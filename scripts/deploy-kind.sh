#!/usr/bin/env bash
set -eu

: "${AWS_REGION:?AWS_REGION is required}"
: "${ECR_REGISTRY:?ECR_REGISTRY is required}"
: "${K8S_NAMESPACE:?K8S_NAMESPACE is required}"

MANIFEST=/tmp/jenkins-java-cicd.yaml

# Get a fresh ECR authentication token using the Kind EC2 IAM role
ECR_PASSWORD="$(aws ecr get-login-password --region "$AWS_REGION")"

# Create the namespace if it does not exist
kubectl create namespace "$K8S_NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

# Create or refresh the private ECR pull secret
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server="$ECR_REGISTRY" \
  --docker-username=AWS \
  --docker-password="$ECR_PASSWORD" \
  --namespace="$K8S_NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

unset ECR_PASSWORD

# Apply the deployment and service
kubectl apply -n "$K8S_NAMESPACE" -f "$MANIFEST"

# Wait until the rollout completes
kubectl rollout status deployment/jenkins-java-cicd \
  -n "$K8S_NAMESPACE" --timeout=180s

kubectl get deployments,pods,svc -n "$K8S_NAMESPACE"
