# How to Check if Kubernetes is Working

## ✅ **Current Status: Kubernetes is Running!**

Based on your system check, Kubernetes (minikube) is now running properly.

## Essential Kubernetes Health Checks

### 1. **Cluster Connectivity**
```bash
# Check if kubectl can connect to cluster
kubectl cluster-info

# Expected output:
# Kubernetes control plane is running at https://127.0.0.1:xxxxx
# CoreDNS is running at https://127.0.0.1:xxxxx/...
```

### 2. **Node Status**
```bash
# Check if nodes are ready
kubectl get nodes

# Expected output:
# NAME       STATUS   ROLES           AGE    VERSION
# minikube   Ready    control-plane   103d   v1.33.1
```

### 3. **System Pods**
```bash
# Check system pods are running
kubectl get pods -n kube-system

# All pods should show STATUS: Running
```

### 4. **Basic Functionality Test**
```bash
# Create a test pod
kubectl run test-pod --image=nginx --restart=Never

# Check if it's running
kubectl get pods

# Clean up
kubectl delete pod test-pod
```

## For Your Kube Credentials Project

### 5. **Deploy Your Application**
```bash
# Use your deployment script
./deploy.sh

# Or deploy manually
kubectl apply -f k8s/namespace-and-scaling.yaml
kubectl apply -f k8s/storage.yaml
kubectl apply -f k8s/issuer.yaml
kubectl apply -f k8s/verifier.yaml
kubectl apply -f k8s/frontend.yaml
```

### 6. **Check Your Deployments**
```bash
# Check if your pods are running
kubectl get pods

# Check services
kubectl get services

# Check deployments
kubectl get deployments
```

### 7. **Test Your Services**
```bash
# Get service URLs (minikube)
minikube service issuer-service --url
minikube service verifier-service --url
minikube service frontend-service --url

# Or use port-forwarding
kubectl port-forward service/frontend-service 3000:80 &
kubectl port-forward service/issuer-service 4001:80 &
kubectl port-forward service/verifier-service 4002:80 &
```

### 8. **Monitor Your Application**
```bash
# Watch pods in real-time
kubectl get pods -w

# Check pod logs
kubectl logs -f deployment/issuer-deployment
kubectl logs -f deployment/verifier-deployment

# Check resource usage
kubectl top pods
```

## Troubleshooting Common Issues

### Issue: "Unable to connect to the server"
**Solution:**
```bash
# Start minikube
minikube start

# Check status
minikube status
```

### Issue: "No resources found"
**Solution:**
```bash
# Check current namespace
kubectl config current-context

# List all resources
kubectl get all --all-namespaces
```

### Issue: Pods stuck in "Pending" state
**Solution:**
```bash
# Check pod details
kubectl describe pod <pod-name>

# Check node resources
kubectl describe nodes
```

### Issue: Image pull errors
**Solution:**
```bash
# For minikube, load images locally
minikube image load <image-name>

# Or build images inside minikube
eval $(minikube docker-env)
docker build -t <image-name> .
```

## Quick Health Check Script

Create this script to check everything at once:

```bash
#!/bin/bash
echo "🔍 Kubernetes Health Check"
echo "=========================="

echo "1. Cluster Info:"
kubectl cluster-info --request-timeout=5s

echo -e "\n2. Node Status:"
kubectl get nodes

echo -e "\n3. System Pods:"
kubectl get pods -n kube-system --no-headers | wc -l
echo "System pods running: $(kubectl get pods -n kube-system --no-headers | grep Running | wc -l)"

echo -e "\n4. Your Application:"
kubectl get pods 2>/dev/null || echo "No application pods found"

echo -e "\n5. Services:"
kubectl get services 2>/dev/null || echo "No services found"

echo -e "\n✅ Kubernetes is $(kubectl get nodes --no-headers 2>/dev/null | grep Ready | wc -l > 0 && echo "WORKING" || echo "NOT READY")"
```

## Current Status Summary

**✅ Your Kubernetes Setup:**
- Minikube cluster: **Running**
- Node status: **Ready**
- System pods: **Running**
- kubectl connectivity: **Working**

**Ready for deployment!** You can now deploy your Kube Credentials application using:
```bash
./deploy.sh
```

## Next Steps

1. **Deploy your application:**
   ```bash
   ./deploy.sh
   ```

2. **Access your services:**
   ```bash
   minikube service frontend-service --url
   ```

3. **Monitor your application:**
   ```bash
   kubectl get pods -w
   ```

Your Kubernetes cluster is ready to run your microservices application! 🚀