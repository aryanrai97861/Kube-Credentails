import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import axios from 'axios';
import { VerifierService } from './verifierService';

const app = express();
const port = process.env.PORT ? parseInt(process.env.PORT) : 4002;
const ISSUER_URL = process.env.ISSUER_SERVICE_URL || 'http://localhost:3001';

app.use(cors());
app.use(bodyParser.json());

const verifier = new VerifierService();

// Sync credentials from issuer service
async function syncFromIssuer() {
  try {
    console.log(`Syncing credentials from issuer: ${ISSUER_URL}`);
    const response = await axios.get(`${ISSUER_URL}/credentials`);
    const { credentials } = response.data;
    
    for (const cred of credentials) {
      verifier.syncCredential(cred.id, cred.credential, cred.issued_at, cred.worker);
    }
    
    console.log(`Synced ${credentials.length} credentials from issuer`);
  } catch (error: any) {
    console.error('Failed to sync from issuer:', error.message);
  }
}

// Sync on startup
syncFromIssuer();

// Sync every 30 seconds
setInterval(syncFromIssuer, 30000);

app.post('/verify', (req, res) => {
  try {
    const credential = req.body;
    if (!credential) return res.status(400).json({ error: 'credential JSON required' });
    const result = verifier.verify(credential);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Manual sync endpoint
app.post('/sync', async (req, res) => {
  try {
    await syncFromIssuer();
    res.json({ message: 'Sync completed successfully' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.listen(port, () => {
  console.log(`Verifier service listening on port ${port}`);
});
