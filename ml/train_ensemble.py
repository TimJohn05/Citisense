"""Train ensemble models for sentiment (3-class) and urgency (3-class) to hit 90%+."""

import csv
import json
import pickle
from pathlib import Path

import numpy as np
from scipy.sparse import csr_matrix
from sklearn.model_selection import GroupShuffleSplit
from sklearn.naive_bayes import MultinomialNB
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import VotingClassifier

from nb_features import build_vocab, idf_map, ngrams, tokenize, tfidf_matrix

ROOT = Path(__file__).resolve().parent
DATASET = ROOT / "dataset" / "citisense_civic_nlp.csv"
EXPORT = ROOT / "export"
MODELS = ROOT / "saved_models"

RANDOM_STATE = 42
ALPHA = 1.0
MIN_DF = 2
MAX_FEATURES = 15000

def load_rows():
    with DATASET.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))

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

    lines = []
    lines.append(f"dataset rows: {n_docs}")
    lines.append(f"vocab (df>={MIN_DF}, cap {MAX_FEATURES}): {len(vocab)}")
    lines.append(f"template-grouped holdout: {len(test_idx)}/{n_docs} (20%)")
    lines.append("")

    export_dir = EXPORT
    export_dir.mkdir(exist_ok=True)
    models_dir = MODELS
    models_dir.mkdir(exist_ok=True)

    # ===== SENTIMENT: Ensemble (NB + LogisticRegression) =====
    print("Training sentiment ensemble...")
    y_sentiment = np.array([rows[i]["sentiment"] for i in ids])
    y_train = y_sentiment[train_idx]
    y_test = y_sentiment[test_idx]

    nb = MultinomialNB(alpha=ALPHA)
    lr = LogisticRegression(max_iter=2000, random_state=RANDOM_STATE, C=1.0, class_weight='balanced')
    ensemble = VotingClassifier(
        estimators=[('nb', nb), ('lr', lr)],
        voting='soft'
    )
    ensemble.fit(X_train, y_train)
    acc = ensemble.score(X_test, y_test)
    lines.append(f"[sentiment] ensemble accuracy: {acc:.4f} ({len(ensemble.classes_)} classes)")

    with (models_dir / "sentiment_ensemble.pkl").open("wb") as f:
        pickle.dump({"clf": ensemble, "vocab": vocab, "idf": idf, "classes": list(ensemble.classes_)}, f)
    export_sentiment_json(ensemble, vocab, idf, export_dir / "sentiment_ensemble.json")

    # ===== URGENCY: Ensemble =====
    print("Training urgency ensemble...")
    y_urgency = np.array([rows[i]["urgency"] for i in ids])
    y_train = y_urgency[train_idx]
    y_test = y_urgency[test_idx]

    nb = MultinomialNB(alpha=ALPHA)
    lr = LogisticRegression(max_iter=2000, random_state=RANDOM_STATE, C=1.0, class_weight='balanced')
    ensemble = VotingClassifier(
        estimators=[('nb', nb), ('lr', lr)],
        voting='soft'
    )
    ensemble.fit(X_train, y_train)
    acc = ensemble.score(X_test, y_test)
    lines.append(f"[urgency] ensemble accuracy: {acc:.4f} ({len(ensemble.classes_)} classes)")

    with (models_dir / "urgency_ensemble.pkl").open("wb") as f:
        pickle.dump({"clf": ensemble, "vocab": vocab, "idf": idf, "classes": list(ensemble.classes_)}, f)

    # ===== CATEGORY (11-class): Keep original NB for paper metrics =====
    print("Training category (11-class, original NB)...")
    y_category = np.array([rows[i]["category"] for i in ids])
    y_train = y_category[train_idx]
    y_test = y_category[test_idx]

    nb = MultinomialNB(alpha=ALPHA).fit(X_train, y_train)
    acc = nb.score(X_test, y_test)
    lines.append(f"[category] NB accuracy: {acc:.4f} ({len(nb.classes_)} classes)")

    with (models_dir / "category_nb.pkl").open("wb") as f:
        pickle.dump({"clf": nb, "vocab": vocab, "idf": idf, "classes": list(nb.classes_)}, f)

    RESULTS = ROOT / "test_results_ensemble.txt"
    RESULTS.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))

def export_sentiment_json(clf, vocab, idf, out_path: Path):
    feature_log_prob = np.asarray(clf.estimators_[0].feature_log_prob_, dtype=np.float64)
    payload = {
        "alpha": ALPHA,
        "classes": [str(c) for c in clf.classes_],
        "vocab": list(vocab),
        "idf": [float(idf[g]) for g in vocab],
        "feature_log_prob": [
            [float(feature_log_prob[j, i]) for i in range(len(vocab))]
            for j in range(len(clf.classes_))
        ],
        "class_log_prior": [float(v) for v in clf.estimators_[0].class_log_prior_],
    }
    out_path.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"  exported: {out_path} ({out_path.stat().st_size / 1024:.0f} KB)")

if __name__ == "__main__":
    main()
