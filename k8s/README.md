# Kubernetes Deployment Guide

## Prerequisites

- Docker installed
- Kubernetes cluster (minikube, AKS, GKE, or other)
- kubectl configured

## Build Docker Images

From the project root:

```bash
# Build issuer image
cd services/issuer
docker build -t kube-credential-issuer:latest .

# Build verifier image
cd ../verifier
docker build -t kube-credential-verifier:latest .
```

## Local Deployment (minikube)

1. Start minikube:
```bash
minikube start
```

2. Load images into minikube:
```bash
minikube image load kube-credential-issuer:latest
minikube image load kube-credential-verifier:latest
```

3. Deploy services:
```bash
kubectl apply -f k8s/issuer.yaml
kubectl apply -f k8s/verifier.yaml
```

4. Check deployment status:
```bash
kubectl get pods
kubectl get services
```

5. Access services:
```bash
# Get service URLs
minikube service issuer-service --url
minikube service verifier-service --url
```

## Cloud Deployment (AWS EKS, GKE, AKS)

1. Push images to container registry:
```bash
# Example for AWS ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-west-2.amazonaws.com
docker tag kube-credential-issuer:latest <account>.dkr.ecr.us-west-2.amazonaws.com/kube-credential-issuer:latest
docker push <account>.dkr.ecr.us-west-2.amazonaws.com/kube-credential-issuer:latest
# Repeat for verifier
```

2. Update image references in k8s/*.yaml files

3. Deploy to cluster:
```bash
kubectl apply -f k8s/
```

## Scaling

Scale replicas:
```bash
kubectl scale deployment issuer-deployment --replicas=3
kubectl scale deployment verifier-deployment --replicas=3
```

## Clean Up

```bash
kubectl delete -f k8s/
```