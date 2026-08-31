import React, { useEffect, useState } from 'react';

const MainDisplay = ({ activeToken }) => {
  const [pulse, setPulse] = useState(false);

  useEffect(() => {
    // Trigger animation
    setPulse(true);
    const timer = setTimeout(() => setPulse(false), 3000);

    // Trigger TTS
    if ('speechSynthesis' in window && activeToken) {
      window.speechSynthesis.cancel(); // Cancel any ongoing speech
      const text = `Token number ${activeToken.token.replace('-', ' ')}, please proceed to Counter ${activeToken.counter}`;
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = 0.85; // Slightly slower for clarity
      utterance.pitch = 1;
      window.speechSynthesis.speak(utterance);
    }

    return () => clearTimeout(timer);
  }, [activeToken.timestamp]);

  return (
    <div className="tv-main">
      <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
        <h2 style={{ fontSize: '2.5rem', color: 'var(--color-text-secondary)', textTransform: 'uppercase', letterSpacing: '2px' }}>
          Currently Serving
        </h2>
      </div>
      
      <div className={pulse ? 'pulse' : ''} style={{ 
        background: 'var(--color-surface)', 
        border: '4px solid var(--color-accent)', 
        borderRadius: '24px', 
        padding: '60px 100px',
        boxShadow: '0 20px 40px rgba(0,0,0,0.15)',
        textAlign: 'center',
        width: '100%',
        maxWidth: '800px',
        position: 'relative',
        overflow: 'hidden'
      }}>
        {/* Subtle background graphic */}
        <div style={{ position: 'absolute', top: '-50px', right: '-50px', opacity: 0.05, transform: 'scale(2)' }}>
          <img src="/logo.png" alt="" width="200" />
        </div>
        
        <h1 style={{ fontSize: '10rem', color: 'var(--color-primary-dark)', margin: 0, lineHeight: 1 }}>
          {activeToken.token}
        </h1>
        <div style={{ marginTop: '2rem', display: 'inline-block', background: 'var(--color-primary)', color: 'white', padding: '15px 40px', borderRadius: '50px' }}>
          <p style={{ fontSize: '2.5rem', margin: 0, fontWeight: 800 }}>
            Counter {activeToken.counter}
          </p>
        </div>
        <p style={{ marginTop: '2rem', fontSize: '1.5rem', color: 'var(--color-text-secondary)', fontWeight: 600 }}>
          {activeToken.service}
        </p>
      </div>
    </div>
  );
};

export default MainDisplay;
