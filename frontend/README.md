# Frontend (React + TypeScript)

This is the React frontend for Kube Credentials with two pages:
- Issue Credential page (calls issuer service at http://localhost:4001/issue)
- Verify Credential page (calls verifier service at http://localhost:4002/verify)

## Run Locally

```bash
npm install
npm run dev
```

Open http://localhost:5173

## Build for Production

```bash
npm run build
```