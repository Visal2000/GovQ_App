import React, { useState, useEffect } from 'react';
import GlassCard from '../components/GlassCard';
import { Play, Check, X, SkipForward, Users, Clock, AlertCircle } from 'lucide-react';
import { db } from '../firebase';
import { doc, setDoc, onSnapshot } from 'firebase/firestore';

const Dashboard = () => {
  const [activeCounter, setActiveCounter] = useState('Counter 1 (Document Submission)');
  const [currentSlot] = useState('10:00 AM - 11:00 AM');
  
  // NIC Multi-Step Counters
  const counters = ['Counter 1 (Document Submission)', 'Counter 4 (Payment)', 'Counter 6 (Collection)'];
  const [servingToken, setServingToken] = useState('Loading...');
  const [nextToken, setNextToken] = useState('Loading...');

  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'queues', 'tv_display'), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        if (data.activeToken?.token) {
          setServingToken(data.activeToken.token);
        }
        if (data.nextTokens && data.nextTokens.length > 0) {
          setNextToken(data.nextTokens[0].token);
        }
      } else {
        // If DB is empty, set defaults
        setServingToken('A-001');
        setNextToken('A-002');
        setDoc(doc(db, 'queues', 'tv_display'), {
          activeToken: {
            token: 'A-001',
            counter: '1',
            stageName: 'Document Submission',
            service: 'New ID - One Day Service',
            timestamp: Date.now()
          },
          nextTokens: [
            { token: 'A-002', counter: '1', stageName: 'Document Submission' },
            { token: 'A-003', counter: '4', stageName: 'Payment' }
          ]
        }).catch(console.error);
      }
    });
    return () => unsub();
  }, []);

  const handleAction = async (action) => {
    console.log(`Action triggered: ${action}`);
    if (action === 'call' || action === 'skip' || action === 'complete' || action === 'next_stage') {
      let currentNum = 1;
      if (nextToken && nextToken.includes('-')) {
        const parsed = parseInt(nextToken.split('-')[1]);
        if (!isNaN(parsed)) currentNum = parsed;
      }
      const nextNum = currentNum + 1;
      const newNextToken = `A-0${nextNum.toString().padStart(2, '0')}`;
      
      const tokenToServe = nextToken.startsWith('A') ? nextToken : 'A-002';

      // We don't need to manually setState because the onSnapshot listener will do it instantly!
      // But we will write to Firebase

      try {
        const stageName = activeCounter.includes('Document') ? 'Document Submission' : 
                          activeCounter.includes('Payment') ? 'Payment' : 'Collection';
                          
        const counterNum = activeCounter.includes('Counter 1') ? '1' : 
                           activeCounter.includes('Counter 4') ? '4' : '6';

        await setDoc(doc(db, 'queues', 'tv_display'), {
          activeToken: {
            token: tokenToServe,
            counter: counterNum,
            stageName: stageName,
            service: 'New ID - One Day Service',
            timestamp: Date.now()
          },
          nextTokens: [
            { token: newNextToken, counter: '1', stageName: 'Document Submission' },
            { token: `A-0${(nextNum + 1).toString().padStart(2, '0')}`, counter: '4', stageName: 'Payment' },
            { token: `A-0${(nextNum + 2).toString().padStart(2, '0')}`, counter: '6', stageName: 'Collection' },
          ]
        });
      } catch (err) {
        console.error("Firebase sync error:", err);
      }
    }
  };

  const isFinalCounter = activeCounter.includes('Collection');

  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h1 className="heading-lg">Queue Management</h1>
          <p className="text-sm">Manage incoming citizens for National Identity Card Renewal</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <select 
            className="input-field" 
            value={activeCounter} 
            onChange={(e) => setActiveCounter(e.target.value)}
            style={{ minWidth: '150px' }}
          >
            {counters.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
        {/* Active Session Info */}
        <GlassCard style={{ padding: '1.5rem', borderLeft: '4px solid var(--color-accent)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem', color: 'var(--color-accent)' }}>
            <Clock size={24} />
            <h3 className="heading-md" style={{ marginBottom: 0 }}>Active Slot</h3>
          </div>
          <p style={{ fontSize: '1.25rem', fontWeight: '600', marginBottom: '0.5rem' }}>{currentSlot}</p>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '1rem' }}>
            <span className="text-sm">Capacity: 45/50 Tokens</span>
            <div style={{ height: '6px', background: 'var(--color-border)', borderRadius: '3px', flex: 1, marginLeft: '1rem', overflow: 'hidden' }}>
              <div style={{ height: '100%', width: '90%', background: 'var(--color-accent)' }}></div>
            </div>
          </div>
        </GlassCard>

        {/* Serving Now */}
        <GlassCard style={{ padding: '1.5rem', borderLeft: '4px solid var(--color-primary)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem', color: 'var(--color-primary)' }}>
            <Users size={24} />
            <h3 className="heading-md" style={{ marginBottom: 0 }}>Serving Now</h3>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '1rem' }}>
            <span style={{ fontSize: '3rem', fontWeight: '700', lineHeight: 1 }}>{servingToken}</span>
            <span className="text-sm">at {activeCounter}</span>
          </div>
          <div style={{ marginTop: '1rem', paddingTop: '1rem', borderTop: '1px solid var(--color-border)' }}>
            <span className="text-sm">Up Next: <strong>{nextToken}</strong></span>
          </div>
        </GlassCard>
      </div>

      <h3 className="heading-md" style={{ marginBottom: '1rem' }}>Counter Actions</h3>
      <GlassCard style={{ padding: '2rem' }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1rem' }}>
          <button className="btn btn-primary" style={{ padding: '1rem 2rem', fontSize: '1.1rem' }} onClick={() => handleAction('call')}>
            <Play size={22} />
            Call Next Token
          </button>
          
          {!isFinalCounter ? (
            <button className="btn btn-success" style={{ padding: '1rem 2rem', fontSize: '1.1rem', backgroundColor: '#10b981' }} onClick={() => handleAction('next_stage')}>
              <Check size={22} />
              Process & Send to Next Stage
            </button>
          ) : (
            <button className="btn btn-success" style={{ padding: '1rem 2rem', fontSize: '1.1rem' }} onClick={() => handleAction('complete')}>
              <Check size={22} />
              Finish & Close Token
            </button>
          )}
          
          <div style={{ width: '1px', background: 'var(--color-border)', margin: '0 0.5rem' }}></div>
          
          <button className="btn btn-secondary" style={{ padding: '1rem 2rem', fontSize: '1.1rem' }} onClick={() => handleAction('skip')}>
            <SkipForward size={22} />
            No-Show (Skip)
          </button>
          
          <button className="btn btn-danger" style={{ padding: '1rem 2rem', fontSize: '1.1rem', marginLeft: 'auto' }} onClick={() => handleAction('cancel')}>
            <X size={22} />
            Cancel Token
          </button>
        </div>
      </GlassCard>
      
      <div style={{ marginTop: '2rem' }}>
         <GlassCard style={{ padding: '1rem 1.5rem', display: 'flex', alignItems: 'center', gap: '1rem', background: 'var(--color-warning-bg)', border: '1px solid rgba(245, 158, 11, 0.3)' }}>
            <AlertCircle size={20} color="var(--color-warning)" />
            <span style={{ color: 'var(--color-text-primary)' }}>Token <strong>A-038</strong> arrived late and is waiting. They will be served after the current sequence.</span>
         </GlassCard>
      </div>
    </div>
  );
};

export default Dashboard;
