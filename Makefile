PROJECT_ID := fullstackpro-python
REGION := us-central1
SERVICE_NAME := huggingface-small
REPO := huggingface-repo
IMAGE := $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(REPO)/$(SERVICE_NAME):latest
URL := https://$(SERVICE_NAME)-$(REGION).run.app
TEXT ?= I love this movie

# Build the Docker image with the correct tag
build:
	docker buildx build --platform linux/amd64 -t $(IMAGE) .

# Push the image to Artifact Registry (requires build first)
push: build
	docker push $(IMAGE)

# Deploy to Cloud Run (requires push first)
deploy: push
	gcloud run deploy $(SERVICE_NAME) \
		--image $(IMAGE) \
		--platform managed \
		--region $(REGION) \
		--allow-unauthenticated

# Convenience target: build + push + deploy
all: deploy

# Test the deployed service with configurable sample text
test:
	curl --get "$(URL)/predict" --data-urlencode "text=$(TEXT)"

# Test the local service (assumes make local is running)
local-test:
	curl --get "http://localhost:8080/predict" --data-urlencode "text=$(TEXT)"

# Run locally with uvicorn (no Docker)
local:
	uv run --with-requirements requirements.txt uvicorn app:app --host 0.0.0.0 --port 8080 --reload

# Create Artifact Registry repo (run once)
create-repo:
	gcloud artifacts repositories create $(REPO) \
		--repository-format=docker \
		--location=$(REGION) \
		--description="Docker repo for Hugging Face models"

# Remove local Docker image for this service
clean-image:
	-docker rmi $(IMAGE)

# Remove common local artifacts (virtualenv and __pycache__)
clean-local:
	-rm -rf .venv __pycache__ */__pycache__

# Full local cleanup helper (does NOT touch GCP resources)
clean: clean-image clean-local

# Delete the Cloud Run service in GCP
clean-service:
	gcloud run services delete $(SERVICE_NAME) \
		--region $(REGION) \
		--quiet

# Delete container image from Artifact Registry
clean-remote-image:
	gcloud artifacts docker images delete $(IMAGE) \
		--quiet \
		--delete-tags || true

# Cleanup helper for remote GCP resources (service + image)
clean-remote: clean-service clean-remote-image
