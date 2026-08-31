import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import GlassCard from '../components/GlassCard';
import { LogIn } from 'lucide-react';

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate();

  const handleLogin = (e) => {
    e.preventDefault();
    // Placeholder login logic
    if (username && password) {
      navigate('/');
    }
  };

  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh', width: '100%', position: 'absolute', top: 0, left: 0 }}>
      <GlassCard className="animate-fade-in" style={{ width: '100%', maxWidth: '420px', padding: '2.5rem' }}>
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <img src="/logo.png" alt="GovQ Logo" style={{ width: '72px', height: '72px', borderRadius: '12px', objectFit: 'contain', background: 'white', margin: '0 auto 1rem', display: 'block', border: '2px solid var(--color-accent)', boxShadow: 'var(--shadow-md)' }} />
          <h2 className="heading-lg text-gradient">GovQ Staff Portal</h2>
          <p className="text-sm">Sign in to manage queues and services</p>
        </div>

        <form onSubmit={handleLogin}>
          <div className="input-group">
            <label className="input-label" htmlFor="username">Username / Staff ID</label>
            <input 
              type="text" 
              id="username" 
              className="input-field" 
              placeholder="e.g., admin.colombo"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
            />
          </div>
          <div className="input-group" style={{ marginBottom: '2rem' }}>
            <label className="input-label" htmlFor="password">Password</label>
            <input 
              type="password" 
              id="password" 
              className="input-field" 
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <button type="submit" className="btn btn-primary" style={{ width: '100%', padding: '12px', fontSize: '1rem' }}>
            <LogIn size={20} />
            Sign In
          </button>
        </form>
      </GlassCard>
    </div>
  );
};

export default Login;
