#!/usr/bin/env python3
"""
CitiSense NLP Baseline Trainer.
Trains n-gram TF-IDF contextual classifiers for:
1. Sentiment Classification (Negative, Neutral, Positive)
2. Category Classification (Waste, Road, Water, Lighting, Others)
3. Urgency Classification (Low, Moderate, Emergency)
"""

import os
import pickle
import pandas as pd
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix


DATASET_PATH = os.path.join(os.path.dirname(__file__), 'dataset', 'citisense_civic_nlp.csv')
MODELS_DIR = os.path.join(os.path.dirname(__file__), 'saved_models')


def load_dataset():
    if not os.path.exists(DATASET_PATH):
        raise FileNotFoundError(f"Dataset not found at {DATASET_PATH}. Run generate_dataset.py first.")
    df = pd.read_csv(DATASET_PATH)
    print(f"Loaded {len(df)} samples from {DATASET_PATH}")
    print("\nDataset Class Distribution:")
    print("--- Sentiment ---")
    print(df['sentiment'].value_counts())
    print("\n--- Category ---")
    print(df['category'].value_counts())
    print("\n--- Urgency ---")
    print(df['urgency'].value_counts())
    return df


def train_task(df, target_col, task_name):
    print(f"\n=======================================================")
    print(f" Training NLP Model for: {task_name.upper()} ({target_col})")
    print(f"=======================================================")

    X = df['text']
    y = df[target_col]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # N-gram TF-IDF vectorizer captures 1-gram, 2-gram, and 3-gram sequences
    # e.g., 'hindi sira' vs 'sira'
    pipeline = Pipeline([
        ('tfidf', TfidfVectorizer(
            ngram_range=(1, 3),        # unigrams + bigrams + trigrams
            min_df=2,                  # ignore rare typos
            sublinear_tf=True,         # sublinear term frequency scaling
            lowercase=True
        )),
        ('clf', LogisticRegression(
            max_iter=1000,
            class_weight='balanced',
            C=1.5
        ))
    ])

    pipeline.fit(X_train, y_train)

    # Evaluation on Holdout Test Set
    y_pred = pipeline.predict(X_test)
    acc = accuracy_score(y_test, y_pred)

    print(f"\nTest Accuracy: {acc * 100:.2f}%")
    print("\nDetailed Classification Report:")
    print(classification_report(y_test, y_pred))

    # Cross-validation score
    cv_scores = cross_val_score(pipeline, X, y, cv=5)
    print(f"5-Fold Cross-Validation Accuracy: {cv_scores.mean() * 100:.2f}% (+/- {cv_scores.std() * 100:.2f}%)")

    # Save model artifact
    os.makedirs(MODELS_DIR, exist_ok=True)
    model_path = os.path.join(MODELS_DIR, f"{target_col}_model.pkl")
    with open(model_path, 'wb') as f:
        pickle.dump(pipeline, f)
    print(f"Saved model to {model_path}")

    return pipeline


def interactive_test(sentiment_model, category_model, urgency_model):
    print("\n=======================================================")
    print(" Test NLP Predictions with Custom Taglish Sentences:")
    print("=======================================================")

    test_samples = [
        "Sobrang lakas ng videoke at sigawan kahit lampas 11 PM na, pakisita naman po.",
        "May live wire na nakalantad at sumasabog na transformer sa may poste!",
        "May sasakyan na nag-iillegal double parking sa kanto, nakaharang sa daanan.",
        "May nagsisiga po ng goma at plastic, napakakapal ng maitim na usok nahihirapan huminga.",
        "Umapaw po ang maruming tubig sa baradong estero dahil sa ulan.",
        "Sira po yung ilaw sa poste kanina pero naayos na po ngayon salamat.",
        "Ano po ang requirements para sa pagkuha ng barangay clearance bukas?",
    ]

    for text in test_samples:
        sent = sentiment_model.predict([text])[0]
        cat = category_model.predict([text])[0]
        urg = urgency_model.predict([text])[0]

        sent_prob = max(sentiment_model.predict_proba([text])[0]) * 100

        print(f"\nText: \"{text}\"")
        print(f"  → Category:  [{cat}]")
        print(f"  → Sentiment: [{sent}] ({sent_prob:.1f}% confidence)")
        print(f"  → Urgency:   [{urg}]")


def main():
    df = load_dataset()
    
    sent_model = train_task(df, 'sentiment', 'Sentiment Analysis')
    cat_model = train_task(df, 'category', 'Category Classification')
    urg_model = train_task(df, 'urgency', 'Urgency Hazard Detection')

    interactive_test(sent_model, cat_model, urg_model)


if __name__ == '__main__':
    main()
