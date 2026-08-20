"""CitiSense sentiment microservice.

Run:  uvicorn server:app --host 0.0.0.0 --port 8000
API:  POST /sentiment  {"text": "..."}
      -> {"sentiment": "...", "confidence": 0.0, "label_raw": "LABEL_x"}

Model: cardiffnlp/twitter-xlm-roberta-base-sentiment (multilingual, incl. Tagalog).
LABEL_0 = negative, LABEL_1 = neutral, LABEL_2 = positive.
"""

from fastapi import FastAPI
from pydantic import BaseModel
from transformers import pipeline

MODEL_NAME = "cardiffnlp/twitter-xlm-roberta-base-sentiment"
ID2LABEL = {"LABEL_0": "negative", "LABEL_1": "neutral", "LABEL_2": "positive"}

app = FastAPI(title="CitiSense Sentiment Service")

class SentimentRequest(BaseModel):
    text: str

class SentimentResponse(BaseModel):
    sentiment: str
    confidence: float
    label_raw: str


@app.on_event("startup")
def _load_model() -> None:
    global _pipe
    _pipe = pipeline("sentiment-analysis", model=MODEL_NAME)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/sentiment", response_model=SentimentResponse)
def sentiment(req: SentimentRequest) -> SentimentResponse:
    result = _pipe(req.text[:512])[0]
    return SentimentResponse(
        sentiment=ID2LABEL.get(result["label"], result["label"]),
        confidence=round(float(result["score"]), 4),
        label_raw=result["label"],
    )
