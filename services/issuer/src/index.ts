import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import { IssuerService } from './issuerService';

const app = express();
const port = process.env.PORT ? parseInt(process.env.PORT) : 4001;

app.use(cors());
app.use(bodyParser.json());

const issuer = new IssuerService();

app.post('/issue', async (req, res) => {
  try {
    const credential = req.body;
    if (!credential) return res.status(400).json({ error: 'credential JSON required' });
    const result = issuer.issue(credential);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Endpoint for verifier to fetch all credentials
app.get('/credentials', (req, res) => {
  try {
    const credentials = issuer.getAllCredentials();
    res.json({ credentials });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.listen(port, () => {
  console.log(`Issuer service listening on port ${port}`);
});
