import React from 'react';
import GlassCard from '../components/GlassCard';
import { Users, CheckCircle, XCircle, TrendingUp } from 'lucide-react';

const StatCard = ({ title, value, icon: Icon, color, trend }) => (
  <GlassCard style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
      <div>
        <p className="text-sm" style={{ marginBottom: '0.25rem' }}>{title}</p>
        <h3 style={{ fontSize: '2rem', fontWeight: '700', lineHeight: 1 }}>{value}</h3>
      </div>
      <div style={{ padding: '0.75rem', borderRadius: '12px', background: `var(--color-${color}-bg)`, color: `var(--color-${color})` }}>
        <Icon size={24} />
      </div>
    </div>
    {trend && (
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', color: trend.positive ? 'var(--color-success)' : 'var(--color-danger)' }}>
        <TrendingUp size={16} style={{ transform: trend.positive ? 'none' : 'rotate(180deg)' }}/>
        <span>{trend.value}% from yesterday</span>
      </div>
    )}
  </GlassCard>
);

const Statistics = () => {
  return (
    <div className="animate-fade-in">
      <div style={{ marginBottom: '2rem' }}>
        <h1 className="heading-lg">Daily Statistics</h1>
        <p className="text-sm">Performance overview for August 31, 2026</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
        <StatCard 
          title="Total Tokens Issued" 
          value="342" 
          icon={Users} 
          color="primary" 
          trend={{ value: 12, positive: true }} 
        />
        <StatCard 
          title="Tokens Served" 
          value="285" 
          icon={CheckCircle} 
          color="success" 
          trend={{ value: 8, positive: true }} 
        />
        <StatCard 
          title="No-Shows" 
          value="42" 
          icon={XCircle} 
          color="warning" 
          trend={{ value: 5, positive: false }} 
        />
        <StatCard 
          title="Avg Service Time" 
          value="4m 12s" 
          icon={TrendingUp} 
          color="accent" 
          trend={{ value: 15, positive: true }} 
        />
      </div>

      <h3 className="heading-md" style={{ marginBottom: '1rem' }}>Hourly Slot Utilization</h3>
      <GlassCard style={{ padding: '2rem', minHeight: '300px', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
        {/* Simple CSS-based Bar Chart Representation */}
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', height: '200px', gap: '0.5rem', borderBottom: '1px solid var(--color-border)' }}>
           {[65, 80, 95, 100, 85, 45, 60, 30].map((val, idx) => (
             <div key={idx} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.5rem' }}>
                <div style={{ width: '100%', maxWidth: '40px', height: `${val}%`, background: 'var(--color-primary)', borderRadius: '4px 4px 0 0', opacity: val > 90 ? 1 : 0.7, transition: 'height 1s ease' }}></div>
                <span className="text-sm" style={{ fontSize: '0.75rem' }}>{idx + 9}AM</span>
             </div>
           ))}
        </div>
        <div style={{ marginTop: '1.5rem', display: 'flex', justifyContent: 'center', gap: '2rem' }}>
           <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}><div style={{ width: '12px', height: '12px', background: 'var(--color-primary)', borderRadius: '2px' }}></div> <span className="text-sm">Booked</span></div>
           <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}><div style={{ width: '12px', height: '12px', background: 'var(--color-border)', borderRadius: '2px' }}></div> <span className="text-sm">Available Capacity</span></div>
        </div>
      </GlassCard>
    </div>
  );
};

export default Statistics;
