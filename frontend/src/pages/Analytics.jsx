import React, { useState, useEffect } from 'react';
import { 
  ResponsiveContainer, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend 
} from 'recharts';
import { Users, AlertTriangle, TrendingUp, Hourglass } from 'lucide-react';
import api from '../api/axios';

export default function Analytics() {
  // Workers list and selection
  const [workers, setWorkers] = useState([]);
  const [selectedWorkerId, setSelectedWorkerId] = useState('');
  const [workerSalaryTrends, setWorkerSalaryTrends] = useState([]);
  
  // Grievances breakdown
  const [grievanceBreakdown, setGrievanceBreakdown] = useState([]);
  
  // Loading states
  const [loadingWorkers, setLoadingWorkers] = useState(true);
  const [loadingTrends, setLoadingTrends] = useState(false);
  const [loadingGrievances, setLoadingGrievances] = useState(true);
  
  // Error states
  const [error, setError] = useState(null);

  // Load workers and grievance breakdown on mount
  useEffect(() => {
    async function loadInitial() {
      try {
        setLoadingWorkers(true);
        setLoadingGrievances(true);
        const [workersRes, grievancesRes] = await Promise.all([
          api.get('/api/workers'),
          api.get('/api/analytics/grievance-breakdown')
        ]);
        
        const sortedWorkers = (workersRes.data || []).sort((a, b) => a.fullName.localeCompare(b.fullName));
        setWorkers(sortedWorkers);
        setGrievanceBreakdown(grievancesRes.data || []);
        
        // Auto-select first worker if available
        if (sortedWorkers.length > 0) {
          setSelectedWorkerId(sortedWorkers[0].workerId);
        }
      } catch (err) {
        console.error('Failed to load initial analytics:', err);
        setError('Failed to load workspace data.');
      } finally {
        setLoadingWorkers(false);
        setLoadingGrievances(false);
      }
    }
    loadInitial();
  }, []);

  // Load salary trends when selected worker changes
  useEffect(() => {
    if (!selectedWorkerId) return;

    async function loadSalaryTrends() {
      try {
        setLoadingTrends(true);
        const res = await api.get(`/api/analytics/salary-trends/${selectedWorkerId}`);
        // Map months to readable labels (e.g. Month 4, 5)
        const formatted = (res.data || []).map(row => ({
          ...row,
          monthName: row.month === 4 ? 'Apr 26' : row.month === 5 ? 'May 26' : `Month ${row.month}`
        }));
        setWorkerSalaryTrends(formatted);
      } catch (err) {
        console.error('Failed to load worker salary trends:', err);
      } finally {
        setLoadingTrends(false);
      }
    }
    loadSalaryTrends();
  }, [selectedWorkerId]);

  const selectedWorkerInfo = workers.find(w => w.workerId === parseInt(selectedWorkerId, 10));

  return (
    <div className="space-y-8 animate-fadeIn">
      {/* Page Title */}
      <div>
        <h2 className="text-xl font-bold text-gray-900">GarmentGuard Analytics Hub</h2>
        <p className="text-sm text-gray-500 mt-1">Cross-component compliance indices, worker wage profiles, and grievance response velocity.</p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 p-4 rounded-xl text-sm">
          {error}
        </div>
      )}

      {/* ── SECTION 1: WORKER SALARY TRENDS (Query 2) ───────────────────────── */}
      <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm space-y-6">
        
        <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between border-b border-gray-100 pb-4">
          <div className="space-y-1">
            <h3 className="font-bold text-gray-800 text-base flex items-center gap-2">
              <Users className="w-5 h-5 text-emerald-600" />
              Worker Wage Cumulative Trends
            </h3>
            <p className="text-xs text-gray-400">Cumulative running net salary per worker per year (Query 2)</p>
          </div>
          
          {/* Worker Selector Dropdown */}
          <div className="flex items-center gap-2">
            <span className="text-xs text-gray-400 font-semibold">Select Worker:</span>
            {loadingWorkers ? (
              <div className="h-9 w-48 bg-slate-50 border border-gray-100 rounded-lg animate-pulse"></div>
            ) : (
              <select
                value={selectedWorkerId}
                onChange={(e) => setSelectedWorkerId(e.target.value)}
                className="text-sm font-medium text-slate-700 bg-white border border-gray-200 rounded-lg px-3 py-1.5 focus:border-emerald-500 focus:outline-none shadow-sm cursor-pointer"
              >
                {workers.map((w) => (
                  <option key={w.workerId} value={w.workerId}>
                    {w.fullName} — {w.factoryName}
                  </option>
                ))}
              </select>
            )}
          </div>
        </div>

        {/* Selected Worker Info banner */}
        {selectedWorkerInfo && (
          <div className="bg-slate-50 p-4 rounded-xl flex flex-wrap gap-6 text-xs text-slate-600 font-medium border border-slate-100">
            <div>
              <span className="text-gray-400">Full Name:</span> <span className="text-gray-700 font-bold">{selectedWorkerInfo.fullName}</span>
            </div>
            <div>
              <span className="text-gray-400">Designation:</span> <span className="text-gray-700 font-bold">{selectedWorkerInfo.designation}</span>
            </div>
            <div>
              <span className="text-gray-400">Factory:</span> <span className="text-gray-700 font-bold">{selectedWorkerInfo.factoryName}</span>
            </div>
            <div>
              <span className="text-gray-400">Shift:</span> <span className="text-gray-700 font-bold">{selectedWorkerInfo.shift}</span>
            </div>
          </div>
        )}

        {/* Salary Trends Chart */}
        <div className="h-72">
          {loadingTrends ? (
            <div className="flex h-full items-center justify-center">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
            </div>
          ) : workerSalaryTrends.length > 0 ? (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={workerSalaryTrends} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
                <XAxis dataKey="monthName" tick={{ fill: '#94A3B8', fontSize: 10 }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fill: '#94A3B8', fontSize: 10 }} axisLine={false} tickLine={false} />
                <Tooltip contentStyle={{ borderRadius: '12px', borderColor: '#E2E8F0', fontSize: '12px' }} />
                <Legend iconType="circle" wrapperStyle={{ fontSize: '11px' }} />
                <Bar dataKey="netSalary" name="Net Salary Paid" fill="#34D399" radius={[4, 4, 0, 0]} maxBarSize={45} />
                <Bar dataKey="runningNetSalary" name="Cumulative Total (YTD)" fill="#059669" radius={[4, 4, 0, 0]} maxBarSize={45} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex h-full items-center justify-center text-xs text-gray-400 italic">
              No salary records found for this worker.
            </div>
          )}
        </div>

      </div>

      {/* ── SECTION 2: GRIEVANCES BREAKDOWN & SPEED (Backend 3) ───────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-5 gap-4 md:gap-6">
        
        {/* Horizontal Bar Chart (3/5 width) */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm lg:col-span-3 space-y-6">
          <div className="space-y-1">
            <h3 className="font-bold text-gray-800 text-base flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-amber-500" />
              Grievance Category Breakdown
            </h3>
            <p className="text-xs text-gray-400">Total volume of disputes registered by Category</p>
          </div>

          <div className="h-72">
            {loadingGrievances ? (
              <div className="flex h-full items-center justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
              </div>
            ) : grievanceBreakdown.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={grievanceBreakdown}
                  layout="vertical"
                  margin={{ top: 10, right: 10, left: 30, bottom: 0 }}
                >
                  <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#F1F5F9" />
                  <XAxis type="number" tick={{ fill: '#94A3B8', fontSize: 10 }} axisLine={false} tickLine={false} />
                  <YAxis dataKey="category" type="category" tick={{ fill: '#475569', fontSize: 10 }} axisLine={false} tickLine={false} />
                  <Tooltip contentStyle={{ borderRadius: '12px', borderColor: '#E2E8F0', fontSize: '12px' }} />
                  <Legend iconType="circle" wrapperStyle={{ fontSize: '11px' }} />
                  <Bar dataKey="openCount" name="Open" fill="#EF4444" stackId="a" radius={[0, 0, 0, 0]} />
                  <Bar dataKey="resolvedCount" name="Resolved" fill="#10B981" stackId="a" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="flex h-full items-center justify-center text-xs text-gray-400 italic">
                No grievance category records found.
              </div>
            )}
          </div>
        </div>

        {/* Average Resolution Time Panel (2/5 width) */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm lg:col-span-2 flex flex-col justify-between">
          <div className="space-y-1">
            <h3 className="font-bold text-gray-800 text-base flex items-center gap-2">
              <Hourglass className="w-5 h-5 text-blue-500" />
              Resolution Velocity
            </h3>
            <p className="text-xs text-gray-400">Average days taken to resolve grievances by category</p>
          </div>

          <div className="flex-1 flex flex-col justify-center space-y-4 my-6">
            {loadingGrievances ? (
              <div className="space-y-3">
                <div className="h-8 bg-slate-50 border border-gray-50 rounded-xl animate-pulse"></div>
                <div className="h-8 bg-slate-50 border border-gray-50 rounded-xl animate-pulse"></div>
                <div className="h-8 bg-slate-50 border border-gray-50 rounded-xl animate-pulse"></div>
              </div>
            ) : grievanceBreakdown.length > 0 ? (
              grievanceBreakdown.map((row) => (
                <div key={row.category} className="flex justify-between items-center text-xs pb-3 border-b border-gray-50">
                  <span className="font-semibold text-slate-700">{row.category}</span>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-slate-900 bg-slate-100 px-2 py-0.5 rounded">
                      {row.avgResolutionTime !== null ? `${row.avgResolutionTime} days` : 'N/A'}
                    </span>
                    {row.avgResolutionTime !== null && (
                      <span className={`w-2.5 h-2.5 rounded-full ${
                        row.avgResolutionTime <= 7 ? 'bg-emerald-500' :
                        row.avgResolutionTime <= 10 ? 'bg-amber-500' : 'bg-red-500'
                      }`} />
                    )}
                  </div>
                </div>
              ))
            ) : (
              <p className="text-xs text-gray-400 italic text-center">No speed data available</p>
            )}
          </div>
          
          <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-100 flex gap-2.5 items-start">
            <TrendingUp className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
            <p className="text-[10px] leading-relaxed text-slate-500">
              <span className="font-bold text-slate-700">Target Benchmark:</span> Resolve salary disputes in &lt; 7 days. Green dots denote categories matching compliance goals.
            </p>
          </div>
        </div>

      </div>

    </div>
  );
}
