import { useState } from 'react'
import axios from 'axios'

export default function VerifyPage() {
  const [credentialText, setCredentialText] = useState('{\n  "name": "Alice",\n  "role": "admin"\n}')
  const [result, setResult] = useState<any>(null)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setResult(null)

    try {
      const credential = JSON.parse(credentialText)
      const response = await axios.post('http://localhost:4002/verify', credential)
      setResult({ success: true, data: response.data })
    } catch (error: any) {
      setResult({ 
        success: false, 
        error: error.response?.data?.error || error.message || 'Failed to verify credential'
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <h2>Verify Credential</h2>
      <form onSubmit={handleSubmit} className="form">
        <div className="form-group">
          <label htmlFor="credential">Credential JSON:</label>
          <textarea
            id="credential"
            value={credentialText}
            onChange={(e) => setCredentialText(e.target.value)}
            placeholder="Enter credential JSON to verify..."
          />
        </div>
        <button type="submit" className="btn" disabled={loading}>
          {loading ? 'Verifying...' : 'Verify Credential'}
        </button>
      </form>

      {result && (
        <div className={`result ${result.success ? 'success' : 'error'}`}>
          {result.success ? (
            <div>
              <h3>Verification Result</h3>
              {result.data.valid ? (
                <div>
                  <p><strong>Status:</strong> Valid ✓</p>
                  <p><strong>ID:</strong> {result.data.id}</p>
                  <p><strong>Issued by:</strong> {result.data.worker}</p>
                  <p><strong>Issued at:</strong> {new Date(result.data.issued_at).toLocaleString()}</p>
                </div>
              ) : (
                <p><strong>Status:</strong> Invalid ✗</p>
              )}
            </div>
          ) : (
            <div>
              <h3>Error</h3>
              <p>{result.error}</p>
            </div>
          )}
        </div>
      )}
    </div>
  )
}