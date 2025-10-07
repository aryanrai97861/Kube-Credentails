import Database from 'better-sqlite3';
import { v4 as uuidv4 } from 'uuid';

const DB_PATH = process.env.DB_PATH || 'issuer.db';

export type Credential = any;

export class IssuerService {
  private db: Database.Database;

  constructor() {
    this.db = new Database(DB_PATH);
    this.init();
  }

  private init() {
    const stmt = `CREATE TABLE IF NOT EXISTS issued (
      id TEXT PRIMARY KEY,
      credential_json TEXT NOT NULL,
      issued_at INTEGER NOT NULL,
      worker TEXT NOT NULL
    )`;
    this.db.prepare(stmt).run();
  }

  issue(credential: Credential) {
    // idempotency key: hash or provided id. We'll use JSON string as key.
    const json = JSON.stringify(credential);
    const existing = this.db.prepare('SELECT id,issued_at,worker FROM issued WHERE credential_json = ?').get(json);
    if (existing) {
      return { message: 'credential already issued', id: existing.id, worker: existing.worker };
    }

    const id = uuidv4();
    const issuedAt = Date.now();
    const worker = process.env.HOSTNAME || process.env.POD_NAME || 'worker-1';
    this.db.prepare('INSERT INTO issued (id, credential_json, issued_at, worker) VALUES (?,?,?,?)')
      .run(id, json, issuedAt, worker);

    return { message: `credential issued by ${worker}`, id, worker };
  }

  // helper for tests
  clearAll() {
    this.db.prepare('DELETE FROM issued').run();
  }
}
