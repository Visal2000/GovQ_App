import React from 'react';

const Sidebar = ({ tokens }) => {
  return (
    <div className="tv-sidebar">
      <h2 style={{ fontSize: '2.5rem', color: 'var(--color-primary-dark)', marginBottom: '30px', borderBottom: '3px solid var(--color-accent)', paddingBottom: '15px' }}>
        Up Next
      </h2>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
        {tokens.map((t, idx) => (
          <div key={idx} style={{ 
            background: 'white', 
            padding: '25px', 
            borderRadius: '16px', 
            border: '2px solid var(--color-border)',
            display: 'flex', 
            justifyContent: 'space-between',
            alignItems: 'center',
            boxShadow: '0 4px 6px rgba(0,0,0,0.05)'
          }}>
            <span style={{ fontSize: '3.5rem', fontWeight: 800, color: 'var(--color-text-primary)' }}>
              {t.token}
            </span>
            <div style={{ textAlign: 'right' }}>
              <span style={{ fontSize: '1.2rem', color: 'var(--color-text-secondary)', textTransform: 'uppercase', fontWeight: 600, display: 'block' }}>Counter</span>
              <span style={{ fontSize: '2.5rem', fontWeight: 800, color: 'var(--color-primary)' }}>{t.counter}</span>
            </div>
          </div>
        ))}
        {tokens.length === 0 && (
          <div style={{ textAlign: 'center', padding: '40px', color: 'var(--color-text-secondary)' }}>
            <p style={{ fontSize: '1.5rem' }}>No more tokens waiting.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Sidebar;
