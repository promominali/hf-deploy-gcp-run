# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

This repo contains a minimal FastAPI service that exposes a Hugging Face Transformers sentiment-analysis model via a `/predict` HTTP endpoint, packaged for deployment to Google Cloud Run using Docker and `gcloud`.

Key pieces:
- `app.py`: FastAPI application and ML inference logic.
- `Makefile`: Common Docker build/push and Cloud Run deploy/test/local dev commands.
- `Dockerfile`: Container image definition for deployment.
- `requirements.txt`: Python dependencies (FastAPI, Uvicorn, Transformers, Torch, etc.).
- `README.md`: Brief instructions for pushing to Artifact Registry and deploying to Cloud Run.

## Architecture and Structure

### FastAPI application (`app.py`)
- Creates a single global `FastAPI` instance (`app`).
- Initializes a Hugging Face `pipeline` for `"sentiment-analysis"` using the `distilbert-base-uncased-finetuned-sst-2-english` model at import time. This means:
  - Model weights are downloaded/loaded once per process start.
  - All incoming requests share this in-memory pipeline for inference.
- Defines a single route:
  - `GET /predict` with query parameter `text: str`.
  - Returns the raw output of the Transformers classifier (a list of label/score dicts) directly as JSON.

### Entrypoints
- Cloud Run / production:
  - The Docker image is expected to run a Uvicorn server pointing to `app:app` (see `Dockerfile`).
  - Cloud Run receives HTTP traffic and forwards it to the container, which serves the FastAPI app.
- `main.py`:
  - Standalone script that just prints a greeting; not used for serving the API.

### Deployment workflow
- Docker image is built locally and pushed to Google Artifact Registry (or Container Registry) under `gcr.io/<PROJECT_ID>/huggingface-small:latest`.
- The image is then deployed to Cloud Run as the `huggingface-small` service in a chosen region (default in `Makefile` is `us-central1`).
- A convenience URL format `https://<SERVICE_NAME>-<REGION>.run.app` is used to construct a test endpoint in `Makefile`.

## Common Commands

All commands assume you are in the repo root.

### Dependency management

- (If using `requirements.txt`):
  ```bash
  pip install -r requirements.txt
  ```
- (If using `pyproject.toml` with uv):
  ```bash
  uv sync
  ```

### Local development server

Run the FastAPI app locally with Uvicorn (no Docker):

```bash
make local
```

This runs:

```bash
uvicorn app:app --host 0.0.0.0 --port 8080 --reload
```

Test locally:

```bash
curl "http://localhost:8080/predict?text=I+love+this+movie"
```

### Docker build & push

Build Docker image:

```bash
make build
```

Push image to Google Artifact/Container Registry (uses `PROJECT_ID` from `Makefile`):

```bash
make push
```

Or run the whole build + push + deploy chain:

```bash
make all
```

If you prefer manual `gcloud` commands (as shown in `README.md`):

```bash
gcloud auth configure-docker

docker build -t gcr.io/<PROJECT_ID>/huggingface-small:latest .

docker push gcr.io/<PROJECT_ID>/huggingface-small:latest
```

### Deploy to Cloud Run

Using `Makefile` (recommended):

```bash
make deploy
```

This expands to:

```bash
gcloud run deploy huggingface-small \
  --image gcr.io/fullstackpro-python/huggingface-small:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

Using raw `gcloud` (as in `README.md`, replace placeholders):

```bash
gcloud run deploy huggingface-small \
  --image gcr.io/<PROJECT_ID>/huggingface-small:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

### Test deployed endpoint

After deployment, either use the Cloud Run URL from `gcloud run services describe` or rely on the convention in the `Makefile`:

```bash
make test
```

Which calls:

```bash
curl "https://huggingface-small-us-central1.run.app/predict?text=I+love+this+movie"
```

Or, following `README.md` (replace `<CLOUD_RUN_URL>`):

```bash
curl "https://<CLOUD_RUN_URL>/predict?text=I+love+this+movie"
```

## Notes for Future Warp Agents

- The primary place to modify API behavior is `app.py` (e.g., add new routes, change the model, alter request/response schemas).
- Cloud Run configuration (service name, region, GCP project, image name) is centralized in `Makefile` variables at the top of the file.
- If you introduce testing, consider wiring it into `Makefile` as an additional target (e.g., `pytest`) so `make test` can run both HTTP smoke tests and unit tests.