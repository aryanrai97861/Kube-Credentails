import { VerifierService } from './verifierService';

describe('VerifierService', () => {
  let svc: VerifierService;

  beforeEach(() => {
    process.env.DB_PATH = ':memory:';
    svc = new VerifierService();
  });

  it('should return invalid for unknown credential', () => {
    const res = svc.verify({ foo: 'bar' });
    expect(res.valid).toBe(false);
  });

  it('should verify inserted credential', () => {
    const cred = { email: 'x@example.com' };
    svc.insertIssued('id-1', cred, 'worker-2');
    const res = svc.verify(cred);
    expect(res.valid).toBe(true);
    expect(res.worker).toBe('worker-2');
  });
});
