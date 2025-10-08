import { useState } from 'react'
import axios from 'axios'

export default function IssuePage() {
  const [credentialText, setCredentialText] = useState('{\n  "name": "Alice",\n  "role": "admin"\n}')
  const [result, setResult] = useState<any>(null)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setResult(null)

    try {
      const credential = JSON.parse(credentialText)
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:4001'
      const response = await axios.post(`${apiUrl}/issue`, credential)
      setResult({ success: true, data: response.data })
    } catch (error: any) {
      setResult({ 
        success: false, 
        error: error.response?.data?.error || error.message || 'Failed to issue credential'
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <h2>Issue Credential</h2>
      <form onSubmit={handleSubmit} className="form">
        <div className="form-group">
          <label htmlFor="credential">Credential JSON:</label>
          <textarea
            id="credential"
            value={credentialText}
            onChange={(e) => setCredentialText(e.target.value)}
            placeholder="Enter credential JSON..."
          />
        </div>
        <button type="submit" className="btn" disabled={loading}>
          {loading ? 'Issuing...' : 'Issue Credential'}
        </button>
      </form>

      {result && (
        <div className={`result ${result.success ? 'success' : 'error'}`}>
          {result.success ? (
            <div>
              <h3>Success!</h3>
              <p><strong>Message:</strong> {result.data.message}</p>
              <p><strong>ID:</strong> {result.data.id}</p>
              <p><strong>Worker:</strong> {result.data.worker}</p>
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