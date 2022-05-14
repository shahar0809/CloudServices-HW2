# This script requires gcloud, terraform and docker

# Login to GCP from CLI
gcloud auth login

echo "Enter project ID"
read PROJECT_ID

echo "Enter billing account"
read BILLING
export BILLING_ACCOUNT=$BILLING

# Enable permissions to push docker image to GCR
gcloud auth configure-docker

# Build docker image of flask server and upload it to gcr
docker build -t gcr.io/$PROJECT_ID/web-server:v1 .
docker push gcr.io/$PROJECT_ID/web-server:v1

terraform apply -auto-approve
