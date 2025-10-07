# Verifier Service

API endpoints:
- POST /verify — accepts credential JSON body. Returns whether valid and, if so, the issuer worker and timestamp.
- GET /health — simple health check.

DB: SQLite (better-sqlite3). Default DB file: `verifier.db`. Override with `DB_PATH`.

Run locally:
- npm install
- npm run dev
