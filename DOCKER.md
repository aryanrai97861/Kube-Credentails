# Docker Setup Guide for Kube Credentials

## Prerequisites

1. **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
2. **Docker Compose** (included with Docker Desktop)

### Installation

**Windows:**
- Download Docker Desktop from https://www.docker.com/products/docker-desktop
- Install and start Docker Desktop
- Enable WSL 2 backend (recommended)

**Mac:**
- Download Docker Desktop from https://www.docker.com/products/docker-desktop
- Install and start Docker Desktop

**Linux:**
```bash
# Install Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## Quick Start

1. **Start Docker Desktop** (Windows/Mac) or **Docker daemon** (Linux)

2. **Clone and navigate to project:**
```bash
cd "C:/Users/aryan/OneDrive/Desktop/projects/Kube Credentials"
```

3. **Start all services:**
```bash
# Option 1: Use Docker Compose
docker-compose up --build -d

# Option 2: Use helper script
./docker-start.sh    # Linux/Mac
docker-start.bat     # Windows
```

4. **Access the application:**
- Frontend: http://localhost:3000
- Issuer API: http://localhost:4001/health
- Verifier API: http://localhost:4002/health

## Docker Services

### Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Issuer API    │    │  Verifier API   │
│   (Nginx)       │    │   (Node.js)     │    │   (Node.js)     │
│   Port: 3000    │    │   Port: 4001    │    │   Port: 4002    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Shared SQLite  │
                    │    Database     │
                    │   (Volume)      │
                    └─────────────────┘
```

### Service Details

**Frontend Container:**
- Built with Vite + React
- Served by Nginx
- Includes API proxy configuration
- Production-optimized build

**Issuer Container:**
- Node.js + TypeScript
- Express.js API server
- SQLite database connection
- Health check endpoint

**Verifier Container:**
- Node.js + TypeScript
- Express.js API server
- Shared SQLite database
- Health check endpoint

## Commands

### Development
```bash
# Start in development mode
docker-compose up --build

# View logs
docker-compose logs -f
docker-compose logs -f issuer    # Specific service

# Restart a service
docker-compose restart issuer

# Rebuild and restart
docker-compose up --build issuer
```

### Production
```bash
# Start production environment
docker-compose -f docker-compose.prod.yml up --build -d

# Production URLs
# Frontend: http://localhost:80
# APIs: same ports (4001, 4002)
```

### Management
```bash
# Check service status
docker-compose ps

# Stop all services
docker-compose down

# Stop and remove volumes (⚠️ deletes database)
docker-compose down -v

# View container stats
docker stats

# Execute commands in container
docker-compose exec issuer /bin/sh
```

## Troubleshooting

### Common Issues

**1. Docker Desktop not running**
```
Error: Cannot connect to the Docker daemon
Solution: Start Docker Desktop application
```

**2. Port already in use**
```
Error: Port 4001 is already allocated
Solution: Stop conflicting services or change ports in docker-compose.yml
```

**3. Build failures**
```bash
# Clear Docker cache
docker system prune -a

# Rebuild without cache
docker-compose build --no-cache
```

**4. Database not shared between services**
```bash
# Check volume
docker volume ls
docker volume inspect kubecredentials_shared_db

# Recreate volume
docker-compose down -v
docker-compose up --build -d
```

### Health Checks
```bash
# Test API endpoints
curl http://localhost:4001/health
curl http://localhost:4002/health

# Test credential flow
curl -X POST http://localhost:4001/issue \
  -H "Content-Type: application/json" \
  -d '{"name":"test","role":"user"}'

curl -X POST http://localhost:4002/verify \
  -H "Content-Type: application/json" \
  -d '{"name":"test","role":"user"}'
```

### Performance Tuning
```bash
# Increase Docker memory (Docker Desktop Settings)
# Recommended: 4GB+ for smooth operation

# Monitor resource usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

## Environment Variables

### Available Variables
```bash
# Issuer Service
PORT=4001                    # API port
DB_PATH=/app/shared/credentials.db  # Database path
POD_NAME=issuer-docker      # Worker identifier

# Verifier Service  
PORT=4002                    # API port
DB_PATH=/app/shared/credentials.db  # Database path
POD_NAME=verifier-docker    # Worker identifier

# Frontend
VITE_API_URL=http://localhost:4001      # Issuer API URL
VITE_VERIFIER_API_URL=http://localhost:4002  # Verifier API URL
```

### Custom Configuration
Create `.env` file in project root:
```bash
# Custom ports
ISSUER_PORT=5001
VERIFIER_PORT=5002
FRONTEND_PORT=8080

# Custom database
DB_PATH=/custom/path/credentials.db
```

## Testing

### Automated Testing
```bash
# Run test script (after services are up)
./test-docker.sh

# Manual testing
# 1. Open http://localhost:3000
# 2. Issue a credential
# 3. Verify the same credential
# 4. Check that verification succeeds
```

### Load Testing
```bash
# Install Apache Bench (if not installed)
# Windows: Download from Apache website
# Mac: brew install httpd
# Linux: sudo apt-get install apache2-utils

# Test issuer endpoint
ab -n 100 -c 10 -T 'application/json' -p test-credential.json http://localhost:4001/issue

# Create test-credential.json:
echo '{"name":"loadtest","role":"user"}' > test-credential.json
```