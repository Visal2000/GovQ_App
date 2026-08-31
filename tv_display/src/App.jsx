import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import MainDisplay from './components/MainDisplay';
import Sidebar from './components/Sidebar';
import Footer from './components/Footer';

function App() {
  // Mock data representing state from Socket.IO
  const [activeToken, setActiveToken] = useState({ token: 'A-045', counter: 3, service: 'NIC Renewal', timestamp: Date.now() });
  const [nextTokens, setNextTokens] = useState([
    { token: 'A-046', counter: 3 },
    { token: 'B-012', counter: 1 },
    { token: 'A-047', counter: 3 },
    { token: 'C-088', counter: 2 },
  ]);

  // Simulate a new token being called every 15 seconds for testing purposes
  useEffect(() => {
    const interval = setInterval(() => {
      setNextTokens((prev) => {
        if (prev.length === 0) return prev;
        const next = prev[0];
        setActiveToken({ ...next, service: 'General Service', timestamp: Date.now() });
        return prev.slice(1);
      });
    }, 15000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="tv-layout">
      <Header />
      <MainDisplay activeToken={activeToken} />
      <Sidebar tokens={nextTokens} />
      <Footer message="Welcome to GovQ. Please have your documents ready. Normal operating hours are 9:00 AM to 4:00 PM." />
    </div>
  );
}

export default App;
