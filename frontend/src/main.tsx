import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter as Router, Routes, Route, NavLink } from 'react-router-dom'
import IssuePage from './pages/IssuePage'
import VerifyPage from './pages/VerifyPage'
import './App.css'

function App() {
  return (
    <Router>
      <div className="app">
        <nav className="nav">
          <h1>Kube Credentials</h1>
          <div className="nav-links">
            <NavLink to="/issue" className={({ isActive }) => isActive ? 'active' : ''}>
              Issue Credential
            </NavLink>
            <NavLink to="/verify" className={({ isActive }) => isActive ? 'active' : ''}>
              Verify Credential
            </NavLink>
          </div>
        </nav>
        <main className="main">
          <Routes>
            <Route path="/" element={<IssuePage />} />
            <Route path="/issue" element={<IssuePage />} />
            <Route path="/verify" element={<VerifyPage />} />
          </Routes>
        </main>
      </div>
    </Router>
  )
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>
)