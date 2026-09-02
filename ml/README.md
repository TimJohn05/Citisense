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
