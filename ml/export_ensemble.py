"""Export ensemble models as combined JSON for Dart."""

import json
import pickle
import numpy as np
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODELS = ROOT / "saved_models"
EXPORT = ROOT / "export"

def export_lr_model(name, clf, vocab, idf, classes, kw_dict):
    """Export LogisticRegression with keyword features as JSON."""
    # Coefficients: (n_classes, n_features + n_keywords)
    coef = clf.coef_  # (n_classes, n_features)
    intercept = clf.intercept_  # (n_classes,)
    
    # Split coefficients: TF-IDF + keywords
    n_vocab = len(vocab)
    n_kw = len(kw_dict)
    
    tfidf_coef = coef[:, :n_vocab].tolist()
    kw_coef = coef[:, n_vocab:].tolist()
    
    payload = {
        "model_type": "logistic_regression",
        "version": "2.0.0",
        "classes": [str(c) for c in classes],
        "vocab": list(vocab),
        "idf": [float(v) for v in idf],
        "tfidf_coef": tfidf_coef,
        "kw_coef": kw_coef,
        "intercept": [float(v) for v in intercept],
        "kw_dict": kw_dict,
    }
    
    out_path = EXPORT / f"{name}_lr_kw.json"
    out_path.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Exported: {out_path} ({out_path.stat().st_size / 1024:.0f} KB)")

def main():
    # Sentiment
    with (MODELS / "sentiment_lr_kw.pkl").open("rb") as f:
        data = pickle.load(f)
    export_lr_model("sentiment", data["clf"], data["vocab"], data["idf"], data["classes"], data["kw_dict"])
    
    # Urgency
    with (MODELS / "urgency_lr_kw.pkl").open("rb") as f:
        data = pickle.load(f)
    export_lr_model("urgency", data["clf"], data["vocab"], data["idf"], data["classes"], data["kw_dict"])

if __name__ == "__main__":
    main()
