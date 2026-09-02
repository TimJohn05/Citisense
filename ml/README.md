# CitiSense NLP & Machine Learning Pipeline

This directory contains the Natural Language Processing (NLP) dataset, synthetic data generator, and machine learning model training pipeline for CitiSense (Taglish civic complaints).

## Architecture

1. **Dataset**: [`dataset/citisense_civic_nlp.csv`](./dataset/citisense_civic_nlp.csv)
   - Columns: `text`, `category`, `sentiment`, `urgency`
   - Features: Full-sentence Taglish contextual examples (negations, slang, compound sentences).
   - ~3,000 samples spanning 11 civic categories.

2. **Data Generator**: [`generate_dataset.py`](./generate_dataset.py)
   - Generates and augments realistic Taglish civic reports for Calamba City.
   - Run to add more samples:
     ```bash
     python3 generate_dataset.py
     ```

3. **NLP Classifier Pipeline**: [`train_model.py`](./train_model.py)
   - Uses **TensorFlow / Keras neural networks** with a `TextVectorization`
     layer (multi-hot n-grams: unigrams + bigrams) to learn word sequences and
     contextual phrases (e.g., `"hindi sira"` vs `"sira"`).
   - Architecture: Dense(64) → Dropout(0.5) → Dense(32) → Dropout(0.5) → Dense(classes, softmax),
     trained with Adam + sparse categorical crossentropy, early stopping.
   - Trains 3 dedicated classifiers:
     - **Sentiment**: `negative`, `neutral`, `positive`
     - **Category**: the 11 civic categories (`waste`, `road`, `water`,
       `lighting`, `peace_order`, `traffic_obstruction`, `flood_drainage`,
       `health_sanitation`, `electrical_hazard`, `public_facilities`,
       `general_inquiry`)
     - **Urgency**: `low`, `moderate`, `emergency`
   - Saves to `saved_models/`:
     - `*_model.keras` — the trained Keras model
     - `*_encoder.pkl` — the `LabelEncoder` for mapping labels ↔ integers

## How to Run

```bash
cd ~/SE2-Project/ml
source .venv/bin/activate
python3 generate_dataset.py   # optional: regenerate/augment the dataset
python train_model.py          # trains + evaluates + saves all 3 models
```

After training, `train_model.py` runs a quick interactive test with sample
Taglish sentences to sanity-check category/sentiment/urgency predictions.

## Testing the models (100 scenarios)

There is a dedicated test harness that runs the trained models against a
fixed set of 100 Taglish scenarios and writes a full report to a file.

```bash
cd ~/SE2-Project/ml

# 1. Regenerate the fixed 100-scenario test set (optional)
python3 generate_test_scenarios.py     # -> test_scenarios.csv

# 2. Run the test and write results to a file
python test_nlp.py                       # -> test_results.txt
python test_nlp.py my_out.txt            # custom output path
python test_nlp.py scenarios.csv out.txt # custom input + output
```

- **`generate_test_scenarios.py`** — writes `test_scenarios.csv` (100 hand-written
  Taglish scenarios covering all 11 categories, all sentiments, all urgencies).
  These are **held out** (not used for training) so the report measures real
  generalization.
- **`test_nlp.py`** — loads the Keras models + encoders, predicts
  sentiment/category/urgency for every scenario, prints a live progress line,
  and writes `test_results.txt`: an accuracy summary plus per-scenario detail
  (actual vs. predicted + confidence for each task).

## Model files (saved_models/)

| File | Purpose |
| --- | --- |
| `sentiment_model.keras` / `sentiment_encoder.pkl` | Sentiment: negative/neutral/positive |
| `category_model.keras` / `category_encoder.pkl` | Category: 11 civic classes |
| `urgency_model.keras` / `urgency_encoder.pkl` | Urgency: low/moderate/emergency |

> ⚠️ These Keras models are the current pipeline. The older scikit-learn
> `*_model.joblib` / `*_model.pkl` files were replaced by this TensorFlow
> version and are no longer produced by `train_model.py`.

## Requirements

```bash
pip install tensorflow pandas scikit-learn numpy
```
