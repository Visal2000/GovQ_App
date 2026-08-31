import React, { useState, useEffect } from 'react';

const Header = () => {
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div className="tv-header">
      <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
        <img src="/logo.png" alt="GovQ" style={{ height: '70px', borderRadius: '8px', background: 'white', padding: '5px', border: '2px solid var(--color-accent)' }} />
        <div>
          <h1 style={{ color: 'var(--color-primary-dark)', fontSize: '2rem', margin: 0 }}>GovQ System</h1>
          <p style={{ color: 'var(--color-text-secondary)', fontSize: '1.2rem', margin: 0, fontWeight: 600 }}>Department of Motor Traffic</p>
        </div>
      </div>
      <div style={{ textAlign: 'right' }}>
        <h2 style={{ fontSize: '3rem', color: 'var(--color-text-primary)', margin: 0, fontWeight: 800 }}>
          {time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
        </h2>
        <p style={{ color: 'var(--color-text-secondary)', fontSize: '1.2rem', margin: 0, fontWeight: 600 }}>
          {time.toLocaleDateString([], { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
        </p>
      </div>
    </div>
  );
};

export default Header;
