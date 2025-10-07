#!/bin/bash

# Quick deployment script for local development

echo "Building Docker images..."
cd services/issuer && docker build -t kube-credential-issuer:latest .
cd ../verifier && docker build -t kube-credential-verifier:latest .
cd ../..

echo "Loading images into minikube..."
minikube image load kube-credential-issuer:latest
minikube image load kube-credential-verifier:latest

echo "Deploying to Kubernetes..."
kubectl apply -f k8s/issuer.yaml
kubectl apply -f k8s/verifier.yaml

echo "Waiting for deployments..."
kubectl wait --for=condition=available --timeout=300s deployment/issuer-deployment
kubectl wait --for=condition=available --timeout=300s deployment/verifier-deployment

echo "Getting service URLs..."
echo "Issuer service:"
minikube service issuer-service --url
echo "Verifier service:"
minikube service verifier-service --url

echo "Deployment complete!"