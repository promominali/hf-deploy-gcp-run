
## Push to Google Artifact Registry
gcloud auth configure-docker
docker build -t gcr.io/<PROJECT_ID>/huggingface-small:latest .
docker push gcr.io/<PROJECT_ID>/huggingface-small:latest

## Deploy on Cloud Run (serverless, easy)
gcloud run deploy huggingface-small \
  --image gcr.io/<PROJECT_ID>/huggingface-small:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated

## Test the endpoint
curl "https://<CLOUD_RUN_URL>/predict?text=I+love+this+movie"

## Makefile
make all

make build
make push
make deploy
make test
make local
