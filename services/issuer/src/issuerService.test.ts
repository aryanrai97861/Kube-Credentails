import { IssuerService } from './issuerService';

describe('IssuerService', () => {
  let svc: IssuerService;

  beforeEach(() => {
    process.env.DB_PATH = ':memory:'; // better-sqlite3 supports memory with this path
    svc = new IssuerService();
    svc.clearAll();
  });

  it('should issue a credential and return worker', () => {
    const cred = { name: 'Alice', role: 'admin' };
    const res = svc.issue(cred);
    expect(res).toHaveProperty('id');
    expect(res).toHaveProperty('worker');
    expect(res.message).toMatch(/credential issued by/);
  });

  it('should be idempotent for same credential', () => {
    const cred = { name: 'Bob' };
    const r1 = svc.issue(cred);
    const r2 = svc.issue(cred);
    expect(r2.message).toMatch(/already issued/);
    expect(r2.id).toBe(r1.id);
  });
});
