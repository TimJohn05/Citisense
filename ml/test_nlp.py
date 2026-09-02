#!/usr/bin/env python3
"""
CitiSense NLP model tester.

Loads the trained TensorFlow/Keras models from saved_models/, reads the test
scenarios from test_scenarios.csv, runs predictions for each scenario, and
writes a detailed report to a file.

Usage:
    python test_nlp.py                      # uses test_scenarios.csv
    python test_nlp.py out_report.txt       # custom output file path
    python test_nlp.py scenarios.csv out.txt
"""

import argparse
import csv
import os
import pickle
import sys
from datetime import datetime

import numpy as np
import tensorflow as tf

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, 'saved_models')
DEFAULT_SCENARIOS = os.path.join(BASE_DIR, 'test_scenarios.csv')
DEFAULT_OUTPUT = os.path.join(BASE_DIR, 'test_results.txt')

TASKS = ['sentiment', 'category', 'urgency']
TASKS_LABEL = {
    'sentiment': 'Sentiment Analysis',
    'category': 'Category Classification',
    'urgency': 'Urgency Detection',
}


def load_models():
    """Load the three Keras models + LabelEncoders."""
    models, encoders = {}, {}
    for task in TASKS:
        model_path = os.path.join(MODELS_DIR, f'{task}_model.keras')
        enc_path = os.path.join(MODELS_DIR, f'{task}_encoder.pkl')
        if not (os.path.exists(model_path) and os.path.exists(enc_path)):
            print(f"Missing model files for {task}: {model_path} / {enc_path}")
            print("Run train_model.py first.")
            sys.exit(1)
        models[task] = tf.keras.models.load_model(model_path)
        with open(enc_path, 'rb') as f:
            encoders[task] = pickle.load(f)
    return models, encoders


def predict(models, encoders, text):
    """Return (labels, confidences) dict for the given text."""
    results = {}
    for task in TASKS:
        preds = models[task].predict(
            tf.constant([text], dtype=tf.string), verbose=0
        )[0]
        idx = int(np.argmax(preds))
        label = encoders[task].inverse_transform([idx])[0]
        results[task] = (label, float(preds[idx]))
    return results


def main():
    parser = argparse.ArgumentParser(description='Test CitiSense NLP models')
    parser.add_argument('scenarios', nargs='?', default=DEFAULT_SCENARIOS,
                        help='Path to test scenarios CSV (default: test_scenarios.csv)')
    parser.add_argument('output', nargs='?', default=DEFAULT_OUTPUT,
                        help='Output file path (default: test_results.txt)')
    args = parser.parse_args()

    if not os.path.exists(args.scenarios):
        print(f"Scenario file not found: {args.scenarios}")
        print("Run generate_test_scenarios.py first.")
        sys.exit(1)

    print("Loading models...")
    models, encoders = load_models()

    with open(args.scenarios, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Loaded {len(rows)} scenarios from {args.scenarios}")
    print("Running predictions... press Ctrl+C to abort.\n")

    results = []
    for i, row in enumerate(rows, 1):
        text = row['text']
        actual = {
            'sentiment': row.get('sentiment', ''),
            'category': row.get('category', ''),
            'urgency': row.get('urgency', ''),
        }
        try:
            preds = predict(models, encoders, text)
        except Exception as e:  # noqa: BLE001
            preds = {t: ('ERROR', 0.0) for t in TASKS}
            print(f"  [{i}/{len(rows)}] ERROR: {e}")

        results.append({
            'index': i,
            'text': text,
            'actual': actual,
            'preds': preds,
        })
        ok = all(preds[t][0] == actual[t] for t in TASKS)
        mark = 'OK ' if ok else 'MISMATCH'
        print(f"  [{i}/{len(rows)}] {mark} sentiment={preds['sentiment'][0]} "
              f"category={preds['category'][0]} urgency={preds['urgency'][0]}")

    write_report(results, args.output)


def write_report(results, output_path):
    """Write the full prediction report to output_path."""
    total = len(results)
    correct = {t: 0 for t in TASKS}
    all_correct = 0

    for r in results:
        ok_all = True
        for t in TASKS:
            if r['preds'][t][0] == r['actual'][t]:
                correct[t] += 1
            else:
                ok_all = False
        if ok_all:
            all_correct += 1

    lines = []
    lines.append("=" * 78)
    lines.append(" CitiSense NLP Model Test Report")
    lines.append(f" Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f" Scenarios: {total}")
    lines.append("=" * 78)
    lines.append("")
    lines.append("ACCURACY SUMMARY")
    lines.append("-" * 78)
    for t in TASKS:
        acc = (correct[t] / total) * 100 if total else 0
        lines.append(f"  {TASKS_LABEL[t]:<28} {correct[t]:>4}/{total}  ({acc:.1f}%)")
    all_acc = (all_correct / total) * 100 if total else 0
    lines.append(f"  {'All three correct':<28} {all_correct:>4}/{total}  ({all_acc:.1f}%)")
    lines.append("")
    lines.append("-" * 78)
    lines.append("PER-SCENARIO DETAIL")
    lines.append("-" * 78)
    for r in results:
        lines.append(f"\n#{r['index']} {r['text']}")
        ok_all = True
        for t in TASKS:
            pred_label, conf = r['preds'][t]
            actual = r['actual'][t]
            ok = pred_label == actual
            if not ok:
                ok_all = False
            mark = 'OK ' if ok else 'XX '
            lines.append(
                f"    [{mark}] {t:<10} actual={actual:<18} "
                f"predicted={pred_label:<18} conf={conf*100:5.1f}%"
            )
        lines.append(f"    -> {'ALL THREE CORRECT' if ok_all else 'MISMATCH(ES)'}")

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')

    print(f"\nWrote report to {output_path}")
    print(f"Accuracy: sentiment {correct['sentiment']}/{total}, "
          f"category {correct['category']}/{total}, "
          f"urgency {correct['urgency']}/{total}. "
          f"All-correct {all_correct}/{total}.")


if __name__ == '__main__':
    main()
