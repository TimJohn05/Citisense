#!/usr/bin/env python3
"""
CitiSense NLP Baseline Trainer (TensorFlow/Keras).
Trains Neural Network classifiers for:
1. Sentiment Classification (Negative, Neutral, Positive)
2. Category Classification (Waste, Road, Water, Lighting, etc.)
3. Urgency Classification (Low, Moderate, Emergency)
"""

import os
import pickle
import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

DATASET_PATH = os.path.join(os.path.dirname(__file__), 'dataset', 'citisense_civic_nlp.csv')
MODELS_DIR = os.path.join(os.path.dirname(__file__), 'saved_models')

# Ensure TensorFlow doesn't eat all GPU memory if one exists
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
    print(f" Training TF Neural Network for: {task_name.upper()} ({target_col})")
    print(f"=======================================================")

    X = tf.constant(df['text'].values, dtype=tf.string)
    y_raw = df[target_col].values

    # Encode string labels to integers
    label_encoder = LabelEncoder()
    y = tf.constant(label_encoder.fit_transform(y_raw), dtype=tf.int32)
    num_classes = len(label_encoder.classes_)
    
    print(f"Classes found: {label_encoder.classes_}")

    X_train_raw, X_test_raw, y_train_raw, y_test_raw = train_test_split(
        X.numpy(), y.numpy(), test_size=0.2, random_state=42, stratify=y.numpy()
    )
    
    X_train = tf.constant(X_train_raw, dtype=tf.string)
    X_test = tf.constant(X_test_raw, dtype=tf.string)
    y_train = tf.constant(y_train_raw, dtype=tf.int32)
    y_test = tf.constant(y_test_raw, dtype=tf.int32)

    # 1. Text Vectorization Layer (multi-hot n-grams)
    max_tokens = 5000
    vectorizer = tf.keras.layers.TextVectorization(
        max_tokens=max_tokens,
        output_mode='multi_hot',
        ngrams=2, # Use unigrams and bigrams
        standardize='lower_and_strip_punctuation'
    )
    
    # Adapt the vectorizer to the training text
    print("Adapting vectorizer...")
    vectorizer.adapt(X_train)

    # 2. Build the Neural Network Model
    model = tf.keras.Sequential([
        tf.keras.Input(shape=(1,), dtype=tf.string),
        vectorizer,
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dropout(0.5),
        tf.keras.layers.Dense(32, activation='relu'),
        tf.keras.layers.Dropout(0.5),
        tf.keras.layers.Dense(num_classes, activation='softmax')
    ])

    # 3. Compile the Model
    model.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )

    # 4. Train the Model
    print("Training model...")
    early_stopping = tf.keras.callbacks.EarlyStopping(
        monitor='val_loss', 
        patience=5, 
        restore_best_weights=True
    )

    model.fit(
        X_train, y_train,
        validation_data=(X_test, y_test),
        epochs=30,
        batch_size=32,
        callbacks=[early_stopping],
        verbose=1
    )

    # 5. Evaluate the Model
    loss, accuracy = model.evaluate(X_test, y_test, verbose=0)
    print(f"\nTest Accuracy: {accuracy * 100:.2f}%")

    # Save model and label encoder
    os.makedirs(MODELS_DIR, exist_ok=True)
    
    # Save the Keras model
    model_path = os.path.join(MODELS_DIR, f"{target_col}_model.keras")
    model.save(model_path)
    
    # (TFLite conversion removed due to TextVectorization op compatibility without TF Text)
        
    # Save the label encoder
    encoder_path = os.path.join(MODELS_DIR, f"{target_col}_encoder.pkl")
    with open(encoder_path, 'wb') as f:
        pickle.dump(label_encoder, f)

    print(f"Saved Keras model to {model_path}")
    print(f"Saved Label Encoder to {encoder_path}")

    return model, label_encoder


def predict_text(model, encoder, text):
    # Predict returns shape (1, num_classes)
    predictions = model.predict(tf.constant([text], dtype=tf.string), verbose=0)[0]
    predicted_class_idx = np.argmax(predictions)
    confidence = predictions[predicted_class_idx] * 100
    predicted_label = encoder.inverse_transform([predicted_class_idx])[0]
    return predicted_label, confidence


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
        print(f"  → Sentiment: [{sent_label}] ({sent_conf:.1f}% confidence)")
        print(f"  → Urgency:   [{urg_label}]")


def main():
    df = load_dataset()
    
    sent_model, sent_enc = train_task(df, 'sentiment', 'Sentiment Analysis')
    cat_model, cat_enc = train_task(df, 'category', 'Category Classification')
    urg_model, urg_enc = train_task(df, 'urgency', 'Urgency Hazard Detection')

    interactive_test(sent_model, sent_enc, cat_model, cat_enc, urg_model, urg_enc)


if __name__ == '__main__':
    main()
