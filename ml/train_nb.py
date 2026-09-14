"""Train Multinomial Naive Bayes over TF-IDF for sentiment/category/urgency.

SHIP strategy (per handoff 2026-09-10): the sentiment model + its parity
fixtures are exported for the on-device Dart classifier. Category and urgency
models are trained only for paper metrics and pickled locally — they are NOT
bundled (category is user-selected in-app; urgency uses strict emergency-term
triage in the app).

Metrics use a template-grouped holdout (GroupShuffleSplit on source_id) so
accuracy reflects generalization to complaint templates the model never saw.
"""

import csv
import json
import pickle
from collections import defaultdict
from pathlib import Path

import numpy as np
from scipy.sparse import csr_matrix
from sklearn.model_selection import GroupShuffleSplit
from sklearn.naive_bayes import MultinomialNB

from nb_features import build_vocab, idf_map, ngrams, tokenize, tfidf_matrix

ROOT = Path(__file__).resolve().parent
DATASET = ROOT / "dataset" / "citisense_civic_nlp.csv"
EXPORT = ROOT / "export"
MODELS = ROOT / "saved_models"
RESULTS = ROOT / "test_results_nb.txt"

RANDOM_STATE = 42
ALPHA = 1.0
MIN_DF = 2
MAX_FEATURES = 12000

FIXTURE_TEXTS = [
    "Walang tubig po dito sa amin for three days na, hirap na kami",
    "Salamat po sa mabilis na action ng barangay, maayos na ang ilaw",
    "Magandang umaga, may tanong lang po ako tungkol sa clearance",
    "Puno ng basura ang kanal sa harap ng palengke, sobrang mabaho",
    "Maayos na po ang daan ngayon, salamat sa mabilis na pag repair",
    "May nakapark na sasakyan sa kanto na humaharang sa daan",
    "Nakapag submit na po ako ng report kanina, maraming salamat",
    "Ano po ba ang requirements para sa barangay clearance?",
    "Madilim at mausok dito sa lugar namin, delikado para sa mga bata",
    "Tuloy lang po ang magandang serbisyo, abtik ang mga tauhan ng barangay",
]


def load_rows():
    with DATASET.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def report_header(rows):
    n_sent = defaultdict(int)
    n_cat = defaultdict(int)
    n_urg = defaultdict(int)
    for r in rows:
        n_sent[r["sentiment"]] += 1
        n_cat[r["category"]] += 1
        n_urg[r["urgency"]] += 1
    return (dict(n_sent), dict(n_cat), dict(n_urg))


def main():
    rows = load_rows()
    docs = [ngrams(tokenize(r["text"])) for r in rows]
    vocab, _, df = build_vocab(docs, min_df=MIN_DF, max_features=MAX_FEATURES)
    n_docs = len(docs)
    X, _, idf = tfidf_matrix(docs, vocab, df, n_docs)
    groups = np.array([r["source_id"] for r in rows])
    ids = np.arange(n_docs)

    split = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=RANDOM_STATE)
    (train_idx, test_idx) = next(split.split(ids, groups=groups))

    X_train = X[train_idx]
    X_test = X[test_idx]
    targets = {
        "sentiment": np.array([rows[i]["sentiment"] for i in ids]),
        "category": np.array([rows[i]["category"] for i in ids]),
        "urgency": np.array([rows[i]["urgency"] for i in ids]),
    }

    lines: list[str] = []

    export_dir = EXPORT
    export_dir.mkdir(exist_ok=True)
    models_dir = MODELS
    models_dir.mkdir(exist_ok=True)

    n_sent, n_cat, n_urg = report_header(rows)
    lines.append(f"dataset rows: {n_docs}")
    lines.append(f"sentiment dist: {n_sent}")
    lines.append(f"category dist: {n_cat}")
    lines.append(f"urgency dist: {n_urg}")
    lines.append(f"vocab (df>={MIN_DF}, cap {MAX_FEATURES}): {len(vocab)}")
    lines.append(f"template-grouped holdout: {len(test_idx)}/{n_docs} (20%)")
    lines.append("")

    for target, y in targets.items():
        y_train = y[train_idx]
        y_test = y[test_idx]
        clf = MultinomialNB(alpha=ALPHA).fit(X_train, y_train)
        acc = clf.score(X_test, y_test)
        lines.append(f"[{target}] group-holdout accuracy: {acc:.4f}  ({len(np.unique(y))} classes)")
        clf_path = models_dir / f"{target}_nb.pkl"
        with clf_path.open("wb") as f:
            pickle.dump(
                {
                    "clf": clf,
                    "vocab": vocab,
                    "idf": idf,
                    "class_order": list(clf.classes_),
                    "random_state": RANDOM_STATE,
                    "alpha": ALPHA,
                    "n_docs": n_docs,
                },
                f,
            )
        lines.append(f"  saved: {clf_path.name}")
        if target == "sentiment":
            export_sentiment_json(clf, vocab, idf, export_dir / "sentiment_nb.json")

    export_parity_fixtures(
        models_dir / "sentiment_nb.pkl",
        docs,
        vocab,
        X,
        export_dir / "parity_fixtures.json",
    )

    RESULTS.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))


def export_sentiment_json(clf, vocab, idf, out_path: Path):
    feature_log_prob = np.asarray(clf.feature_log_prob_, dtype=np.float64)
    payload = {
        "alpha": ALPHA,
        "classes": [str(c) for c in clf.classes_],
        "vocab": list(vocab),
        "idf": [float(idf[g]) for g in vocab],
        "feature_log_prob": [
            [float(feature_log_prob[j, i]) for i in range(len(vocab))]
            for j in range(len(clf.classes_))
        ],
        "class_log_prior": [float(v) for v in clf.class_log_prior_],
    }
    out_path.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"  exported: {out_path} ({out_path.stat().st_size / 1024:.0f} KB)")


def export_parity_fixtures(
    clf_path: Path, docs, vocab, X, out_path: Path
):
    """Recompute reference log-scores for 10 sentences on the TRAINED model and
    save them with the exact sklearn path the Dart classifier must reproduce."""
    with clf_path.open("rb") as f:
        bag = pickle.load(f)
    clf = bag["clf"]

    rows = []
    for text in FIXTURE_TEXTS:
        grams = ngrams(tokenize(text))
        index = {g: i for i, g in enumerate(bag["vocab"])}
        counts = defaultdict(int)
        for g in grams:
            counts[g] += 1
        present = set(grams) & set(index)
        raw = {index[g]: counts[g] * bag["idf"][g] for g in present}
        norm2 = sum(v * v for v in raw.values())
        inv = 1.0 / (norm2 ** 0.5) if norm2 > 0 else 0.0
        data = [raw[k] * inv for k in sorted(raw)]
        indices = [k for k in sorted(raw)]
        indptr = [0, len(data)]
        mat = csr_matrix((data, indices, indptr), shape=(1, len(bag["vocab"])))
        log_proba = clf.predict_log_proba(mat)[0]
        rows.append(
            {
                "text": text,
                "predicted": str(clf.predict(mat)[0]),
                "classes": [str(c) for c in clf.classes_],
                "log_proba": [float(v) for v in log_proba],
            }
        )
    out_path.write_text(
        json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    print(f"  parity fixtures: {out_path} ({len(rows)} sentences)")


if __name__ == "__main__":
    main()