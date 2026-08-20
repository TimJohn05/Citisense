# CitiSense NLP & Machine Learning Pipeline

This directory contains the Natural Language Processing (NLP) dataset, synthetic data generator, and machine learning model training pipeline for CitiSense (Taglish civic complaints).

## Architecture

1. **Dataset**: [`dataset/citisense_civic_nlp.csv`](./dataset/citisense_civic_nlp.csv)
   - Columns: `text`, `category`, `sentiment`, `urgency`
   - Features: Full-sentence Taglish contextual examples (negations, slang, compound sentences).

2. **Data Generator**: [`generate_dataset.py`](./generate_dataset.py)
   - Generates and augments realistic Taglish civic reports.
   - Run to add more samples:
     ```bash
     python3 generate_dataset.py
     ```

3. **NLP Classifier Pipeline**: [`train_model.py`](./train_model.py)
   - Uses **N-gram TF-IDF Vectorization** (unigrams, bigrams, and trigrams) to learn word sequences and contextual phrases (e.g., `"hindi sira"` vs `"sira"`).
   - Trains 3 dedicated classifiers:
     - **Sentiment**: `negative`, `neutral`, `positive`
     - **Category**: `waste`, `road`, `water`, `lighting`, `others`
     - **Urgency**: `low`, `moderate`, `emergency`
   - Saves trained models to `saved_models/*.joblib`.

## How to Run

```bash
cd ~/SE2-Project/ml
source .venv/bin/activate
python train_model.py
```
