"""Train improved NB with keyword features for sentiment & urgency."""

import csv
import json
import pickle
import numpy as np
from pathlib import Path
from scipy.sparse import csr_matrix, hstack
from sklearn.model_selection import GroupShuffleSplit
from sklearn.naive_bayes import MultinomialNB

from nb_features import build_vocab, ngrams, tokenize, tfidf_matrix

ROOT = Path(__file__).resolve().parent
DATASET = ROOT / "dataset" / "citisense_civic_nlp.csv"
EXPORT = ROOT / "export"
MODELS = ROOT / "saved_models"

RANDOM_STATE = 42
ALPHA = 1.0
MIN_DF = 2
MAX_FEATURES = 15000

SENTIMENT_KEYWORDS = {
    'negative': {
        'walang', 'sira', 'sirang', 'nasira', 'hindi', 'di', 'wala', 'wlang',
        'baha', 'binaha', 'bumaha', 'basura', 'tambak', 'mabaho', 'mabantot',
        'baho', 'maingay', 'ingay', 'delikado', 'marumi', 'dumi', 'madilim',
        'dilim', 'pangit', 'panget', 'mali', 'kulang', 'mabagal', 'putol',
        'naputol', 'problema', 'makalat', 'kalat', 'maputik', 'putik', 'madulas',
        'trap', 'muntik', 'aksidente', 'sagabal', 'harang', 'usok', 'mausok',
        'masikip', 'siksikan', 'sakit', 'lamok', 'dengue', 'hirap', 'nahihirapan',
        'sobra', 'mabigat', 'galing', 'loko', 'lokohin', 'linlang', 'linlangin',
        'madaya', 'mandaraya', 'ayaw', 'ayoko', 'hirap', 'hindi mabuti', 'di mabuti',
        'wala', 'empty', 'zero', 'barado', 'bara', 'busted', 'flickering',
        'outage', 'delay', 'delayed', 'late', 'neglect', 'neglected', 'stagnant',
        'foul', 'odor', 'pollution', 'contaminated', 'sewage', 'sewer', 'drain',
        'mess', 'obstructing', 'obstruction', 'vandalized', 'graffiti', 'illegal',
        'unclean', 'unpleasant', 'smoke', 'smoggy', 'mosquito', 'mosquitoes',
        'rats', 'pest', 'overgrown', 'weeds', 'muddy', 'slippery', 'uneven',
        'annoying', 'irritating', 'inconvenient', 'traffic', 'congested'
    },
    'positive': {
        'good', 'great', 'thanks', 'thank', 'thankful', 'grateful', 'appreciate',
        'appreciated', 'resolved', 'fixed', 'working', 'functional', 'restored',
        'improved', 'improvement', 'better', 'best', 'clean', 'cleaner', 'safe',
        'safer', 'fast', 'faster', 'prompt', 'quick', 'quickly', 'responsive',
        'helpful', 'polite', 'friendly', 'professional', 'efficient', 'excellent',
        'wonderful', 'amazing', 'awesome', 'nice', 'beautiful', 'bright', 'clear',
        'love', 'perfect', 'smooth', 'convenient', 'tidy', 'neat', 'organized',
        'okay', 'ok', 'ayos', 'maayos', 'naayos', 'nakaayos', 'maganda', 'magaling',
        'mabuti', 'mabait', 'mababait', 'mahusay', 'galing', 'salamat', 'malinis',
        'linis', 'luminis', 'maliwanag', 'mabilis', 'mabango', 'maaliwalas',
        'tahimik', 'tulong', 'tumulong', 'nakatulong', 'gumana', 'gumagana',
        'bumalik', 'naibalik', 'husay', 'ganda', 'kalma', 'masaya', 'natutuwa',
        'abtik', 'mabilis', 'responsive', 'reliable', 'trustworthy', 'legit',
        'recommend', 'recommended', 'refer', 'referred', 'support', 'supported',
    },
    'neutral': {
        'tanong', 'question', 'inquire', 'inquiry', 'schedule', 'requirement',
        'requirements', 'document', 'documents', 'clearance', 'permit',
        'license', 'id', 'identification', 'certificate', 'certification',
        'office hours', 'bukas', 'open', 'close', 'holiday', 'weekend',
        'magkano', 'how much', 'where', 'saan', 'kailan', 'when', 'pano',
        'paano', 'process', 'procedure', 'apply', 'application', 'register',
        'registration', 'avail', 'service', 'info', 'information', 'pwede',
        'pwedeng', 'contact', 'number', 'hours', 'time', 'date', 'location',
        'address', 'name', 'pangalan', 'address', 'tirahan', 'pangalan',
        'age', 'edad', 'birthday', 'kapanganakan', 'civil status', 'status'
    }
}

URGENCY_KEYWORDS = {
    'emergency': {
        'sos', 'emergency', 'rescue', 'evacuate', 'evacuation', 'trapped',
        'collapse', 'collapsed', 'landslide', 'flash flood', 'live wire',
        'electrocution', 'fire', 'sunog', 'supporta', 'nalunod', 'nawala',
        'pumutok', 'explosion', 'bagsak', 'gumuho', 'tumba', 'hindi makalabas',
        'lagpas tuhod', 'lagpas bewang', 'may namatay', 'patay', 'critical',
        'ambulance', 'fire truck', 'bumbero', '911', '8888', 'may armas',
        'baril', 'kutsilyo', 'patalim', 'holdap', 'suntukan', 'aksidente',
        'naputol', 'nakakamatay', 'buhay', 'urgent', 'asap', 'agad',
        'desisyon', 'kailangan agad', 'walang oras', 'critical', 'nakamamatay'
    },
    'moderate': {
        'walang tubig', 'walang ilaw', 'walang kuryente', 'brownout', 'blackout',
        'sirang kalsada', 'lubak', 'pothole', 'pundido', 'basura', 'tambak',
        'barado', 'baha', 'flood', 'drainage', 'ingay', 'noise', 'videoke',
        'lasing', 'traffic', 'nakaharang', 'harang', 'nakaparada', 'mabaho',
        'mabantot', 'dengue', 'lamok', 'ipis', 'daga', 'stray', 'asong',
        'pusang', 'muntik', 'delikado', 'unsafe', 'hazard', 'nakakatakot',
        'nahihirapan', 'sobra', 'problem', 'issue', 'complaint', 'reklamo',
        'repair', 'ayos', 'ayusin', 'aksyunan', 'aksyon', 'paki-aksyunan',
        'schedule', 'interruption', 'tagas', 'leak', 'tulo', 'contaminated',
        'maputik', 'mabaho', 'pangit', 'sirang', 'nasira', 'butas', 'crack',
        'construction', 'debris', 'illegal', 'double park', 'sidewalk'
    },
    'low': {
        'ano po', 'tanong', 'question', 'inquire', 'inquiry', 'schedule',
        'requirement', 'requirements', 'document', 'clearance', 'permit',
        'certificate', 'certification', 'help', 'tulong', 'information',
        'info', 'pwedeng', 'pwede', 'magkano', 'how much', 'where', 'saan',
        'kailan', 'when', 'pano', 'paano', 'process', 'procedure', 'apply',
        'application', 'register', 'registration', 'avail', 'service',
        'office hours', 'bukas', 'open', 'close', 'holiday', 'weekend',
        'salamat', 'thank you', 'thanks', 'appreciate', 'commend', 'good job',
        'great job', 'nice', 'maayos', 'ayos na', 'maliwanag', 'malinis',
        'thank', 'saludo', 'kudos', 'mabait', 'magaling', 'abtik'
    }
}

def load_rows():
    with DATASET.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))

def count_keywords(text, kw_dict):
    text_lower = text.lower()
    counts = {}
    for cls, keywords in kw_dict.items():
        c = 0
        for kw in keywords:
            if kw in text_lower:
                c += 1
        counts[cls] = c
    return counts

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

    # Add keyword features
    print("Adding keyword features...")
    
    train_kw_s = []
    train_kw_u = []
    test_kw_s = []
    test_kw_u = []
    
    for i in train_idx:
        s_counts = count_keywords(rows[i]["text"], SENTIMENT_KEYWORDS)
        u_counts = count_keywords(rows[i]["text"], URGENCY_KEYWORDS)
        train_kw_s.append([s_counts['negative'], s_counts['positive'], s_counts['neutral']])
        train_kw_u.append([u_counts['emergency'], u_counts['moderate'], u_counts['low']])
    
    for i in test_idx:
        s_counts = count_keywords(rows[i]["text"], SENTIMENT_KEYWORDS)
        u_counts = count_keywords(rows[i]["text"], URGENCY_KEYWORDS)
        test_kw_s.append([s_counts['negative'], s_counts['positive'], s_counts['neutral']])
        test_kw_u.append([u_counts['emergency'], u_counts['moderate'], u_counts['low']])

    train_kw_s = np.array(train_kw_s, dtype=np.float32)
    test_kw_s = np.array(test_kw_s, dtype=np.float32)
    train_kw_u = np.array(train_kw_u, dtype=np.float32)
    test_kw_u = np.array(test_kw_u, dtype=np.float32)

    X_train_s = hstack([X[train_idx], csr_matrix(train_kw_s)])
    X_test_s = hstack([X[test_idx], csr_matrix(test_kw_s)])
    X_train_u = hstack([X[train_idx], csr_matrix(train_kw_u)])
    X_test_u = hstack([X[test_idx], csr_matrix(test_kw_u)])

    # Train sentiment NB
    y_sentiment = np.array([rows[i]["sentiment"] for i in range(len(rows))])
    nb_s = MultinomialNB(alpha=ALPHA).fit(X_train_s, y_sentiment[train_idx])
    acc_s = nb_s.score(X_test_s, y_sentiment[test_idx])
    print(f"[sentiment] NB + keywords accuracy: {acc_s:.4f}")

    with (MODELS / "sentiment_nb_kw.pkl").open("wb") as f:
        pickle.dump({"clf": nb_s, "vocab": vocab, "idf": idf, "classes": list(nb_s.classes_), "kw_dict": SENTIMENT_KEYWORDS}, f)
    export_nb_json(nb_s, vocab, idf, SENTIMENT_KEYWORDS, EXPORT / "sentiment_nb_kw.json")

    # Train urgency NB
    y_urgency = np.array([rows[i]["urgency"] for i in range(len(rows))])
    nb_u = MultinomialNB(alpha=ALPHA).fit(X_train_u, y_urgency[train_idx])
    acc_u = nb_u.score(X_test_u, y_urgency[test_idx])
    print(f"[urgency] NB + keywords accuracy: {acc_u:.4f}")

    with (MODELS / "urgency_nb_kw.pkl").open("wb") as f:
        pickle.dump({"clf": nb_u, "vocab": vocab, "idf": idf, "classes": list(nb_u.classes_), "kw_dict": URGENCY_KEYWORDS}, f)
    export_nb_json(nb_u, vocab, idf, URGENCY_KEYWORDS, EXPORT / "urgency_nb_kw.json")

    # Category (11-class, original)
    y_category = np.array([rows[i]["category"] for i in range(len(rows))])
    nb_cat = MultinomialNB(alpha=ALPHA).fit(X[train_idx], y_category[train_idx])
    acc_cat = nb_cat.score(X[test_idx], y_category[test_idx])
    print(f"[category] NB accuracy: {acc_cat:.4f}")

    with (MODELS / "category_nb.pkl").open("wb") as f:
        pickle.dump({"clf": nb_cat, "vocab": vocab, "idf": idf, "classes": list(nb_cat.classes_)}, f)

    print(f"\nResults:")
    print(f"  Sentiment (3-class): {acc_s:.4f}")
    print(f"  Urgency (3-class): {acc_u:.4f}")
    print(f"  Category (11-class): {acc_cat:.4f}")

def export_nb_json(clf, vocab, idf, kw_dict, out_path):
    """Export NB with keyword features as JSON for Dart."""
    feature_log_prob = clf.feature_log_prob_
    n_vocab = len(vocab)
    n_kw = len(kw_dict)
    
    tfidf_logprob = feature_log_prob[:, :len(vocab)].tolist()
    kw_logprob = feature_log_prob[:, len(vocab):].tolist()
    
    payload = {
        "model_type": "naive_bayes_kw",
        "version": "1.0.0",
        "classes": [str(c) for c in clf.classes_],
        "vocab": list(vocab),
        "idf": [float(idf[v]) for v in vocab],
        "feature_log_prob_tfidf": tfidf_logprob,
        "feature_log_prob_kw": kw_logprob,
        "class_log_prior": [float(v) for v in clf.class_log_prior_],
        "kw_dict": {k: sorted(list(v)) for k, v in kw_dict.items()},
    }
    out_path.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Exported: {out_path}")

if __name__ == "__main__":
    main()
