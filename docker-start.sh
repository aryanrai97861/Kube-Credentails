#!/bin/bash

echo "🐳 Building and starting Kube Credentials with Docker Compose..."

# Build and start all services
docker-compose up --build -d

echo "✅ Services started successfully!"
echo ""
echo "🌐 Access the application:"
echo "   Frontend: http://localhost:3000"
echo "   Issuer API: http://localhost:4001"
echo "   Verifier API: http://localhost:4002"
echo ""
echo "📊 Check service status:"
echo "   docker-compose ps"
echo ""
echo "📝 View logs:"
echo "   docker-compose logs -f [service-name]"
echo ""
echo "🛑 Stop services:"
echo "   docker-compose down"