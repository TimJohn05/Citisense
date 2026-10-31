"""Boost urgency with keyword features + ensemble."""

import csv
import json
import pickle
from pathlib import Path

import numpy as np
from scipy.sparse import csr_matrix, hstack
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

# Urgency keywords (from sentiment_engine.dart)
URGENCY_KEYWORDS = {
    'emergency': {
        'sos', 'emergency', 'rescue', 'evacuate', 'evacuation', 'trapped',
        'collapse', 'collapsed', 'landslide', 'flash flood', 'live wire',
        'electrocution', 'fire', 'sunog', 'supporta', 'nalunod', 'nawala',
        'pumutok', 'explosion', 'bagsak', 'gumuho', 'tumba', 'hindi makalabas',
        'lagpas tuhod', 'lagpas bewang', 'may namatay', 'patay', 'critical',
        'ambulance', 'fire truck', 'bumbero', '911', '8888', 'may armas',
        'baril', 'kutsilyo', 'patalim', 'holdap', 'suntukan', 'aksidente',
        'naputol', 'nakakamatay', 'buhay', 'emergency', 'urgent', 'asap',
        'agad', 'desisyon', 'kailangan agad', 'walang oras', 'critical'
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

def count_urgency_keywords(text, kw_dict):
    text_lower = text.lower()
    counts = {'emergency': 0, 'moderate': 0, 'low': 0}
    for urgency, keywords in kw_dict.items():
        for kw in keywords:
            if kw in text_lower:
                counts[urgency] += 1
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

    # Add keyword count features
    print("Adding urgency keyword features...")
    train_kw = []
    test_kw = []
    for i in ids:
        counts = count_urgency_keywords(rows[i]["text"], URGENCY_KEYWORDS)
        feat = [counts['emergency'], counts['moderate'], counts['low']]
        if i in train_idx:
            train_kw.append(feat)
        else:
            test_kw.append(feat)
    
    train_kw = np.array(train_kw, dtype=np.float32)
    test_kw = np.array(test_kw, dtype=np.float32)
    
    # Normalize
    from sklearn.preprocessing import StandardScaler
    scaler = StandardScaler()
    train_kw = scaler.fit_transform(train_kw)
    test_kw = scaler.transform(test_kw)
    
    X_train_combined = hstack([X_train, csr_matrix(train_kw)])
    X_test_combined = hstack([X_test, csr_matrix(test_kw)])

    # Train urgency ensemble
    y_urgency = np.array([rows[i]["urgency"] for i in ids])
    y_train = y_urgency[train_idx]
    y_test = y_urgency[test_idx]

    nb = MultinomialNB(alpha=ALPHA)
    lr = LogisticRegression(max_iter=2000, random_state=RANDOM_STATE, C=1.0, class_weight='balanced')
    ensemble = VotingClassifier(
        estimators=[('nb', nb), ('lr', lr)],
        voting='soft'
    )
    ensemble.fit(X_train_combined, y_train)
    acc = ensemble.score(X_test_combined, y_test)
    print(f"[urgency] ensemble + keywords accuracy: {acc:.4f}")

    with (MODELS / "urgency_ensemble_kw.pkl").open("wb") as f:
        pickle.dump({
            "clf": ensemble, 
            "vocab": vocab, 
            "idf": idf, 
            "classes": list(ensemble.classes_),
            "scaler": scaler,
            "kw_dict": URGENCY_KEYWORDS
        }, f)

if __name__ == "__main__":
    main()
