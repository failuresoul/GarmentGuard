import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { 
  Building2, 
  Award, 
  AlertCircle, 
  Flame, 
  ArrowUpRight, 
  ArrowDownRight, 
  Activity, 
  Calendar,
  ChevronUp,
  ChevronDown
} from 'lucide-react';
import { 
  ResponsiveContainer, 
  PieChart, 
  Pie, 
  Cell, 
  Tooltip, 
  Legend, 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  ReferenceLine 
} from 'recharts';
import api from '../api/axios';

const COLORS = ['#10B981', '#F59E0B', '#EF4444'];

export default function Dashboard() {
  const [dashboardData, setDashboardData] = useState(null);
  const [auditTrends, setAuditTrends] = useState([]);
  const [districtRankings, setDistrictRankings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Sorting state for district rankings
  const [sortField, setSortField] = useState('complianceRank');
  const [sortAsc, setSortAsc] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        setLoading(true);
        const [dashRes, trendsRes, rankRes] = await Promise.all([
          api.get('/api/dashboard'),
          api.get('/api/analytics/audit-trends'),
          api.get('/api/analytics/district-ranking')
        ]);
        setDashboardData(dashRes.data);
        setAuditTrends(trendsRes.data);
        setDistrictRankings(rankRes.data);
      } catch (err) {
        console.error('Failed to load dashboard data:', err);
        setError(err.message || 'Failed to load dashboard resources.');
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, []);

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-emerald-600"></div>
        <span className="ml-3 text-sm text-gray-500 font-medium">Loading GarmentGuard Dashboard...</span>
      </div>
    );
  }

  if (error || !dashboardData) {
    return (
      <div className="bg-red-50 border border-red-200 text-red-700 p-6 rounded-2xl">
        <h3 className="font-bold text-lg">System Loading Error</h3>
        <p className="text-sm mt-1">{error || 'Unable to retrieve dashboard aggregates from database.'}</p>
      </div>
    );
  }

  const { aggregates, recentGrievances, recentAudits } = dashboardData;

  // Donut chart preparation
  const complianceRate = aggregates.totalFactories > 0 
    ? Math.round((aggregates.compliantCount / aggregates.totalFactories) * 100) 
    : 0;

  const donutData = [
    { name: 'Compliant', value: aggregates.compliantCount || 0 },
    { name: 'At Risk', value: aggregates.atRiskCount || 0 },
    { name: 'Non-Compliant', value: aggregates.nonCompliantCount || 0 }
  ].filter(d => d.value > 0);

  // Sorting logic for table
  const handleSort = (field) => {
    if (sortField === field) {
      setSortAsc(!sortAsc);
    } else {
      setSortField(field);
      setSortAsc(true);
    }
  };

  const sortedRankings = [...districtRankings].sort((a, b) => {
    let valA = a[sortField];
    let valB = b[sortField];

    if (typeof valA === 'string') {
      return sortAsc ? valA.localeCompare(valB) : valB.localeCompare(valA);
    }
    return sortAsc ? valA - valB : valB - valA;
  });

  const SortIndicator = ({ field }) => {
    if (sortField !== field) return null;
    return sortAsc ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />;
  };

  return (
    <div className="space-y-8 animate-fadeIn">
      {/* ── TOP METRIC ROW ────────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6">
        
        {/* Metric 1: Total Factories */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow flex items-center justify-between">
          <div className="space-y-1">
            <span className="text-xs font-semibold tracking-wider text-gray-400 uppercase">Total Factories</span>
            <h3 className="text-3xl font-extrabold text-slate-800">{aggregates.totalFactories}</h3>
            <span className="text-xs text-gray-500 flex items-center gap-1 font-medium mt-1">
              <Activity className="w-3.5 h-3.5 text-emerald-500" /> Active Registry
            </span>
          </div>
          <div className="p-4 bg-slate-50 text-slate-600 rounded-xl">
            <Building2 className="w-6 h-6" />
          </div>
        </div>

        {/* Metric 2: Compliance % */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow flex items-center justify-between">
          <div className="space-y-1">
            <span className="text-xs font-semibold tracking-wider text-gray-400 uppercase">Compliance Rate</span>
            <h3 className="text-3xl font-extrabold text-emerald-600">{complianceRate}%</h3>
            <span className="text-xs flex items-center gap-0.5 text-emerald-600 font-semibold mt-1">
              <ArrowUpRight className="w-4 h-4" /> target: 80%+
            </span>
          </div>
          <div className="p-4 bg-emerald-50 text-emerald-600 rounded-xl">
            <Award className="w-6 h-6" />
          </div>
        </div>

        {/* Metric 3: Open Grievances */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow flex items-center justify-between">
          <div className="space-y-1">
            <span className="text-xs font-semibold tracking-wider text-gray-400 uppercase">Open Grievances</span>
            <h3 className={`text-3xl font-extrabold ${aggregates.openGrievances > 0 ? 'text-red-500' : 'text-emerald-600'}`}>
              {aggregates.openGrievances}
            </h3>
            <span className="text-xs flex items-center gap-0.5 text-slate-500 font-medium mt-1">
              Pending Resolution
            </span>
          </div>
          <div className={`p-4 rounded-xl ${aggregates.openGrievances > 0 ? 'bg-red-50 text-red-500' : 'bg-emerald-50 text-emerald-600'}`}>
            <AlertCircle className="w-6 h-6" />
          </div>
        </div>

        {/* Metric 4: Safety Alerts */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow flex items-center justify-between">
          <div className="space-y-1">
            <span className="text-xs font-semibold tracking-wider text-gray-400 uppercase">Equipment Alerts</span>
            <h3 className={`text-3xl font-extrabold ${aggregates.equipmentAlerts > 0 ? 'text-amber-500' : 'text-emerald-600'}`}>
              {aggregates.equipmentAlerts}
            </h3>
            <span className="text-xs flex items-center gap-0.5 text-slate-500 font-medium mt-1">
              Expiring in 30 Days
            </span>
          </div>
          <div className={`p-4 rounded-xl ${aggregates.equipmentAlerts > 0 ? 'bg-amber-50 text-amber-500' : 'bg-emerald-50 text-emerald-600'}`}>
            <Flame className="w-6 h-6" />
          </div>
        </div>

      </div>

      {/* ── CHARTS SECTION ───────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-5 gap-4 md:gap-6">
        
        {/* Compliance Distribution (2/5 size) */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm lg:col-span-2 flex flex-col justify-between">
          <div>
            <h3 className="font-bold text-gray-800 text-base">Compliance Distribution</h3>
            <p className="text-xs text-gray-400 mt-1">Factory status composition across registries</p>
          </div>
          <div className="h-60 mt-4 flex items-center justify-center">
            {donutData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={donutData}
                    cx="50%"
                    cy="50%"
                    innerRadius={65}
                    outerRadius={90}
                    paddingAngle={3}
                    dataKey="value"
                  >
                    {donutData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip 
                    contentStyle={{ borderRadius: '12px', borderColor: '#E2E8F0', fontSize: '12px' }}
                    itemStyle={{ fontWeight: 'bold' }}
                  />
                  <Legend 
                    verticalAlign="bottom" 
                    height={36} 
                    iconType="circle"
                    wrapperStyle={{ fontSize: '12px' }}
                  />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <span className="text-xs text-gray-400">No factory data loaded</span>
            )}
          </div>
        </div>

        {/* Audit Score Trend Line Chart (3/5 size) */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm lg:col-span-3 flex flex-col justify-between">
          <div>
            <h3 className="font-bold text-gray-800 text-base">Average Audit Score Trend</h3>
            <p className="text-xs text-gray-400 mt-1">12-Month aggregate timeline of safety inspections</p>
          </div>
          <div className="h-60 mt-4">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={auditTrends} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
                <XAxis 
                  dataKey="label" 
                  tick={{ fill: '#94A3B8', fontSize: 10 }} 
                  axisLine={false} 
                  tickLine={false} 
                />
                <YAxis 
                  domain={[0, 100]} 
                  tick={{ fill: '#94A3B8', fontSize: 10 }} 
                  axisLine={false} 
                  tickLine={false} 
                />
                <Tooltip 
                  contentStyle={{ borderRadius: '12px', borderColor: '#E2E8F0', fontSize: '12px' }}
                />
                <ReferenceLine y={75} stroke="#10B981" strokeDasharray="5 5" label={{ value: 'Compliant (75)', fill: '#10B981', fontSize: 10, position: 'top' }} />
                <ReferenceLine y={40} stroke="#EF4444" strokeDasharray="5 5" label={{ value: 'Action Level (40)', fill: '#EF4444', fontSize: 10, position: 'top' }} />
                <Line 
                  type="monotone" 
                  dataKey="avgScore" 
                  name="Avg Score"
                  stroke="#059669" 
                  strokeWidth={3} 
                  dot={{ r: 4, stroke: '#059669', strokeWidth: 2, fill: '#fff' }}
                  activeDot={{ r: 6 }}
                  connectNulls={true}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

      </div>

      {/* ── LOWER DETAIL ROW ──────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6">
        
        {/* District rankings table (2/3 size) */}
        <div className="bg-white p-4 md:p-6 rounded-2xl border border-gray-100 shadow-sm lg:col-span-2 flex flex-col">
          <div>
            <h3 className="font-bold text-gray-800 text-base">District Compliance Rankings</h3>
            <p className="text-xs text-gray-400 mt-1">Factories evaluated and ranked within their geographical districts (Query 1)</p>
          </div>
          <div className="overflow-x-auto mt-4">
            <table className="w-full text-left text-sm border-collapse">
              <thead>
                <tr className="border-b border-gray-100 text-gray-400 font-semibold text-xs">
                  <th 
                    onClick={() => handleSort('complianceRank')}
                    className="pb-3 cursor-pointer hover:text-emerald-600 transition-colors flex items-center gap-1"
                  >
                    Rank <SortIndicator field="complianceRank" />
                  </th>
                  <th 
                    onClick={() => handleSort('factoryName')}
                    className="pb-3 cursor-pointer hover:text-emerald-600 transition-colors"
                  >
                    Factory <SortIndicator field="factoryName" />
                  </th>
                  <th 
                    onClick={() => handleSort('district')}
                    className="pb-3 cursor-pointer hover:text-emerald-600 transition-colors hidden sm:table-cell"
                  >
                    District <SortIndicator field="district" />
                  </th>
                  <th 
                    onClick={() => handleSort('complianceScore')}
                    className="pb-3 cursor-pointer hover:text-emerald-600 transition-colors"
                  >
                    Score <SortIndicator field="complianceScore" />
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50 text-gray-700">
                {sortedRankings.length > 0 ? (
                  sortedRankings.map((row) => (
                    <tr key={row.factoryId} className="hover:bg-slate-50/50 transition-colors group">
                      <td className="py-3 font-semibold text-emerald-600">
                        #{row.complianceRank}
                      </td>
                      <td className="py-3 font-medium group-hover:text-emerald-700 transition-colors">
                        <Link to={`/factories/${row.factoryId}`} className="hover:underline">
                          {row.factoryName}
                        </Link>
                      </td>
                      <td className="py-3 text-gray-500 hidden sm:table-cell">
                        {row.district}
                      </td>
                      <td className="py-3 font-bold">
                        <span className={`px-2.5 py-0.5 rounded-full text-xs ${
                          row.complianceScore >= 75 ? 'bg-emerald-50 text-emerald-700' :
                          row.complianceScore >= 50 ? 'bg-amber-50 text-amber-700' : 'bg-red-50 text-red-700'
                        }`}>
                          {(row.complianceScore ?? 0).toFixed(1)}
                        </span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4} className="py-8 text-center text-gray-400 text-sm">
                      No district compliance data available
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Activity feed (1/3 size) */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col gap-6">
          
          {/* Recent Grievances (5 items) */}
          <div className="space-y-4">
            <div>
              <h3 className="font-bold text-gray-800 text-sm">Grievance Status Changes</h3>
              <p className="text-xs text-gray-400 mt-0.5">Last 5 worker updates</p>
            </div>
            <div className="space-y-3">
              {recentGrievances.length > 0 ? (
                recentGrievances.map((g) => (
                  <div key={g.grievanceId} className="flex gap-3 items-start text-xs border-l-2 border-emerald-500 pl-3 py-0.5">
                    <div className="space-y-1">
                      <p className="text-gray-700 font-semibold">{g.category}</p>
                      <p className="text-gray-400">{g.workerName} ({g.factoryName})</p>
                      <span className={`inline-block px-1.5 py-0.5 rounded text-[10px] font-bold ${
                        g.status === 'Resolved' || g.status === 'Closed' ? 'bg-emerald-50 text-emerald-600' :
                        g.status === 'In Progress' || g.status === 'Investigating' ? 'bg-amber-50 text-amber-600' : 'bg-red-50 text-red-500'
                      }`}>
                        {g.status}
                      </span>
                    </div>
                  </div>
                ))
              ) : (
                <p className="text-xs text-gray-400 italic">No recent grievances</p>
              )}
            </div>
          </div>

          {/* Recent Audits scheduled (3 items) */}
          <div className="space-y-4 pt-4 border-t border-gray-100">
            <div>
              <h3 className="font-bold text-gray-800 text-sm">Upcoming Scheduled Audits</h3>
              <p className="text-xs text-gray-400 mt-0.5">Safety & structural assessments</p>
            </div>
            <div className="space-y-3">
              {recentAudits.length > 0 ? (
                recentAudits.map((a) => (
                  <div key={a.auditId} className="flex gap-3 items-start text-xs border-l-2 border-slate-700 pl-3 py-0.5">
                    <div className="space-y-1 flex-1">
                      <p className="text-gray-700 font-semibold">{a.factoryName}</p>
                      <div className="flex items-center gap-1.5 text-gray-400 mt-0.5">
                        <Calendar className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                        <span>Scheduled: {a.nextScheduled}</span>
                      </div>
                    </div>
                  </div>
                ))
              ) : (
                <p className="text-xs text-gray-400 italic">No audits scheduled</p>
              )}
            </div>
          </div>

        </div>

      </div>
    </div>
  );
}
