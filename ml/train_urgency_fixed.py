"""Boost urgency with keyword features - use LR for combined, NB for TF-IDF only."""

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

# Urgency keywords
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

    # Add keyword count features (non-negative for NB)
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
    
    X_train_combined = hstack([X_train, csr_matrix(train_kw)])
    X_test_combined = hstack([X_test, csr_matrix(test_kw)])

    # Train urgency: NB on TF-IDF only, LR on combined, then ensemble
    y_urgency = np.array([rows[i]["urgency"] for i in ids])
    y_train = y_urgency[train_idx]
    y_test = y_urgency[test_idx]

    # NB only on TF-IDF (no negative values)
    nb = MultinomialNB(alpha=ALPHA)
    nb.fit(X_train, y_train)
    
    # LR on combined features
    lr = LogisticRegression(max_iter=2000, random_state=RANDOM_STATE, C=1.0, class_weight='balanced')
    lr.fit(X_train_combined, y_train)
    
    # Simple voting: average probabilities
    nb_proba = nb.predict_proba(X_test)
    lr_proba = lr.predict_proba(X_test_combined)
    ensemble_proba = (nb_proba + lr_proba) / 2
    ensemble_pred = ensemble_proba.argmax(axis=1)
    classes = np.array(['emergency', 'low', 'moderate'])  # alphabetical from sklearn
    acc = np.mean(classes[ensemble_pred] == y_test)
    print(f"[urgency] NB + LR ensemble accuracy: {acc:.4f}")

    # Save models
    with (MODELS / "urgency_nb.pkl").open("wb") as f:
        pickle.dump({"clf": nb, "vocab": vocab, "idf": idf, "classes": list(nb.classes_)}, f)
    with (MODELS / "urgency_lr_kw.pkl").open("wb") as f:
        pickle.dump({"clf": lr, "vocab": vocab, "idf": idf, "classes": list(lr.classes_), "kw_dict": URGENCY_KEYWORDS}, f)

    # Also train sentiment ensemble (same approach)
    print("Training sentiment ensemble...")
    y_sentiment = np.array([rows[i]["sentiment"] for i in ids])
    y_train = y_sentiment[train_idx]
    y_test = y_sentiment[test_idx]

    # Sentiment keywords
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
            'ayos', 'maayos', 'naayos', 'nakaayos', 'maganda', 'magaling', 'mabuti',
            'mabait', 'mababait', 'mahusay', 'galing', 'salamat', 'malinis', 'linis',
            'luminis', 'maliwanag', 'mabilis', 'mabango', 'maaliwalas', 'tahimik',
            'tulong', 'tumulong', 'nakatulong', 'gumana', 'gumagana', 'bumalik',
            'naibalik', 'husay', 'ganda', 'kalma', 'masaya', 'natutuwa', 'abtik',
            'mabilis', 'responsive', 'reliable', 'trustworthy', 'legit', 'recommend',
            'recommended', 'refer', 'referred', 'support', 'supported', 'smooth',
            'convenient', 'tidy', 'neat', 'organized', 'okay', 'ok', 'great',
            'excellent', 'wonderful', 'amazing', 'awesome', 'nice', 'beautiful',
            'bright', 'clear', 'love', 'perfect', 'improved', 'improvement',
            'better', 'best', 'clean', 'cleaner', 'safe', 'safer', 'fast',
            'faster', 'prompt', 'quick', 'quickly', 'helpful', 'polite',
            'friendly', 'professional', 'efficient', 'restored', 'functional',
            'working', 'fixed', 'resolved', 'thankful', 'grateful', 'appreciate',
            'appreciated', 'thank', 'thanks'
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

    def count_sentiment_keywords(text, kw_dict):
        text_lower = text.lower()
        counts = {'negative': 0, 'positive': 0, 'neutral': 0}
        for sentiment, keywords in kw_dict.items():
            for kw in keywords:
                if kw in text_lower:
                    counts[sentiment] += 1
        return counts

    train_kw_s = []
    test_kw_s = []
    for i in ids:
        counts = count_sentiment_keywords(rows[i]["text"], SENTIMENT_KEYWORDS)
        feat = [counts['negative'], counts['positive'], counts['neutral']]
        if i in train_idx:
            train_kw_s.append(feat)
        else:
            test_kw_s.append(feat)
    
    train_kw_s = np.array(train_kw_s, dtype=np.float32)
    test_kw_s = np.array(test_kw_s, dtype=np.float32)
    
    X_train_combined_s = hstack([X_train, csr_matrix(train_kw_s)])
    X_test_combined_s = hstack([X_test, csr_matrix(test_kw_s)])

    nb_s = MultinomialNB(alpha=ALPHA)
    nb_s.fit(X_train, y_train)
    
    lr_s = LogisticRegression(max_iter=2000, random_state=RANDOM_STATE, C=1.0, class_weight='balanced')
    lr_s.fit(X_train_combined_s, y_train)
    
    nb_proba_s = nb_s.predict_proba(X_test)
    lr_proba_s = lr_s.predict_proba(X_test_combined_s)
    ensemble_proba_s = (nb_proba_s + lr_proba_s) / 2
    ensemble_pred_s = ensemble_proba_s.argmax(axis=1)
    classes_s = np.array(['negative', 'neutral', 'positive'])
    acc_s = np.mean(classes_s[ensemble_pred_s] == y_test)
    print(f"[sentiment] NB + LR ensemble accuracy: {acc_s:.4f}")

    # Save sentiment models
    with (MODELS / "sentiment_nb.pkl").open("wb") as f:
        pickle.dump({"clf": nb_s, "vocab": vocab, "idf": idf, "classes": list(nb_s.classes_)}, f)
    with (MODELS / "sentiment_lr_kw.pkl").open("wb") as f:
        pickle.dump({"clf": lr_s, "vocab": vocab, "idf": idf, "classes": list(lr_s.classes_), "kw_dict": SENTIMENT_KEYWORDS}, f)

    # Category NB (11-class, original)
    print("Training category (11-class)...")
    y_category = np.array([rows[i]["category"] for i in ids])
    y_train = y_category[train_idx]
    y_test = y_category[test_idx]

    nb_cat = MultinomialNB(alpha=ALPHA).fit(X_train, y_train)
    acc_cat = nb_cat.score(X_test, y_test)
    print(f"[category] NB accuracy: {acc_cat:.4f}")

    with (MODELS / "category_nb.pkl").open("wb") as f:
        pickle.dump({"clf": nb_cat, "vocab": vocab, "idf": idf, "classes": list(nb_cat.classes_)}, f)

if __name__ == "__main__":
    main()
