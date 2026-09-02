import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import MainDisplay from './components/MainDisplay';
import Sidebar from './components/Sidebar';
import Footer from './components/Footer';
import { db } from './firebase';
import { doc, onSnapshot } from 'firebase/firestore';

function App() {
  // Mock data representing state from Socket.IO
  const [activeToken, setActiveToken] = useState({ token: 'A-045', counter: '1', stageName: 'Document Submission', service: 'New ID - One Day Service', timestamp: Date.now() });
  const [nextTokens, setNextTokens] = useState([
    { token: 'A-046', counter: '1', stageName: 'Document Submission' },
    { token: 'B-012', counter: '4', stageName: 'Payment' },
    { token: 'A-047', counter: '6', stageName: 'Final Collection' },
    { token: 'C-088', counter: '1', stageName: 'Document Submission' },
  ]);

  // Live Firestore Listener
  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'queues', 'tv_display'), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        if (data.activeToken) setActiveToken(data.activeToken);
      }
    }, (error) => {
      console.error("Firebase listen error:", error);
    });

    return () => unsub();
  }, []);

  return (
    <div className="tv-layout">
      <Header />
      <MainDisplay activeToken={activeToken} />
      <Footer message="Welcome to GovQ. Please have your documents ready. Normal operating hours are 9:00 AM to 4:00 PM." />
    </div>
  );
}

export default App;
