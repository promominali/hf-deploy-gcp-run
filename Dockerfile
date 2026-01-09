FROM python:3.10-slim

WORKDIR /app
COPY app.py /app

RUN pip install fastapi uvicorn transformers torch

EXPOSE 8080
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]