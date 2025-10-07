# Testing Guide

## Backend Services

Both issuer and verifier services include unit tests using Jest.

### Run Tests

```bash
# Issuer service tests
cd services/issuer
npm install
npm test

# Verifier service tests  
cd services/verifier
npm install
npm test
```

### Test Coverage

- **Issuer Service**:
  - Credential issuance with worker ID
  - Idempotency (duplicate credentials)
  - Database persistence
  
- **Verifier Service**:
  - Credential verification (valid/invalid)
  - Worker and timestamp retrieval
  - Database queries

### CI/CD Testing

Add to your CI pipeline (GitHub Actions example):

```yaml
name: Test Services
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-node@v3
      with:
        node-version: '20'
    - name: Test Issuer
      run: |
        cd services/issuer
        npm ci
        npm test
    - name: Test Verifier
      run: |
        cd services/verifier
        npm ci
        npm test
```

## Frontend Testing

Frontend uses Vitest for testing React components.

```bash
cd frontend
npm install
npm test
```

## Integration Testing

To test the full system locally:

1. Start services:
```bash
# Terminal 1: Issuer
cd services/issuer && npm run dev

# Terminal 2: Verifier  
cd services/verifier && npm run dev

# Terminal 3: Frontend
cd frontend && npm run dev
```

2. Test endpoints:
```bash
# Issue a credential
curl -X POST http://localhost:4001/issue \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","role":"admin"}'

# Verify the credential
curl -X POST http://localhost:4002/verify \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","role":"admin"}'
```