import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, BarChart3, LogOut, Settings } from 'lucide-react';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Statistics from './pages/Statistics';

const Sidebar = () => {
  const location = useLocation();
  
  if (location.pathname === '/login') return null;

  return (
    <div className="sidebar" style={{ height: '100vh', position: 'sticky', top: 0 }}>
      <div style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <img src="/logo.png" alt="GovQ Logo" style={{ width: '44px', height: '44px', borderRadius: '4px', objectFit: 'contain', background: 'white', border: '1px solid var(--color-accent)' }} />
        <div>
          <h1 className="heading-md" style={{ marginBottom: 0, color: 'white' }}>GovQ</h1>
          <p className="text-sm" style={{ color: 'rgba(255,255,255,0.8)' }}>Govt. of Sri Lanka</p>
        </div>
      </div>

      <nav style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', flex: 1 }}>
        <Link to="/" style={{ textDecoration: 'none' }}>
          <div className="btn" style={{ width: '100%', justifyContent: 'flex-start', padding: '12px 16px', backgroundColor: location.pathname === '/' ? 'rgba(255,255,255,0.1)' : 'transparent', color: 'white', border: location.pathname === '/' ? '1px solid rgba(255,255,255,0.2)' : '1px solid transparent' }}>
            <LayoutDashboard size={18} />
            Queue Management
          </div>
        </Link>
        <Link to="/statistics" style={{ textDecoration: 'none' }}>
          <div className="btn" style={{ width: '100%', justifyContent: 'flex-start', padding: '12px 16px', backgroundColor: location.pathname === '/statistics' ? 'rgba(255,255,255,0.1)' : 'transparent', color: 'white', border: location.pathname === '/statistics' ? '1px solid rgba(255,255,255,0.2)' : '1px solid transparent' }}>
            <BarChart3 size={18} />
            Statistics
          </div>
        </Link>
      </nav>

      <div style={{ marginTop: 'auto', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
        <div className="btn" style={{ width: '100%', justifyContent: 'flex-start', padding: '12px 16px', color: 'white', backgroundColor: 'transparent' }}>
          <Settings size={18} />
          Settings
        </div>
        <Link to="/login" style={{ textDecoration: 'none' }}>
          <div className="btn" style={{ width: '100%', justifyContent: 'flex-start', padding: '12px 16px', color: '#fca5a5', backgroundColor: 'transparent' }}>
            <LogOut size={18} />
            Logout
          </div>
        </Link>
      </div>
    </div>
  );
};

function App() {
  return (
    <Router>
      <div className="app-container">
        <Sidebar />
        <main className="main-content">
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/" element={<Dashboard />} />
            <Route path="/statistics" element={<Statistics />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
