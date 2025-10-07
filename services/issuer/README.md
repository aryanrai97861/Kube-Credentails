# Issuer Service

API endpoints:
- POST /issue — accepts credential JSON body. Returns issued id, worker and message.
- GET /health — simple health check.

DB: SQLite (better-sqlite3). Default DB file: `issuer.db` in service root. You can override with `DB_PATH`.

Worker id: service sets worker from env HOSTNAME or POD_NAME; defaults to `worker-1`.

Run locally:
- npm install
- npm run dev
