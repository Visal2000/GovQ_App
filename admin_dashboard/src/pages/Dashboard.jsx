import React, { useState, useEffect } from 'react';
import GlassCard from '../components/GlassCard';
import { Play, Check, X, SkipForward, Users, Clock, AlertCircle, AlertTriangle } from 'lucide-react';
import { db } from '../firebase';
import { doc, setDoc, onSnapshot, collection, query, where, orderBy, updateDoc, getDocs } from 'firebase/firestore';

const Dashboard = () => {
  const [activeCounter, setActiveCounter] = useState('Counter 1 (Document Submission)');
  const [userRole, setUserRole] = useState(null);

  useEffect(() => {
    const userStr = localStorage.getItem('govq_user');
    if (userStr) {
      const user = JSON.parse(userStr);
      setUserRole(user.role);
      if (user.role === 'counter' && user.counter) {
        setActiveCounter(user.counter);
      }
    } else {
      window.location.href = '/login';
    }
  }, []);
  
  const getCurrentSlot = () => {
    const hour = new Date().getHours();
    if (hour < 10) return '09:00 AM - 10:00 AM';
    if (hour === 10) return '10:00 AM - 11:00 AM';
    if (hour === 11) return '11:00 AM - 12:00 PM';
    if (hour === 12) return '12:00 PM - 01:00 PM';
    if (hour === 13) return '01:00 PM - 02:00 PM';
    if (hour === 14) return '02:00 PM - 03:00 PM';
    if (hour === 15) return '03:00 PM - 04:00 PM';
    if (hour === 16) return '04:00 PM - 05:00 PM';
    if (hour === 17) return '05:00 PM - 06:00 PM';
    return '06:00 PM - 07:00 PM';
  };

  const [currentSlot, setCurrentSlot] = useState(getCurrentSlot());

  const allSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '01:00 PM - 02:00 PM',
    '02:00 PM - 03:00 PM',
    '03:00 PM - 04:00 PM',
    '04:00 PM - 05:00 PM',
    '05:00 PM - 06:00 PM',
    '06:00 PM - 07:00 PM'
  ];
  
  // Single Counter Mode
  const counters = ['Counter 1 (Document Submission)'];
  const [servingToken, setServingToken] = useState('--');
  const [nextToken, setNextToken] = useState('--');
  const [waitingTokens, setWaitingTokens] = useState([]);
  const [activeSession, setActiveSession] = useState(null);
  const [lateTokenInput, setLateTokenInput] = useState('');
  const [lateTokensMsg, setLateTokensMsg] = useState([]);
  const [pendingLateTokens, setPendingLateTokens] = useState([]);
  
  // Delay Broadcast State
  const [delayMinutes, setDelayMinutes] = useState('30');
  const [isDelayActive, setIsDelayActive] = useState(false);

  // Listen to current delay status
  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'queues', 'metadata'), (docSnap) => {
      if (docSnap.exists()) {
        setIsDelayActive(docSnap.data().delayActive || false);
        if (docSnap.data().delayMinutes) {
          setDelayMinutes(docSnap.data().delayMinutes.toString());
        }
      }
    });
    return () => unsub();
  }, []);

  useEffect(() => {
    const stageName = 'Document Submission';

    // Remove orderBy to avoid Firestore composite index requirement. Sort manually in JS.
    const q = query(collection(db, 'tokens'), where('status', '==', 'waiting'));
    const unsub = onSnapshot(q, (snapshot) => {
      let tokens = snapshot.docs
        .map(d => ({ id: d.id, ...d.data() }))
        .filter(t => t.stageName === stageName);

      // Important: For the very first stage, ONLY show tokens that belong to the current active hour slot.
      // For later stages (Payment, Collection), show everyone because they are already inside the building progressing.
      if (stageName === 'Document Submission') {
        tokens = tokens.filter(t => t.slot && t.slot.startsWith(currentSlot));
      }
        
      // Sort by timestamp manually (handle null timestamps which occur during serverTimestamp resolution)
      tokens.sort((a, b) => {
        const timeA = a.timestamp ? (a.timestamp.toMillis ? a.timestamp.toMillis() : a.timestamp) : 0;
        const timeB = b.timestamp ? (b.timestamp.toMillis ? b.timestamp.toMillis() : b.timestamp) : 0;
        return timeA - timeB;
      });
        
      setWaitingTokens(tokens);
      if (tokens.length > 0) {
        setNextToken(tokens[0].token);
      } else {
        setNextToken('--');
      }
    }, (error) => {
      console.error("Firestore Error in waitingTokens query: ", error);
    });

    // Listen for late arrivals pending approval
    const qLate = query(collection(db, 'tokens'), where('status', '==', 'late_arrival_pending'));
    const unsubLate = onSnapshot(qLate, (snapshot) => {
      let lateList = snapshot.docs
        .map(d => ({ id: d.id, ...d.data() }))
        .filter(t => t.stageName === stageName);
      
      // Filter by the current slot so counter only sees late arrivals for their active hour
      if (stageName === 'Document Submission') {
        lateList = lateList.filter(t => t.slot && t.slot.startsWith(currentSlot));
      }
      setPendingLateTokens(lateList);
    });

    return () => { unsub(); unsubLate(); };
  }, [activeCounter, currentSlot]);

  // Keep TV Display's "Up Next" live-synced with our waiting tokens
  useEffect(() => {
    const syncUpcoming = async () => {
      const upcoming = waitingTokens.slice(0, 5).map(t => ({
        token: t.token,
        counter: '1',
        stageName: 'Document Submission'
      }));
      try {
        await updateDoc(doc(db, 'queues', 'tv_display'), {
          nextTokens: upcoming
        });
      } catch(e) {
        // Document might not exist yet, ignore
      }
    };
    syncUpcoming();
  }, [waitingTokens]);

  useEffect(() => {
    const counterNum = activeCounter.includes('Counter 1') ? '1' : 
                       activeCounter.includes('Counter 4') ? '4' : '6';

    const qServing = query(collection(db, 'tokens'), where('status', '==', 'serving'));

    const unsubServing = onSnapshot(qServing, (snapshot) => {
      const active = snapshot.docs
        .map(d => ({ id: d.id, ...d.data() }))
        .find(t => t.counter === counterNum);
      
      if (active) {
        setActiveSession(active);
        setServingToken(active.token);
      } else {
        setActiveSession(null);
        setServingToken('--');
      }
    });

    return () => unsubServing();
  }, [activeCounter]);

  const handleAction = async (action) => {
    if (action === 'call') {
      if (waitingTokens.length === 0) return;
      const nextToServe = waitingTokens[0];
      
      const stageName = 'Document Submission';
      const counterNum = '1';

      try {
        await updateDoc(doc(db, 'tokens', nextToServe.id), { status: 'serving', counter: counterNum, stageName: stageName });

        const upcoming = waitingTokens.slice(1, 5).map(t => ({
          token: t.token,
          counter: counterNum,
          stageName: stageName
        }));

        await setDoc(doc(db, 'queues', 'tv_display'), {
          activeToken: {
            token: nextToServe.token,
            counter: counterNum,
            stageName: stageName,
            service: nextToServe.service || 'New ID - One Day Service',
            timestamp: Date.now()
          },
          nextTokens: upcoming
        });
      } catch (err) {
        console.error("Firebase sync error:", err);
      }
    } else if (action === 'complete') {
      if (!activeSession) return;
      try {
        await updateDoc(doc(db, 'tokens', activeSession.id), { status: 'completed' });
        await setDoc(doc(db, 'queues', 'tv_display'), { activeToken: null }, { merge: true });
      } catch (err) { console.error(err); }
    } else if (action === 'skip' || action === 'cancel') {
      if (!activeSession) return;
      try {
        await updateDoc(doc(db, 'tokens', activeSession.id), { status: action === 'skip' ? 'skipped' : 'cancelled' });
        await setDoc(doc(db, 'queues', 'tv_display'), { activeToken: null }, { merge: true });
      } catch (err) { console.error(err); }
    }
  };

  const handleLateArrival = async () => {
    if (!lateTokenInput.trim()) return;
    
    try {
      const q = query(collection(db, 'tokens'), where('token', '==', lateTokenInput.trim().toUpperCase()));
      const snap = await getDocs(q); 
      
      if (snap.empty) {
        setLateTokensMsg(prev => [...prev, `Error: Token ${lateTokenInput} not found in database.`]);
        return;
      }

      const docRef = snap.docs[0];
      const stageName = activeCounter.includes('Document') ? 'Document Submission' : 
                        activeCounter.includes('Payment') ? 'Payment' : 'Collection';

      // Reactivate token and place at the end of the line
      await updateDoc(doc(db, 'tokens', docRef.id), { 
        status: 'waiting',
        stageName: stageName,
        timestamp: Date.now() // This moves them to the end of the orderBy('timestamp', 'asc') query
      });

      setLateTokensMsg(prev => [...prev, `Success: Token ${docRef.data().token} has been added to the end of the ${stageName} queue.`]);
      setLateTokenInput('');
      
    } catch (err) {
      console.error(err);
      setLateTokensMsg(prev => [...prev, `Error: Could not process late arrival.`]);
    }
  };

  const acceptPendingLateArrival = async (tokenDoc) => {
    try {
      await updateDoc(doc(db, 'tokens', tokenDoc.id), { 
        status: 'waiting',
        timestamp: Date.now() // This moves them to the end of the orderBy('timestamp', 'asc') queue for their slot
      });
      alert(`Token ${tokenDoc.token} accepted and added to the queue.`);
    } catch (err) {
      console.error(err);
      alert('Error accepting late arrival.');
    }
  };

  const handleBroadcastDelay = async (active) => {
    try {
      await setDoc(doc(db, 'queues', 'metadata'), {
        delayActive: active,
        delayMinutes: active ? parseInt(delayMinutes) : 0,
        updatedAt: Date.now()
      }, { merge: true });
      alert(active ? `Delay broadcasted successfully.` : `Delay broadcast turned off.`);
    } catch (error) {
      console.error("Error broadcasting delay:", error);
      alert("Error broadcasting delay.");
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
            disabled={userRole === 'counter'}
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
          <select 
            className="input-field"
            value={currentSlot}
            onChange={(e) => setCurrentSlot(e.target.value)}
            style={{ fontSize: '1.25rem', fontWeight: '600', marginBottom: '0.5rem', width: '100%', padding: '0.5rem', appearance: 'auto' }}
          >
            {allSlots.map(slot => (
              <option key={slot} value={slot}>{slot}</option>
            ))}
          </select>
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
          
          <button className="btn btn-success" style={{ padding: '1rem 2rem', fontSize: '1.1rem' }} onClick={() => handleAction('complete')}>
            <Check size={22} />
            Finish & Close Token
          </button>
          
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

      {/* Delay Broadcast Section */}
      <div style={{ marginTop: '2rem' }}>
        <h3 className="heading-md" style={{ marginBottom: '1rem', color: 'var(--color-danger)' }}>
          <AlertCircle size={20} style={{ display: 'inline', marginRight: '8px', verticalAlign: 'middle' }} />
          System Delay Broadcast
        </h3>
        <GlassCard style={{ padding: '2rem', border: '1px solid var(--color-danger)' }}>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'flex-end', flexWrap: 'wrap' }}>
            <div className="input-group" style={{ flex: 1, minWidth: '200px', marginBottom: 0 }}>
              <label className="input-label">Estimated Delay (Minutes)</label>
              <select 
                className="input-field" 
                value={delayMinutes} 
                onChange={(e) => setDelayMinutes(e.target.value)}
                disabled={isDelayActive}
              >
                <option value="15">15 Minutes</option>
                <option value="30">30 Minutes</option>
                <option value="45">45 Minutes</option>
                <option value="60">60 Minutes (1 Hour)</option>
                <option value="120">120 Minutes (2 Hours)</option>
              </select>
            </div>
            
            {!isDelayActive ? (
              <button className="btn btn-danger" style={{ padding: '0.8rem 2rem' }} onClick={() => handleBroadcastDelay(true)}>
                Broadcast Delay to Citizens
              </button>
            ) : (
              <button className="btn btn-secondary" style={{ padding: '0.8rem 2rem' }} onClick={() => handleBroadcastDelay(false)}>
                Turn Off Delay Broadcast
              </button>
            )}
          </div>
          {isDelayActive && (
            <div style={{ marginTop: '1rem', padding: '1rem', backgroundColor: 'var(--color-danger)', color: 'white', borderRadius: '8px', opacity: 0.9 }}>
              <strong>Status:</strong> Citizens are currently seeing a {delayMinutes}-minute delay warning on their apps.
            </div>
          )}
        </GlassCard>
      </div>
      
      <div style={{ marginTop: '2rem' }}>
        {waitingTokens.length === 0 && !activeSession ? (
          <GlassCard style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem', background: '#dcfce7', border: '1px solid #86efac' }}>
            <Check size={28} color="#166534" />
            <span style={{ color: '#166534', fontSize: '1.2rem', fontWeight: 600 }}>All tokens for this stage in the {currentSlot} slot are finished!</span>
          </GlassCard>
        ) : null}

        {pendingLateTokens.length > 0 && (
          <GlassCard style={{ padding: '1.5rem', marginTop: '1rem', border: '2px solid var(--color-warning)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1rem', color: 'var(--color-warning)' }}>
              <AlertTriangle size={24} />
              <h4 style={{ fontSize: '1.1rem', fontWeight: 600, margin: 0 }}>Late Arrivals Pending Approval ({pendingLateTokens.length})</h4>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {pendingLateTokens.map(pt => (
                <div key={pt.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'white', padding: '1rem', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
                  <div>
                    <div style={{ fontWeight: 'bold', fontSize: '1.2rem', color: 'var(--color-text-dark)' }}>{pt.token}</div>
                    <div className="text-sm" style={{ color: 'var(--color-text-light)' }}>{pt.service}</div>
                  </div>
                  <button className="btn btn-primary" onClick={() => acceptPendingLateArrival(pt)}>
                    Accept (Add to Queue)
                  </button>
                </div>
              ))}
            </div>
          </GlassCard>
        )}

        <GlassCard style={{ padding: '1.5rem', marginTop: '1rem' }}>
          <h4 style={{ marginBottom: '1rem', fontSize: '1.1rem', fontWeight: 600 }}>Manual Late Arrivals Handling</h4>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
            <input 
              type="text" 
              className="input-field" 
              placeholder="Enter missed token (e.g. A-005)" 
              value={lateTokenInput}
              onChange={(e) => setLateTokenInput(e.target.value)}
              style={{ maxWidth: '250px' }}
            />
            <button className="btn btn-secondary" onClick={handleLateArrival}>
              Accept Late Arrival
            </button>
          </div>
          {lateTokensMsg.length > 0 && (
             <div style={{ marginTop: '1rem', padding: '1rem', background: 'var(--color-warning-bg)', border: '1px solid rgba(245, 158, 11, 0.3)', borderRadius: '8px', display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
               <AlertCircle size={20} color="var(--color-warning)" />
               <span>{lateTokensMsg[lateTokensMsg.length - 1]}</span>
             </div>
          )}
        </GlassCard>
      </div>
    </div>
  );
};

export default Dashboard;
