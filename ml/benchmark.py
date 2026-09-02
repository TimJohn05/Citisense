#!/usr/bin/env python3
"""
Hyper-parameter benchmark for CitiSense NLP classifiers.

Trains each config on the synthetic dataset and reports BOTH:
  1. validation accuracy on the 20% holdout (from the training split), and
  2. accuracy on the 100 held-out scenarios (test_scenarios.csv).

The held-out scenario accuracy is the real measure of generalization, since
those are independently-worded sentences the model has never seen.
Usage: python benchmark.py
"""

import itertools
import os
import pickle
import sys
import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.utils.class_weight import compute_class_weight

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
tf.get_logger().setLevel('ERROR')

BASE = os.path.dirname(os.path.abspath(__file__))
DATASET = os.path.join(BASE, 'dataset', 'citisense_civic_nlp.csv')
SCENARIOS = os.path.join(BASE, 'test_scenarios.csv')

CONFIGS = [
    # output_mode, max_tokens, ngrams, units
    ('multi_hot', 5000, 2, 64),      # ~v1 baseline
    ('multi_hot', 8000, 2, 128),
    ('multi_hot', 12000, 2, 128),
    ('multi_hot', 12000, 3, 128),
    ('tf_idf', 5000, 2, 64),
    ('tf_idf', 8000, 2, 128),
    ('tf_idf', 12000, 2, 128),
    ('count', 5000, 2, 128),
]


def build_tfidfish(mode, max_tokens, ngrams, units, num_classes):
    vectorizer = tf.keras.layers.TextVectorization(
        max_tokens=max_tokens, output_mode=mode, ngrams=ngrams,
        standardize='lower_and_strip_punctuation')
    return vectorizer, units, num_classes


def train_eval(df, target_col, mode, max_tokens, ngrams, units, scenario_rows, enc_map):
    y_raw = df[target_col].values
    enc = LabelEncoder()
    y_int = enc.fit_transform(y_raw)
    num_classes = len(enc.classes_)

    X_raw = df['text'].values
    X_tr, X_va, y_tr, y_va = train_test_split(
        X_raw, y_int, test_size=0.2, random_state=42, stratify=y_int)

    vec = tf.keras.layers.TextVectorization(
        max_tokens=max_tokens, output_mode=mode, ngrams=ngrams,
        standardize='lower_and_strip_punctuation')
    vec.adapt(tf.constant(X_tr))

    inp = tf.keras.Input(shape=(1,), dtype=tf.string)
    x = vec(inp)
    x = tf.keras.layers.Dense(units, activation='relu')(x)
    x = tf.keras.layers.Dropout(0.5)(x)
    x = tf.keras.layers.Dense(units // 2, activation='relu')(x)
    x = tf.keras.layers.Dropout(0.5)(x)
    out = tf.keras.layers.Dense(num_classes, activation='softmax')(x)
    model = tf.keras.Model(inp, out)
    model.compile(optimizer=tf.keras.optimizers.Adam(1e-3),
                  loss='sparse_categorical_crossentropy', metrics=['accuracy'])

    cw = dict(zip(np.unique(y_tr),
                  compute_class_weight('balanced', classes=np.unique(y_tr), y=y_tr)))
    model.fit(tf.constant(X_tr), y_tr, validation_data=(tf.constant(X_va), y_va),
              epochs=30, batch_size=64, class_weight=cw,
              callbacks=[tf.keras.callbacks.EarlyStopping(
                  monitor='val_loss', patience=5, restore_best_weights=True)],
              verbose=0)
    val_acc = model.evaluate(tf.constant(X_va), y_va, verbose=0)[1]

    # held-out scenarios
    correct = 0
    for r in scenario_rows:
        p = model.predict(tf.constant([r['text']], dtype=tf.string), verbose=0)[0]
        pl = enc.inverse_transform([int(np.argmax(p))])[0]
        if pl == r[target_col]:
            correct += 1
    return val_acc, correct / len(scenario_rows)


def main():
    df = pd.read_csv(DATASET)
    scenario_rows = list(pd.read_csv(SCENARIOS).to_dict('records'))
    targets = ['sentiment', 'category', 'urgency']

    results = []
    # Only scan category first (the hardest task) to save time.
    target = 'category'
    print(f"Scanning configs on task: {target} ({len(scenario_rows)} held-out scenarios)")
    for mode, mt, ng, units in CONFIGS:
        try:
            val, scen = train_eval(df, target, mode, mt, ng, units, scenario_rows, None)
            tag = f"{mode:10s} tokens={mt} ngrams={ng} units={units}"
            print(f"  {tag:<42} val={val*100:5.1f}% scen={scen*100:5.1f}%")
            results.append((scen, val, mode, mt, ng, units))
        except Exception as e:  # noqa: BLE001
            print(f"  {mode} {mt} {ng} {units} ERROR: {e}")

    results.sort(reverse=True)
    print("\nBest (by held-out scenario accuracy):")
    for r in results[:3]:
        scen, val, mode, mt, ng, units = r
        print(f"  scen={scen*100:.1f}% val={val*100:.1f}%  mode={mode} tokens={mt} ngrams={ng} units={units}")


if __name__ == '__main__':
    main()
