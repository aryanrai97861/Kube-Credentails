import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import { VerifierService } from './verifierService';

const app = express();
const port = process.env.PORT ? parseInt(process.env.PORT) : 4002;
app.use(cors());
app.use(bodyParser.json());

const verifier = new VerifierService();

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

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.listen(port, () => {
  console.log(`Verifier service listening on port ${port}`);
});
