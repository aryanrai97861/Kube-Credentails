import Database from 'better-sqlite3';

const DB_PATH = process.env.DB_PATH || '../../shared/credentials.db';

export class VerifierService {
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

  verify(credential: any) {
    const json = JSON.stringify(credential);
    const row = this.db.prepare('SELECT id,issued_at,worker FROM issued WHERE credential_json = ?').get(json);
    if (row) {
      return { valid: true, id: row.id, worker: row.worker, issued_at: row.issued_at };
    }
    return { valid: false };
  }

  // helper for tests
  insertIssued(id: string, credential: any, worker = 'worker-1') {
    const json = JSON.stringify(credential);
    this.db.prepare('INSERT OR REPLACE INTO issued (id, credential_json, issued_at, worker) VALUES (?,?,?,?)')
      .run(id, json, Date.now(), worker);
  }
}
