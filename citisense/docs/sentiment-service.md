# Sentiment Analysis Service — Recommendation & Real-System Setup

## Current: Offline Taglish Lexicon Engine (v3)

The app ships with `lib/services/sentiment_engine.dart` — a rule-based Taglish (Tagalog + English) analyzer that works **fully offline**:

1. Tokenizes input and strips Tagalog particles (`po`, `naman`, `kasi`, `lang`, etc.)
2. Checks for negation in the previous meaningful token (`hindi naman mabaho` → positive)
3. Matches against phrase lists (longer matches first) and word lists
4. Returns sentiment (negative/neutral/positive), confidence (0.0–1.0), and a per-category recommendation

This is fast, requires zero internet, and is sufficient for demos and the paper's prototype.

## Why an ML model may still be needed

The lexicon engine is a heuristic — it cannot understand meaning, context, or sarcasm.
For the paper's "real system" section, a **machine-learning model** served as a tiny
Python microservice demonstrates a production-grade approach.

## Recommended NLP approach
Use a **multilingual transformer model** served as a tiny Python microservice. The Flutter app POSTs the complaint text and receives a sentiment JSON.

| Model (Hugging Face) | Language coverage | Size | Good for |
|---|---|---|---|
| `cardiffnlp/twitter-xlm-roberta-base-sentiment` | multilingual incl. Tagalog | ~1.1GB | **Start here.** Positive/Neutral/Negative |
| `lxyuan/distilbert-base-multilingual-cased-sentiments-student` | EN + multilingual | ~250MB | Faster/lightweight 3-class |
| `jcblaise/bert-tagalog-base` (fine-tuned) | Tagalog-focused | ~420MB | Best accuracy for pure Filipino if you fine-tune on a Filipino sentiment dataset |

Two-stage plan (recommended):
1. **Stage A (fast to try):** FastAPI + `cardiffnlp/twitter-xlm-roberta-base-sentiment`. Works on this laptop, no training needed.
2. **Stage B (paper-grade):** fine-tune `jcblaise/bert-tagalog-base` on a Filipino sentiment dataset and report its measured held-out performance. The service API stays identical, so the app doesn't change. Do not claim a target accuracy until it has been independently evaluated on CitiSense-style Taglish reports.

## Setup — Stage A (run it today)

### 1. Create a Python venv and install deps
```bash
mkdir -p sentiment-service
cd sentiment-service
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install fastapi "uvicorn[standard]" transformers torch requests
```

### 2. Server script
Copy `docs/sentiment_service.py` (below) into `sentiment-service/server.py`.

### 3. Run the server
```bash
source .venv/bin/activate
uvicorn server:app --host 0.0.0.0 --port 8000
# first start downloads the model (~1.1GB) once
```

### 4. Test it
```bash
curl -s http://localhost:8000/sentiment \
  -H "Content-Type: application/json" \
  -d '{"text":"Walang ilaw sa kalye, delikado para sa mga bata, paki ayos naman po."}'
# -> {"sentiment":"negative","confidence":0.97,"label_raw":"LABEL_0"}
```

### 5. Point the app at it (later)
When the phone and this PC are on the same Wi-Fi, the app calls `http://<PC-lan-ip>:8000/sentiment`.
On Android you must allow cleartext HTTP for the dev IP (or use `adb reverse tcp:8000 tcp:8000` when the phone is USB-connected so the app can use `http://localhost:8000`).

## API contract (keep it stable for the app)
```
POST /sentiment
{"text": "<complaint description>"}
200 OK
{"sentiment": "positive" | "neutral" | "negative",
 "confidence": 0.0-1.0,
 "label_raw": "LABEL_0"}
```
`LABEL_0 = negative`, `LABEL_1 = neutral`, `LABEL_2 = positive` for the cardiff model.

## Swapping in a fine-tuned model later
Keep the same `/sentiment` endpoint; only change the `MODEL_NAME` constant. The app does not change.
