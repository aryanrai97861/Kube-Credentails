#!/bin/bash

echo "🧪 Testing Kube Credentials Docker Setup..."

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Test issuer service
echo "🔍 Testing Issuer Service..."
ISSUE_RESPONSE=$(curl -s -X POST "http://localhost:4001/issue" \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","role":"admin"}')

if [[ $ISSUE_RESPONSE == *"credential issued by"* ]]; then
  echo "✅ Issuer service working"
  echo "Response: $ISSUE_RESPONSE"
else
  echo "❌ Issuer service failed"
  echo "Response: $ISSUE_RESPONSE"
  exit 1
fi

# Test verifier service
echo "🔍 Testing Verifier Service..."
VERIFY_RESPONSE=$(curl -s -X POST "http://localhost:4002/verify" \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","role":"admin"}')

if [[ $VERIFY_RESPONSE == *"valid"* ]]; then
  echo "✅ Verifier service working"
  echo "Response: $VERIFY_RESPONSE"
else
  echo "❌ Verifier service failed"
  echo "Response: $VERIFY_RESPONSE"
  exit 1
fi

# Test frontend
echo "🔍 Testing Frontend..."
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000")

if [[ $FRONTEND_RESPONSE == "200" ]]; then
  echo "✅ Frontend service working"
else
  echo "❌ Frontend service failed (HTTP $FRONTEND_RESPONSE)"
  exit 1
fi

echo ""
echo "🎉 All services are working correctly!"
echo "🌐 Open http://localhost:3000 in your browser to use the application"