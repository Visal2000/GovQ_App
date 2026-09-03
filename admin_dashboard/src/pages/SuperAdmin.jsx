import React, { useState, useEffect } from 'react';
import GlassCard from '../components/GlassCard';
import { db } from '../firebase';
import { collection, onSnapshot, deleteDoc, doc, setDoc, deleteField } from 'firebase/firestore';
import { Trash2, User, UserPlus, Settings, Shield, Calendar } from 'lucide-react';

const SuperAdmin = () => {
  const [users, setUsers] = useState([]);
  const [staff, setStaff] = useState([]);
  const [holidays, setHolidays] = useState([]);
  const [activeTab, setActiveTab] = useState('users'); // 'users', 'staff', 'appeals', 'holidays'
  
  const [newHolidayDate, setNewHolidayDate] = useState('');
  const [newHolidayReason, setNewHolidayReason] = useState('');
  
  // New Staff Form
  const [newStaffUsername, setNewStaffUsername] = useState('');
  const [newStaffPassword, setNewStaffPassword] = useState('');
  const [newStaffRole, setNewStaffRole] = useState('counter');
  const [newStaffCounter, setNewStaffCounter] = useState('Counter 1 (Document Submission)');

  useEffect(() => {
    const unsubUsers = onSnapshot(collection(db, 'users'), (snap) => {
      setUsers(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    const unsubStaff = onSnapshot(collection(db, 'staff'), (snap) => {
      setStaff(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    const unsubHolidays = onSnapshot(collection(db, 'holidays'), (snap) => {
      setHolidays(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    return () => { unsubUsers(); unsubStaff(); unsubHolidays(); };
  }, []);

  const handleDeleteUser = async (id) => {
    if (window.confirm('Are you sure you want to terminate this user account?')) {
      await deleteDoc(doc(db, 'users', id));
    }
  };

  const handleDeleteStaff = async (id) => {
    if (window.confirm('Are you sure you want to delete this staff login?')) {
      await deleteDoc(doc(db, 'staff', id));
    }
  };

  const handleAddHoliday = async (e) => {
    e.preventDefault();
    if (!newHolidayDate) return;
    
    await setDoc(doc(db, 'holidays', newHolidayDate), {
      reason: newHolidayReason || 'Public Holiday',
      createdAt: Date.now()
    });
    
    setNewHolidayDate('');
    setNewHolidayReason('');
    alert('Holiday added successfully!');
  };

  const handleDeleteHoliday = async (date) => {
    if (window.confirm('Are you sure you want to remove this holiday?')) {
      await deleteDoc(doc(db, 'holidays', date));
    }
  };

  const handleAppealDecision = async (nic, decision) => {
    try {
      if (decision === 'accepted') {
        await setDoc(doc(db, 'users', nic), {
          appealStatus: 'accepted',
          blockedUntil: deleteField()
        }, { merge: true });
      } else {
        await setDoc(doc(db, 'users', nic), {
          appealStatus: 'rejected'
        }, { merge: true });
      }
    } catch(e) {
      console.error("Error updating appeal: ", e);
    }
  };

  const handleCreateStaff = async (e) => {
    e.preventDefault();
    if (!newStaffUsername || !newStaffPassword) return;
    
    await setDoc(doc(db, 'staff', newStaffUsername), {
      username: newStaffUsername,
      password: newStaffPassword,
      role: newStaffRole,
      counter: newStaffRole === 'counter' ? newStaffCounter : null,
      createdAt: Date.now()
    });
    
    setNewStaffUsername('');
    setNewStaffPassword('');
    alert('Staff account created successfully!');
  };

  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h1 className="heading-lg">Super Admin Dashboard</h1>
          <p className="text-sm">Manage Citizens and Counter Logins</p>
        </div>
      </div>

      <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem' }}>
        <button 
          className={`btn ${activeTab === 'users' ? 'btn-primary' : 'btn-secondary'}`} 
          onClick={() => setActiveTab('users')}
        >
          <User size={18} /> Registered Citizens
        </button>
        <button 
          className={`btn ${activeTab === 'staff' ? 'btn-primary' : 'btn-secondary'}`} 
          onClick={() => setActiveTab('staff')}
        >
          <Shield size={18} /> Staff Logins
        </button>
        <button 
          className={`btn ${activeTab === 'appeals' ? 'btn-primary' : 'btn-secondary'}`} 
          onClick={() => setActiveTab('appeals')}
        >
          <Shield size={18} /> Ban Appeals
        </button>
        <button 
          className={`btn ${activeTab === 'holidays' ? 'btn-primary' : 'btn-secondary'}`} 
          onClick={() => setActiveTab('holidays')}
        >
          <Calendar size={18} /> Holidays
        </button>
      </div>

      {activeTab === 'users' && (
        <GlassCard style={{ padding: '2rem' }}>
          <h2 className="heading-md" style={{ marginBottom: '1.5rem' }}>Registered Citizens ({users.length})</h2>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--color-border)' }}>
                  <th style={{ padding: '1rem' }}>NIC</th>
                  <th style={{ padding: '1rem' }}>Name</th>
                  <th style={{ padding: '1rem' }}>Phone</th>
                  <th style={{ padding: '1rem' }}>Email</th>
                  <th style={{ padding: '1rem' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map(user => (
                  <tr key={user.id} style={{ borderBottom: '1px solid var(--color-border)' }}>
                    <td style={{ padding: '1rem', fontWeight: 'bold' }}>{user.id}</td>
                    <td style={{ padding: '1rem' }}>{user.name}</td>
                    <td style={{ padding: '1rem' }}>{user.phone}</td>
                    <td style={{ padding: '1rem' }}>{user.email}</td>
                    <td style={{ padding: '1rem' }}>
                      <button className="btn btn-danger" style={{ padding: '0.5rem 1rem' }} onClick={() => handleDeleteUser(user.id)}>
                        <Trash2 size={16} /> Terminate
                      </button>
                    </td>
                  </tr>
                ))}
                {users.length === 0 && (
                  <tr>
                    <td colSpan="5" style={{ padding: '2rem', textAlign: 'center' }}>No citizens registered yet.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </GlassCard>
      )}

      {activeTab === 'staff' && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
          <GlassCard style={{ padding: '2rem' }}>
            <h2 className="heading-md" style={{ marginBottom: '1.5rem' }}>Create Staff Login</h2>
            <form onSubmit={handleCreateStaff}>
              <div className="input-group">
                <label className="input-label">Username</label>
                <input type="text" className="input-field" value={newStaffUsername} onChange={e => setNewStaffUsername(e.target.value)} required />
              </div>
              <div className="input-group">
                <label className="input-label">Password</label>
                <input type="password" className="input-field" value={newStaffPassword} onChange={e => setNewStaffPassword(e.target.value)} required />
              </div>
              <div className="input-group">
                <label className="input-label">Role</label>
                <select className="input-field" value={newStaffRole} onChange={e => setNewStaffRole(e.target.value)}>
                  <option value="counter">Counter Officer</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              {newStaffRole === 'counter' && (
                <div className="input-group">
                  <label className="input-label">Assigned Counter</label>
                  <select className="input-field" value={newStaffCounter} onChange={e => setNewStaffCounter(e.target.value)}>
                    <option value="Counter 1 (Document Submission)">Counter 1 (Document Submission)</option>
                  </select>
                </div>
              )}
              <button type="submit" className="btn btn-primary" style={{ width: '100%', marginTop: '1rem' }}>
                <UserPlus size={18} /> Create Account
              </button>
            </form>
          </GlassCard>

          <GlassCard style={{ padding: '2rem' }}>
            <h2 className="heading-md" style={{ marginBottom: '1.5rem' }}>Active Staff Logins</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '1rem', background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: '8px' }}>
                <div>
                  <strong>admin</strong> <span className="text-sm">(Default Super Admin)</span>
                </div>
                <Shield size={18} color="var(--color-primary)" />
              </div>
              
              {staff.map(s => (
                <div key={s.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: '8px' }}>
                  <div>
                    <div style={{ fontWeight: 'bold' }}>{s.username} <span style={{ fontWeight: 'normal', color: 'var(--color-text-secondary)', fontSize: '0.9rem' }}>({s.role})</span></div>
                    {s.role === 'counter' && <div className="text-sm">{s.counter}</div>}
                  </div>
                  <button className="btn btn-danger" style={{ padding: '0.5rem' }} onClick={() => handleDeleteStaff(s.id)}>
                    <Trash2 size={16} />
                  </button>
                </div>
              ))}
            </div>
          </GlassCard>
        </div>
      )}

      {activeTab === 'appeals' && (
        <GlassCard style={{ padding: '2rem' }}>
          <h2 className="heading-md" style={{ marginBottom: '1.5rem', color: 'var(--color-warning)' }}>Pending 7-Day Ban Appeals</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {users.filter(u => u.appealStatus === 'pending').map(appeal => (
              <div key={appeal.id} style={{ padding: '1rem', background: 'white', borderRadius: '8px', border: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontWeight: 600, color: 'var(--color-text-dark)', marginBottom: '0.25rem' }}>NIC: {appeal.id} | Name: {appeal.name} | Phone: {appeal.phone}</div>
                  <div style={{ color: 'var(--color-text-light)', fontSize: '0.9rem' }}>
                    <span style={{ fontWeight: 500 }}>Reason:</span> {appeal.appealReason || 'No reason provided'}
                  </div>
                </div>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <button 
                    className="btn" 
                    style={{ background: '#ef4444', color: 'white', padding: '0.5rem 1rem' }}
                    onClick={() => handleAppealDecision(appeal.id, 'rejected')}
                  >
                    Reject
                  </button>
                  <button 
                    className="btn" 
                    style={{ background: '#22c55e', color: 'white', padding: '0.5rem 1rem' }}
                    onClick={() => handleAppealDecision(appeal.id, 'accepted')}
                  >
                    Accept (Unban)
                  </button>
                </div>
              </div>
            ))}
            {users.filter(u => u.appealStatus === 'pending').length === 0 && (
              <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--color-text-light)' }}>
                No pending appeals at the moment.
              </div>
            )}
          </div>
        </GlassCard>
      )}

      {activeTab === 'holidays' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '2rem' }}>
          <GlassCard style={{ padding: '2rem' }}>
            <h2 className="heading-md" style={{ marginBottom: '1.5rem' }}>Mark New Holiday</h2>
            <form onSubmit={handleAddHoliday}>
              <div className="input-group">
                <label className="input-label">Select Date</label>
                <input 
                  type="date" 
                  className="input-field" 
                  required
                  value={newHolidayDate}
                  onChange={(e) => setNewHolidayDate(e.target.value)}
                />
              </div>
              <div className="input-group">
                <label className="input-label">Reason (e.g. Public Holiday)</label>
                <input 
                  type="text" 
                  className="input-field" 
                  placeholder="Optional reason"
                  value={newHolidayReason}
                  onChange={(e) => setNewHolidayReason(e.target.value)}
                />
              </div>
              <button type="submit" className="btn btn-primary" style={{ width: '100%', marginTop: '1rem' }}>
                <Calendar size={18} /> Mark Holiday
              </button>
            </form>
          </GlassCard>

          <GlassCard style={{ padding: '2rem' }}>
            <h2 className="heading-md" style={{ marginBottom: '1.5rem' }}>Upcoming Holidays</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {holidays.sort((a,b) => a.id.localeCompare(b.id)).map(h => (
                <div key={h.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', background: 'var(--color-surface)', border: '1px solid var(--color-border)', borderRadius: '8px' }}>
                  <div>
                    <div style={{ fontWeight: 'bold', fontSize: '1.1rem' }}>{h.id}</div>
                    <div className="text-sm" style={{ color: 'var(--color-text-secondary)' }}>{h.reason}</div>
                  </div>
                  <button className="btn btn-danger" style={{ padding: '0.5rem' }} onClick={() => handleDeleteHoliday(h.id)}>
                    <Trash2 size={16} />
                  </button>
                </div>
              ))}
              {holidays.length === 0 && (
                <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--color-text-light)' }}>
                  No holidays marked.
                </div>
              )}
            </div>
          </GlassCard>
        </div>
      )}
    </div>
  );
};

export default SuperAdmin;
