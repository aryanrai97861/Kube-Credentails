# Kube Credentials

A microservice-based credential issuance and verification system built with Node.js (TypeScript), React, and Kubernetes.

## Architecture

- **Issuer Service** (Port 4001): Issues credentials and tracks which worker handled the request
- **Verifier Service** (Port 4002): Verifies if credentials have been issued 
- **Frontend** (Port 5173): React UI with Issue and Verify pages
- **Database**: Each service uses its own SQLite database for independence

## Project Structure

```
├── services/
│   ├── issuer/          # Credential issuance microservice
│   └── verifier/        # Credential verification microservice
├── frontend/            # React TypeScript frontend
├── k8s/                # Kubernetes manifests
├── deploy.sh           # Quick deployment script
└── TESTING.md          # Testing documentation
```

## API Documentation

### Issuer Service (POST /issue)

**Request:**
```json
{
  "name": "Alice",
  "role": "admin"
}
```

**Response (New Credential):**
```json
{
  "message": "credential issued by worker-abc123",
  "id": "uuid-here",
  "worker": "worker-abc123"
}
```

**Response (Duplicate):**
```json
{
  "message": "credential already issued",
  "id": "uuid-here", 
  "worker": "worker-abc123"
}
```

### Verifier Service (POST /verify)

**Request:**
```json
{
  "name": "Alice",
  "role": "admin"
}
```

**Response (Valid):**
```json
{
  "valid": true,
  "id": "uuid-here",
  "worker": "worker-abc123",
  "issued_at": 1703123456789
}
```

**Response (Invalid):**
```json
{
  "valid": false
}
```

## Quick Start

### Local Development

1. **Start Issuer Service:**
```bash
cd services/issuer
npm install
npm run dev  # Runs on http://localhost:4001
```

2. **Start Verifier Service:**
```bash
cd services/verifier  
npm install
npm run dev  # Runs on http://localhost:4002
```

3. **Start Frontend:**
```bash
cd frontend
npm install
npm run dev  # Runs on http://localhost:5173
```

### Docker Deployment

**Option 1: Docker Compose (Recommended)**
```bash
# Start all services with shared database
docker-compose up --build -d

# Or use the helper script
./docker-start.sh          # Linux/Mac
# or
docker-start.bat           # Windows
```

**Option 2: Individual Containers**
```bash
# Create shared volume for database
docker volume create kube-credentials-db

# Build and run issuer
cd services/issuer
docker build -t kube-credential-issuer .
docker run -d -p 4001:4001 -v kube-credentials-db:/app/shared \
  -e POD_NAME=issuer-docker kube-credential-issuer

# Build and run verifier
cd services/verifier  
docker build -t kube-credential-verifier .
docker run -d -p 4002:4002 -v kube-credentials-db:/app/shared \
  -e POD_NAME=verifier-docker kube-credential-verifier

# Build and run frontend
cd frontend
docker build -t kube-credential-frontend .
docker run -d -p 3000:80 kube-credential-frontend
```

**Access Points:**
- Frontend: http://localhost:3000
- Issuer API: http://localhost:4001
- Verifier API: http://localhost:4002

### Kubernetes Deployment

```bash
# Build images
cd services/issuer && docker build -t kube-credential-issuer:latest .
cd ../verifier && docker build -t kube-credential-verifier:latest .

# Deploy to minikube
minikube start
minikube image load kube-credential-issuer:latest
minikube image load kube-credential-verifier:latest
kubectl apply -f k8s/

# Or use the deployment script
chmod +x deploy.sh
./deploy.sh
```

## Features

✅ **Microservice Architecture**: Separate, independently scalable services  
✅ **Worker Identification**: Each response includes which pod/worker handled the request  
✅ **Idempotency**: Duplicate credential issuance is handled gracefully  
✅ **TypeScript**: Full type safety across backend and frontend  
✅ **Unit Tests**: Jest tests for core business logic  
✅ **Containerization**: Docker images ready for deployment  
✅ **Kubernetes Ready**: Complete K8s manifests with scaling support  
✅ **React Frontend**: Clean UI for testing both services  
✅ **Docker Compose**: Full orchestration with shared database volume  
✅ **Production Ready**: Optimized Docker builds with health checks  

## Testing

Run unit tests:
```bash
# Backend tests
cd services/issuer && npm test
cd services/verifier && npm test

# Frontend tests
cd frontend && npm test
```

See [TESTING.md](./TESTING.md) for comprehensive testing documentation.

## Cloud Deployment

This system is designed for deployment on free-tier cloud platforms:

- **AWS**: EKS free tier + ECR
- **Google Cloud**: GKE autopilot + Container Registry  
- **Azure**: AKS free tier + Container Registry

See [k8s/README.md](./k8s/README.md) for detailed cloud deployment instructions.

## Assignment Compliance

✅ Node.js (TypeScript) APIs  
✅ Two microservices (Issuer + Verifier)  
✅ Docker containerization  
✅ Independent persistence layers  
✅ React (TypeScript) frontend with two pages  
✅ Worker ID in responses  
✅ JSON credential handling  
✅ Proper error handling  
✅ Unit tests included  
✅ Kubernetes YAML manifests  
✅ Cloud deployment ready
