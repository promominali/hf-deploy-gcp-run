from fastapi import FastAPI
from transformers import pipeline

app = FastAPI()
classifier = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")

@app.get("/")
def read_root():
    return {"message": "Welcome to the Sentiment Analysis API!"}

@app.get("/predict")
def predict(text: str):
    return classifier(text)
