#!/usr/bin/env python3
"""
CitiSense NLP Baseline Trainer (TensorFlow/Keras) — v4 final.

Trains Neural Network classifiers for:
1. Sentiment Classification (Negative, Neutral, Positive)
2. Category Classification (11 civic categories)
3. Urgency Classification (Low, Moderate, Emergency)

Design notes (validated empirically against a 100-scenario held-out test):
- output_mode='multi_hot' (binary n-gram presence) GENERALIZES far better to
  unseen, differently-worded Taglish sentences than tf_idf, count, embeddings,
  or trigrams — because it ignores raw frequency and keeps only keyword
  presence, which transfers across phrasings.
- Small vocabulary (~5000) + bigrams beats larger vocab / trigrams (which
  overfit the synthetic template language).
- Shallow wide network + strong dropout resists overfitting.
- Class weights rebalance the rare general_inquiry category.
See benchmark.py for the empirical comparison.
"""

import os
import pickle
import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.utils.class_weight import compute_class_weight

DATASET_PATH = os.path.join(os.path.dirname(__file__), 'dataset', 'citisense_civic_nlp.csv')
MODELS_DIR = os.path.join(os.path.dirname(__file__), 'saved_models')

VOCAB_SIZE = int(os.environ.get('VOCAB', '5000'))
NGRAMS = int(os.environ.get('NGRAMS', '2'))
UNITS = int(os.environ.get('UNITS', '96'))
EPOCHS = int(os.environ.get('EPOCHS', '40'))
PATIENCE = int(os.environ.get('PATIENCE', '8'))
BATCH_SIZE = 64

gpus = tf.config.list_physical_devices('GPU')
if gpus:
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
    except RuntimeError as e:
        print(e)


def load_dataset():
    if not os.path.exists(DATASET_PATH):
        raise FileNotFoundError(f"Dataset not found at {DATASET_PATH}. Run generate_dataset.py first.")
    df = pd.read_csv(DATASET_PATH)
    print(f"Loaded {len(df)} samples from {DATASET_PATH}")
    return df


def train_task(df, target_col, task_name):
    print(f"\n=======================================================")
    print(f" Training multi-hot Network for: {task_name.upper()} ({target_col})")
    print(f"  vocab={VOCAB_SIZE} ngrams={NGRAMS} units={UNITS}")
    print(f"=======================================================")

    X_raw = df['text'].values
    y_raw = df[target_col].values

    label_encoder = LabelEncoder()
    y_int = label_encoder.fit_transform(y_raw)
    num_classes = len(label_encoder.classes_)
    print(f"Classes found: {label_encoder.classes_}")
    print(f"Samples/class: {dict(zip(label_encoder.classes_, np.bincount(y_int)))}")

    X_train_raw, X_test_raw, y_train_raw, y_test_raw = train_test_split(
        X_raw, y_int, test_size=0.2, random_state=42, stratify=y_int
    )
    X_train = tf.constant(X_train_raw, dtype=tf.string)
    X_test = tf.constant(X_test_raw, dtype=tf.string)
    y_train = tf.constant(y_train_raw, dtype=tf.int32)
    y_test = tf.constant(y_test_raw, dtype=tf.int32)

    vectorizer = tf.keras.layers.TextVectorization(
        max_tokens=VOCAB_SIZE,
        output_mode='multi_hot',
        ngrams=NGRAMS,
        standardize='lower_and_strip_punctuation',
    )
    print("Adapting vectorizer...")
    vectorizer.adapt(X_train)

    model = tf.keras.Sequential([
        tf.keras.Input(shape=(1,), dtype=tf.string),
        vectorizer,
        tf.keras.layers.Dense(UNITS, activation='relu'),
        tf.keras.layers.Dropout(0.5),
        tf.keras.layers.Dense(UNITS // 2, activation='relu'),
        tf.keras.layers.Dropout(0.5),
        tf.keras.layers.Dense(num_classes, activation='softmax'),
    ])
    model.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy'],
    )

    class_weights = compute_class_weight(
        class_weight='balanced', classes=np.unique(y_train_raw), y=y_train_raw)
    cw = dict(zip(np.unique(y_train_raw), class_weights))

    early_stopping = tf.keras.callbacks.EarlyStopping(
        monitor='val_loss', patience=PATIENCE, restore_best_weights=True)
    reduce_lr = tf.keras.callbacks.ReduceLROnPlateau(
        monitor='val_loss', factor=0.5, patience=4, min_lr=1e-5)

    model.fit(
        X_train, y_train,
        validation_data=(X_test, y_test),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        class_weight=cw,
        callbacks=[early_stopping, reduce_lr],
        verbose=1,
    )

    loss, accuracy = model.evaluate(X_test, y_test, verbose=0)
    print(f"\nHoldout (20%) Val Accuracy: {accuracy * 100:.2f}%")

    os.makedirs(MODELS_DIR, exist_ok=True)
    model_path = os.path.join(MODELS_DIR, f"{target_col}_model.keras")
    model.save(model_path)
    encoder_path = os.path.join(MODELS_DIR, f"{target_col}_encoder.pkl")
    with open(encoder_path, 'wb') as f:
        pickle.dump(label_encoder, f)

    print(f"Saved Keras model to {model_path}")
    print(f"Saved Label Encoder to {encoder_path}")
    return model, label_encoder


def predict_text(model, encoder, text):
    predictions = model.predict(tf.constant([text], dtype=tf.string), verbose=0)[0]
    idx = int(np.argmax(predictions))
    label = encoder.inverse_transform([idx])[0]
    return label, predictions[idx]


def interactive_test(sent_model, sent_enc, cat_model, cat_enc, urg_model, urg_enc):
    print("\n=======================================================")
    print(" Test NLP Predictions with Custom Taglish Sentences:")
    print("=======================================================")
    test_samples = [
        "Sobrang lakas ng videoke at sigawan kahit lampas 11 PM na, pakisita naman po.",
        "May live wire na nakalantad at sumasabog na transformer sa may poste!",
        "May sasakyan na nag-iillegal double parking sa kanto, nakaharang sa daanan.",
        "Ano po ang requirements para sa pagkuha ng barangay clearance bukas?",
    ]
    for text in test_samples:
        cat_label, _ = predict_text(cat_model, cat_enc, text)
        sent_label, sent_conf = predict_text(sent_model, sent_enc, text)
        urg_label, _ = predict_text(urg_model, urg_enc, text)
        print(f"\nText: \"{text}\"")
        print(f"  → Category:  [{cat_label}]")
        print(f"  → Sentiment: [{sent_label}] ({sent_conf*100:.1f}% confidence)")
        print(f"  → Urgency:   [{urg_label}]")


def main():
    df = load_dataset()
    sent_model, sent_enc = train_task(df, 'sentiment', 'Sentiment Analysis')
    cat_model, cat_enc = train_task(df, 'category', 'Category Classification')
    urg_model, urg_enc = train_task(df, 'urgency', 'Urgency Hazard Detection')
    interactive_test(sent_model, sent_enc, cat_model, cat_enc, urg_model, urg_enc)


if __name__ == '__main__':
    main()
