import React, { useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  fetchFactory, fetchFactoryWorkers,
  fetchFactoryAudits, fetchFactoryCertifications, fetchEquipmentAlerts
} from '../api/factories';
import { ComplianceBadge } from '../components/ComplianceBadge';
import {
  ArrowLeft, Users, ClipboardCheck, ShieldCheck, AlertTriangle,
  ChevronDown, ChevronUp, MapPin, Phone, Mail, User,
  BadgeCheck, Clock, TriangleAlert, CheckCircle2, XCircle,
  ChevronLeft, ChevronRight, Building2, Search, ArrowUpDown, ArrowUp, ArrowDown, X
} from 'lucide-react';

// ─── helpers ─────────────────────────────────────────────────────────────────
const safeStr = (v) => {
  if (!v) return null;
  if (typeof v === 'string') return v;
  if (typeof v === 'object' && v.toString) return v.toString();
  return String(v);
};

const fmt = {
  date: (d) => d
    ? new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
    : '—',
  currency: (n) => (n !== undefined && n !== null)
    ? '৳ ' + Number(n).toLocaleString('en-BD', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    : '—'
};

// ─── SVG Gauge — large, prominent, centred ───────────────────────────────────
function ComplianceGauge({ score }) {
  const hasScore = score !== null && score !== undefined;
  const pct = Math.max(0, Math.min(100, hasScore ? Number(score) : 0));

  // Centre the arc at (90,88) inside a 180×108 canvas.
  // The arc radius is 60px → rightmost point = 90+60 = 150px, leaving 30px margin.
  // This ensures strokeLinecap and the needle dot never reach the SVG boundary.
  const R = 60, cx = 90, cy = 88;
  const toXY = (a) => ({ x: cx + R * Math.cos(a), y: cy - R * Math.sin(a) });
  const frac = pct / 100;
  const angle = Math.PI - frac * Math.PI;
  const end = toXY(angle);
  const startPt = toXY(Math.PI);
  const trackE = toXY(0);
  const largeArc = 0;

  const color = !hasScore ? '#6b7280' : pct >= 75 ? '#10b981' : pct >= 40 ? '#f59e0b' : '#ef4444';

  return (
    <div className="flex flex-col items-center gap-1 select-none pr-2">
      {/* SVG is exactly the canvas size; no overflow-visible needed */}
      <svg width="180" height="108" viewBox="0 0 180 108">
        <defs>
          <filter id="gauge-glow" x="-30%" y="-30%" width="160%" height="160%">
            <feGaussianBlur stdDeviation="3" result="blur"/>
            <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
          </filter>
        </defs>
        {/* Track arc */}
        <path
          d={`M ${toXY(Math.PI).x} ${toXY(Math.PI).y} A ${R} ${R} 0 0 1 ${trackE.x} ${trackE.y}`}
          fill="none" stroke="rgba(255,255,255,0.12)" strokeWidth="10" strokeLinecap="round"
        />
        {/* Score arc */}
        {hasScore && pct > 0 && (
          <path
            d={`M ${startPt.x} ${startPt.y} A ${R} ${R} 0 ${largeArc} 1 ${end.x} ${end.y}`}
            fill="none" stroke={color} strokeWidth="10" strokeLinecap="round"
            filter="url(#gauge-glow)"
            style={{ transition: 'all 0.8s cubic-bezier(.4,0,.2,1)' }}
          />
        )}
        {/* Needle cap dot */}
        {hasScore && (
          <circle cx={end.x} cy={end.y} r="5" fill="white" stroke={color} strokeWidth="2.5"
            style={{ transition: 'all 0.8s cubic-bezier(.4,0,.2,1)' }}
          />
        )}
        {/* Score number */}
        <text x="90" y="80" textAnchor="middle" fontSize="28" fontWeight="800"
          fill={color} fontFamily="system-ui, -apple-system, sans-serif"
          style={{ transition: 'fill 0.5s ease' }}>
          {hasScore ? Math.round(pct) : '—'}
        </text>
        <text x="90" y="96" textAnchor="middle" fontSize="10" fill="rgba(255,255,255,0.45)"
          fontFamily="system-ui, -apple-system, sans-serif">
          out of 100
        </text>
      </svg>
      <span className="text-[11px] font-bold tracking-widest uppercase text-white/35">
        Compliance Score
      </span>
    </div>
  );
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────
const Sk = ({ className = '' }) => (
  <div className={`animate-pulse bg-white/10 rounded ${className}`} />
);
const SkLight = ({ className = '' }) => (
  <div className={`animate-pulse bg-gray-200 rounded ${className}`} />
);

// ─── Tab button ───────────────────────────────────────────────────────────────
function Tab({ active, onClick, icon: Icon, label, count }) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-2 px-5 py-3.5 text-sm font-semibold border-b-2 transition-all whitespace-nowrap
        ${active
          ? 'border-emerald-600 text-emerald-700 bg-emerald-50/50'
          : 'border-transparent text-gray-500 hover:text-gray-700 hover:bg-gray-50'}`}
    >
      <Icon className="w-4 h-4 shrink-0" />
      {label}
      {count !== undefined && count !== null && (
        <span className={`text-xs px-1.5 py-0.5 rounded-full font-bold min-w-[20px] text-center
          ${active ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-500'}`}>
          {count}
        </span>
      )}
    </button>
  );
}

// ─── Stat card ────────────────────────────────────────────────────────────────
function StatCard({ icon: Icon, label, value, color = 'emerald', sub, alert }) {
  const palettes = {
    emerald: { wrap: 'bg-emerald-50 text-emerald-600', ring: 'ring-emerald-100' },
    amber:   { wrap: 'bg-amber-50  text-amber-600',   ring: 'ring-amber-100'  },
    red:     { wrap: 'bg-red-50    text-red-600',     ring: 'ring-red-100'    },
    blue:    { wrap: 'bg-blue-50   text-blue-600',    ring: 'ring-blue-100'   },
  };
  const p = palettes[color] || palettes.emerald;
  return (
    <div className={`bg-white rounded-2xl border border-gray-100 p-5 flex items-start gap-4 shadow-sm
      hover:shadow-md hover:-translate-y-0.5 transition-all duration-200`}>
      <div className={`w-11 h-11 rounded-xl flex items-center justify-center shrink-0 ring-4 ${p.wrap} ${p.ring}`}>
        <Icon className="w-5 h-5" />
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-[11px] text-gray-400 font-semibold uppercase tracking-widest">{label}</p>
        <p className="text-3xl font-extrabold text-gray-900 leading-none mt-1">{value ?? '—'}</p>
        {sub && <p className="text-xs text-gray-400 mt-1 truncate">{sub}</p>}
      </div>
      {alert && <div className="w-2 h-2 rounded-full bg-red-500 mt-1 shrink-0 animate-pulse" />}
    </div>
  );
}

// ─── Shift badge ──────────────────────────────────────────────────────────────
const SHIFT_COLORS = {
  Morning: 'bg-amber-50   text-amber-700   border-amber-200',
  Evening: 'bg-orange-50  text-orange-700  border-orange-200',
  Night:   'bg-indigo-50  text-indigo-700  border-indigo-200',
  Day:     'bg-sky-50     text-sky-700     border-sky-200',
  Roster:  'bg-purple-50  text-purple-700  border-purple-200',
};
const ShiftBadge = ({ shift }) => (
  <span className={`inline-flex text-xs font-semibold px-2.5 py-1 rounded-full border
    ${SHIFT_COLORS[shift] || 'bg-gray-50 text-gray-600 border-gray-200'}`}>
    {shift}
  </span>
);

// ─── Score bar ────────────────────────────────────────────────────────────────
function ScoreBar({ score }) {
  if (score === null || score === undefined)
    return <span className="text-xs text-gray-400 italic">No score</span>;
  const pct = Math.min(100, Math.max(0, Number(score)));
  const color = pct >= 75 ? 'bg-emerald-500' : pct >= 40 ? 'bg-amber-500' : 'bg-red-500';
  return (
    <div className="flex items-center gap-3 min-w-[120px]">
      <div className="flex-1 h-1.5 bg-gray-200 rounded-full overflow-hidden">
        <div className={`h-full ${color} rounded-full transition-all duration-700`}
          style={{ width: `${pct}%` }} />
      </div>
      <span className="text-xs font-bold text-gray-700 tabular-nums w-6 text-right">{pct}</span>
    </div>
  );
}

// ─── Audit result badge ───────────────────────────────────────────────────────
const RESULT_CFG = {
  Passed:      { cls: 'bg-emerald-50 text-emerald-700 border-emerald-200', Icon: CheckCircle2 },
  Failed:      { cls: 'bg-red-50    text-red-700    border-red-200',     Icon: XCircle       },
  Conditional: { cls: 'bg-amber-50  text-amber-700  border-amber-200',   Icon: AlertTriangle  },
  Pending:     { cls: 'bg-blue-50   text-blue-700   border-blue-200',    Icon: Clock          },
};
const ResultBadge = ({ result }) => {
  const cfg = RESULT_CFG[result] || RESULT_CFG.Pending;
  return (
    <span className={`inline-flex items-center gap-1 text-xs font-bold px-2.5 py-1 rounded-full border ${cfg.cls}`}>
      <cfg.Icon className="w-3 h-3" />
      {result || 'Pending'}
    </span>
  );
};

// ─── Expiry countdown ─────────────────────────────────────────────────────────
function ExpiryChip({ days }) {
  const d = Number(days);
  if (isNaN(d)) return null;
  if (d < 0)   return <span className="text-[11px] font-bold text-white bg-red-500 px-2 py-0.5 rounded-full">Expired</span>;
  if (d === 0) return <span className="text-[11px] font-bold text-white bg-red-500 px-2 py-0.5 rounded-full">Today!</span>;
  if (d <= 30) return <span className="text-[11px] font-bold text-amber-700 bg-amber-100 border border-amber-300 px-2 py-0.5 rounded-full">{d}d left</span>;
  if (d <= 90) return <span className="text-[11px] font-medium text-yellow-700 bg-yellow-50 border border-yellow-200 px-2 py-0.5 rounded-full">{d}d left</span>;
  return <span className="text-[11px] font-medium text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full">{d}d left</span>;
}

// ─── Error banner ─────────────────────────────────────────────────────────────
const ErrorBanner = ({ message }) => (
  <div className="bg-red-50 border border-red-200 rounded-2xl p-5 flex items-center gap-3 text-red-700">
    <AlertTriangle className="w-5 h-5 shrink-0" />
    <span className="text-sm font-medium">{message}</span>
  </div>
);

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Overview
// ─────────────────────────────────────────────────────────────────────────────
function OverviewTab({ factory, alerts }) {
  const alertCount = alerts.data?.alerts?.length ?? 0;
  const hasAlerts  = !alerts.data?.allOk && alertCount > 0;

  return (
    <div className="space-y-5">
      {/* Stat cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <StatCard icon={Users}         label="Total Workers"   value={factory.totalWorkers?.toLocaleString()} color="blue" />
        <StatCard icon={AlertTriangle} label="Open Grievances" value={factory.openGrievancesCount}
          color={factory.openGrievancesCount > 0 ? 'red' : 'emerald'}
          alert={factory.openGrievancesCount > 0} />
        <StatCard icon={ShieldCheck}   label="Active Certs"    value={factory.activeCertsCount}   color="emerald" />
        <StatCard
          icon={TriangleAlert}
          label="Equipment Alerts"
          value={alerts.isLoading ? '…' : alertCount}
          color={hasAlerts ? 'amber' : 'emerald'}
          sub={hasAlerts ? 'Expiring within 30 days' : 'All equipment OK'}
          alert={hasAlerts}
        />
      </div>

      {/* Equipment alert pills */}
      {hasAlerts && (
        <div className="bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 rounded-2xl p-5">
          <div className="flex items-center gap-2 mb-3">
            <div className="w-7 h-7 bg-amber-100 rounded-lg flex items-center justify-center">
              <TriangleAlert className="w-4 h-4 text-amber-600" />
            </div>
            <h3 className="font-bold text-amber-800 text-sm">Safety Equipment Expiring Within 30 Days</h3>
          </div>
          <div className="flex flex-wrap gap-2">
            {alerts.data.alerts.map((item, i) => (
              <span key={i} className="bg-white text-amber-800 border border-amber-300 text-xs font-semibold px-3 py-1.5 rounded-full shadow-sm">
                ⚠ {item}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* Factory info */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
        <p className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-5">Factory Information</p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5 text-sm">
          {[
            { icon: MapPin,         label: 'Address',     value: factory.address        },
            { icon: MapPin,         label: 'District',    value: factory.district       },
            { icon: User,           label: 'Contact',     value: factory.contactPerson  },
            { icon: Phone,          label: 'Phone',       value: factory.phone          },
            { icon: Mail,           label: 'Email',       value: factory.email          },
            { icon: ClipboardCheck, label: 'Reg. Number', value: factory.registrationNo },
          ].map(({ icon: Icon, label, value }) => (
            <div key={label} className="flex items-start gap-3 group">
              <div className="w-8 h-8 bg-gray-50 rounded-lg flex items-center justify-center shrink-0 group-hover:bg-emerald-50 transition-colors">
                <Icon className="w-3.5 h-3.5 text-gray-400 group-hover:text-emerald-500 transition-colors" />
              </div>
              <div>
                <p className="text-[11px] font-semibold text-gray-400 uppercase tracking-wide">{label}</p>
                <p className="text-gray-800 font-medium mt-0.5 text-sm">{value || '—'}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Workers
// ─────────────────────────────────────────────────────────────────────────────
function WorkersTab({ factoryId }) {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [sortBy, setSortBy] = useState('fullName');
  const [order, setOrder] = useState('ASC');
  const LIMIT = 15;

  // Debounce search term changes
  React.useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(search);
      setPage(1);
    }, 400);

    return () => {
      clearTimeout(handler);
    };
  }, [search]);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['factory-workers', factoryId, page, debouncedSearch, sortBy, order],
    queryFn:  () => fetchFactoryWorkers(factoryId, page, LIMIT, new Date().getFullYear(), debouncedSearch, sortBy, order),
    keepPreviousData: true
  });

  const handleSort = (key) => {
    if (!key) return;
    if (sortBy === key) {
      setOrder(prev => prev === 'ASC' ? 'DESC' : 'ASC');
    } else {
      setSortBy(key);
      setOrder('ASC');
    }
    setPage(1);
  };

  const headers = [
    { label: 'Worker', key: 'fullName' },
    { label: 'Designation', key: 'designation' },
    { label: 'Shift', key: 'shift' },
    { label: 'Join Date', key: 'joinDate' },
    { label: 'Base Salary', key: 'baseSalary' },
    { label: `YTD Salary (${new Date().getFullYear()})`, key: null },
    { label: 'Status', key: 'status' }
  ];

  if (isError) return <ErrorBanner message="Could not load workers." />;

  return (
    <div className="space-y-4">
      {/* Search Input */}
      <div className="flex flex-col sm:flex-row gap-3 items-center justify-between pb-1">
        <div className="relative w-full sm:max-w-md">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
          <input
            type="text"
            placeholder="Search workers by name, NID, or designation..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-10 pr-10 py-2.5 text-sm bg-white border border-gray-200 rounded-xl focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all placeholder:text-gray-400"
          />
          {search && (
            <button
              onClick={() => setSearch('')}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 p-0.5 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-all"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[800px] text-sm">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100">
                {headers.map(h => {
                  const isSortable = h.key !== null;
                  const isSorted = sortBy === h.key;
                  return (
                    <th
                      key={h.label}
                      onClick={() => isSortable && handleSort(h.key)}
                      className={`px-5 py-3.5 text-left text-[11px] font-bold uppercase tracking-widest whitespace-nowrap select-none
                        ${isSortable ? 'cursor-pointer hover:text-gray-700 transition-colors text-gray-500' : 'text-gray-400'}`}
                    >
                      <div className="flex items-center gap-1.5">
                        <span className={isSorted ? 'text-emerald-700' : ''}>{h.label}</span>
                        {isSortable && (
                          <span className="shrink-0">
                            {isSorted ? (
                              order === 'ASC' ? (
                                <ArrowUp className="w-3 h-3 text-emerald-600" />
                              ) : (
                                <ArrowDown className="w-3 h-3 text-emerald-600" />
                              )
                            ) : (
                              <ArrowUpDown className="w-3 h-3 text-gray-300 hover:text-gray-400 transition-colors" />
                            )}
                          </span>
                        )}
                      </div>
                    </th>
                  );
                })}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {isLoading
                ? Array.from({ length: 6 }).map((_, i) => (
                    <tr key={i} className="animate-pulse">
                      {Array.from({ length: 7 }).map((_, j) => (
                        <td key={j} className="px-5 py-4"><div className="h-4 bg-gray-200 rounded-lg w-24"/></td>
                      ))}
                    </tr>
                  ))
                : data?.data?.length === 0
                  ? (
                    <tr>
                      <td colSpan={7} className="px-5 py-16 text-center">
                        <Users className="w-10 h-10 mx-auto mb-3 text-gray-200"/>
                        <p className="font-semibold text-gray-400">No workers found</p>
                      </td>
                    </tr>
                  )
                  : data?.data?.map((w) => (
                      <tr key={w.workerId} className="hover:bg-gray-50/80 transition-colors">
                        <td className="px-5 py-4">
                          <p className="font-semibold text-gray-900">{w.fullName}</p>
                          <p className="text-xs text-gray-400 mt-0.5">{w.nationalId}</p>
                        </td>
                        <td className="px-5 py-4 text-gray-600">{w.designation}</td>
                        <td className="px-5 py-4"><ShiftBadge shift={w.shift}/></td>
                        <td className="px-5 py-4 text-gray-500 tabular-nums">{fmt.date(w.joinDate)}</td>
                        <td className="px-5 py-4 font-mono text-gray-700">{fmt.currency(w.baseSalary)}</td>
                        <td className="px-5 py-4 font-mono font-bold text-emerald-700">{fmt.currency(w.ytdSalary)}</td>
                        <td className="px-5 py-4">
                          <span className={`text-xs font-semibold px-2.5 py-1 rounded-full
                            ${w.status === 'Active' ? 'bg-emerald-50 text-emerald-700' : 'bg-gray-100 text-gray-500'}`}>
                            {w.status}
                          </span>
                        </td>
                      </tr>
                    ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      {data && data.totalPages > 1 && (
        <div className="flex items-center justify-between text-xs text-gray-500 px-1">
          <span>Showing {((page-1)*LIMIT)+1}–{Math.min(page*LIMIT, data.total)} of {data.total}</span>
          <div className="flex gap-1">
            <button onClick={() => setPage(p => Math.max(1, p-1))} disabled={page===1}
              className="p-1.5 rounded-lg border border-gray-200 hover:bg-gray-50 disabled:opacity-30">
              <ChevronLeft className="w-4 h-4"/>
            </button>
            {Array.from({ length: data.totalPages }, (_, i) => i+1)
              .filter(p => p===1 || p===data.totalPages || Math.abs(p-page) <= 1)
              .map((p, idx, arr) => (
                <React.Fragment key={p}>
                  {idx > 0 && arr[idx-1] !== p-1 && <span className="px-1 text-gray-300 self-center">…</span>}
                  <button onClick={() => setPage(p)}
                    className={`w-8 h-8 rounded-lg text-xs font-bold border transition-colors
                      ${p===page ? 'bg-emerald-600 text-white border-emerald-600' : 'border-gray-200 hover:bg-gray-50'}`}>
                    {p}
                  </button>
                </React.Fragment>
              ))}
            <button onClick={() => setPage(p => Math.min(data.totalPages, p+1))} disabled={page===data.totalPages}
              className="p-1.5 rounded-lg border border-gray-200 hover:bg-gray-50 disabled:opacity-30">
              <ChevronRight className="w-4 h-4"/>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Audits  (timeline)
// ─────────────────────────────────────────────────────────────────────────────
function AuditsTab({ factoryId }) {
  const [expanded, setExpanded] = useState(new Set());
  const { data: audits, isLoading, isError } = useQuery({
    queryKey: ['factory-audits', factoryId],
    queryFn:  () => fetchFactoryAudits(factoryId)
  });

  const toggle = (id) => setExpanded(prev => {
    const s = new Set(prev);
    s.has(id) ? s.delete(id) : s.add(id);
    return s;
  });

  if (isError) return <ErrorBanner message="Could not load audit history." />;

  if (!isLoading && (!audits || audits.length === 0)) {
    return (
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm py-20 text-center">
        <ClipboardCheck className="w-12 h-12 mx-auto mb-3 text-gray-200"/>
        <p className="font-semibold text-gray-400">No audit records yet</p>
        <p className="text-sm text-gray-300 mt-1">Audits will appear here once completed.</p>
      </div>
    );
  }

  return (
    <div className="space-y-0">
      {isLoading
        ? Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="flex gap-4 mb-3">
              <div className="flex flex-col items-center pt-5 shrink-0">
                <div className="w-3 h-3 rounded-full bg-gray-200 animate-pulse"/>
                {i < 2 && <div className="w-px flex-1 mt-1 bg-gray-100"/>}
              </div>
              <div className="flex-1 bg-white rounded-2xl border border-gray-100 p-5 animate-pulse mb-3">
                <SkLight className="h-4 w-40 mb-3"/>
                <SkLight className="h-3 w-full"/>
              </div>
            </div>
          ))
        : audits.map((audit, idx) => {
            const isOpen = expanded.has(audit.auditId);
            const isLast = idx === audits.length - 1;
            const scoreNum = audit.score !== null ? Number(audit.score) : null;
            const dotColor = scoreNum === null ? 'bg-gray-300'
              : scoreNum >= 75 ? 'bg-emerald-500'
              : scoreNum >= 40 ? 'bg-amber-500'
              : 'bg-red-500';

            const findings        = safeStr(audit.findings);
            const recommendations = safeStr(audit.recommendations);

            return (
              <div key={audit.auditId} className="flex gap-4">
                {/* Timeline spine */}
                <div className="flex flex-col items-center shrink-0 pt-6">
                  <div className={`w-3 h-3 rounded-full ring-4 ring-white shadow ${dotColor}`}/>
                  {!isLast && <div className="w-px flex-1 mt-1 bg-gray-200 min-h-[24px]"/>}
                </div>

                {/* Audit card */}
                <div className="flex-1 mb-3">
                  <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden hover:shadow-md transition-shadow">
                    <button
                      onClick={() => toggle(audit.auditId)}
                      className="w-full text-left px-6 py-4 hover:bg-gray-50/80 transition-colors"
                    >
                      <div className="flex flex-wrap items-center gap-3 justify-between">
                        <div className="flex items-center gap-3 flex-wrap">
                          <span className="font-bold text-gray-900">{fmt.date(audit.auditDate)}</span>
                          <ResultBadge result={audit.result}/>
                          {audit.nextScheduled && (
                            <span className="text-xs text-gray-400 flex items-center gap-1">
                              <Clock className="w-3 h-3"/>
                              Next: {fmt.date(audit.nextScheduled)}
                            </span>
                          )}
                        </div>
                        <div className="flex items-center gap-4 shrink-0">
                          <div className="w-36 hidden sm:block">
                            <ScoreBar score={audit.score}/>
                          </div>
                          <span className="text-xs text-gray-400 hidden md:block">{audit.inspectorName}</span>
                          <div className={`w-7 h-7 rounded-lg flex items-center justify-center transition-colors
                            ${isOpen ? 'bg-emerald-50 text-emerald-600' : 'bg-gray-100 text-gray-400'}`}>
                            {isOpen ? <ChevronUp className="w-4 h-4"/> : <ChevronDown className="w-4 h-4"/>}
                          </div>
                        </div>
                      </div>
                    </button>

                    {isOpen && (
                      <div className="border-t border-gray-100 px-6 py-5 space-y-4 bg-gray-50/40">
                        <div className="sm:hidden">
                          <p className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-2">Score</p>
                          <ScoreBar score={audit.score}/>
                        </div>
                        {findings && (
                          <div>
                            <p className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-2">Findings</p>
                            <p className="text-sm text-gray-700 bg-white border border-gray-100 rounded-xl p-4 leading-relaxed whitespace-pre-wrap">{findings}</p>
                          </div>
                        )}
                        {recommendations && (
                          <div>
                            <p className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-2">Recommendations</p>
                            <p className="text-sm text-gray-700 bg-emerald-50 border border-emerald-100 rounded-xl p-4 leading-relaxed whitespace-pre-wrap">{recommendations}</p>
                          </div>
                        )}
                        {audit.inspectorEmail && (
                          <div className="flex items-center gap-2 pt-2 border-t border-gray-100 text-xs text-gray-400">
                            <Mail className="w-3.5 h-3.5"/>
                            {audit.inspectorEmail}
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: Certifications
// ─────────────────────────────────────────────────────────────────────────────
function CertificationsTab({ factoryId }) {
  const { data: certs, isLoading, isError } = useQuery({
    queryKey: ['factory-certifications', factoryId],
    queryFn:  () => fetchFactoryCertifications(factoryId)
  });

  if (isError) return <ErrorBanner message="Could not load certifications." />;

  if (!isLoading && (!certs || certs.length === 0)) {
    return (
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm py-20 text-center">
        <ShieldCheck className="w-12 h-12 mx-auto mb-3 text-gray-200"/>
        <p className="font-semibold text-gray-400">No certifications registered</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
      {isLoading
        ? Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="bg-white rounded-2xl border border-gray-100 p-5 animate-pulse space-y-3">
              <SkLight className="h-5 w-3/4"/>
              <SkLight className="h-3 w-1/2"/>
              <SkLight className="h-3 w-full mt-4"/>
            </div>
          ))
        : certs.map((c) => {
            const isValid   = c.isValid === 'Y';
            const days      = Number(c.daysUntilExpiry);
            const isExpired = days < 0;
            const isWarning = !isExpired && days <= 30;

            const borderCls = isExpired ? 'border-red-200' : isWarning ? 'border-amber-200' : isValid ? 'border-emerald-200' : 'border-gray-200';
            const headerBg  = isExpired ? 'bg-red-50/60' : isWarning ? 'bg-amber-50/60' : isValid ? 'bg-emerald-50/40' : 'bg-gray-50';

            return (
              <div key={c.certId}
                className={`bg-white rounded-2xl border-2 ${borderCls} overflow-hidden shadow-sm hover:shadow-md transition-all duration-200 hover:-translate-y-0.5`}>

                {/* Card header */}
                <div className={`px-5 pt-5 pb-4 ${headerBg}`}>
                  <div className="flex items-start justify-between gap-2 mb-1">
                    <div className="flex items-center gap-2">
                      {isValid
                        ? <BadgeCheck className="w-5 h-5 text-emerald-500 shrink-0"/>
                        : <XCircle    className="w-5 h-5 text-red-400    shrink-0"/>}
                      <h4 className="font-bold text-gray-900 text-sm leading-snug">{c.certName}</h4>
                    </div>
                    <ExpiryChip days={c.daysUntilExpiry}/>
                  </div>
                  <p className="text-xs text-gray-500 mt-1 pl-7">{c.issuingBody}</p>
                </div>

                {/* Dates */}
                <div className="px-5 py-3 border-t border-gray-100 text-xs text-gray-400 space-y-1.5">
                  <div className="flex justify-between">
                    <span>Issued</span>
                    <span className="font-semibold text-gray-600">{fmt.date(c.issueDate)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Expires</span>
                    <span className={`font-semibold ${isExpired ? 'text-red-600' : isWarning ? 'text-amber-600' : 'text-gray-600'}`}>
                      {fmt.date(c.expiryDate)}
                    </span>
                  </div>
                </div>

                {/* Status footer — single indicator, no redundancy */}
                <div className={`px-5 py-2.5 border-t border-gray-100 flex items-center justify-between text-xs font-bold
                  ${isExpired ? 'bg-red-50/60 text-red-600' : isValid ? 'bg-emerald-50/60 text-emerald-700' : 'bg-gray-50 text-gray-500'}`}>
                  <span>{c.status}</span>
                  <span>{isValid ? '✓ Valid' : '✗ Not valid'}</span>
                </div>
              </div>
            );
          })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────────────────────────────────────
export function FactoryDetail() {
  const { id } = useParams();
  const [activeTab, setActiveTab] = useState('overview');

  const factory = useQuery({
    queryKey: ['factory', id],
    queryFn:  () => fetchFactory(id),
    enabled:  !!id
  });

  const alerts = useQuery({
    queryKey: ['factory-equipment-alerts', id],
    queryFn:  () => fetchEquipmentAlerts(id),
    enabled:  !!id
  });

  const f = factory.data;

  // ── Loading ──────────────────────────────────────────────────────────────
  if (factory.isLoading) {
    return (
      <div className="space-y-5">
        <Link to="/factories" className="inline-flex items-center gap-1.5 text-sm text-gray-400">
          <ArrowLeft className="w-4 h-4"/> All Factories
        </Link>
        <div className="bg-gradient-to-br from-slate-900 to-slate-700 rounded-2xl p-8 animate-pulse">
          <div className="flex gap-8 justify-between">
            <div className="space-y-3 flex-1">
              <Sk className="h-8 w-56"/>
              <Sk className="h-4 w-40"/>
              <Sk className="h-6 w-28"/>
            </div>
            <Sk className="h-28 w-44 rounded-2xl"/>
          </div>
        </div>
      </div>
    );
  }

  // ── 404 ──────────────────────────────────────────────────────────────────
  if (factory.isError || !f) {
    return (
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-16 text-center">
        <Building2 className="w-12 h-12 text-gray-200 mx-auto mb-4"/>
        <h2 className="text-lg font-bold text-gray-700 mb-1">Factory Not Found</h2>
        <p className="text-sm text-gray-400 mb-6">No factory exists with ID {id}.</p>
        <Link to="/factories" className="inline-flex items-center gap-2 text-sm font-semibold text-emerald-600 hover:underline">
          <ArrowLeft className="w-4 h-4"/> Back to Factories
        </Link>
      </div>
    );
  }

  const workerWord = f.totalWorkers === 1 ? 'worker' : 'workers';

  return (
    <div className="space-y-5">
      {/* Back link */}
      <Link to="/factories"
        className="inline-flex items-center gap-1.5 text-sm font-medium text-gray-400 hover:text-emerald-600 transition-colors">
        <ArrowLeft className="w-4 h-4"/> All Factories
      </Link>

      {/* ── HEADER CARD ───────────────────────────────────────────────────── */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">

        {/* Dark hero band — NO overflow-hidden so SVG overflow-visible works */}
        <div className="relative bg-gradient-to-br from-slate-900 via-slate-800 to-slate-700 px-4 sm:px-8 py-6 md:py-8">
          {/* Background decoration */}
          <div className="absolute top-0 right-0 w-64 h-64 bg-emerald-500/5 rounded-full -translate-y-1/2 translate-x-1/3 pointer-events-none"/>
          <div className="absolute bottom-0 left-1/3 w-48 h-48 bg-white/3 rounded-full translate-y-1/2 pointer-events-none"/>

          <div className="relative flex flex-col lg:flex-row items-start lg:items-center gap-8 justify-between">

            {/* Left: name + meta */}
            <div className="flex-1 min-w-0 space-y-3">
              <div className="flex flex-wrap items-center gap-3">
                <h1 className="text-3xl font-extrabold text-white tracking-tight truncate">
                  {f.name}
                </h1>
                <ComplianceBadge score={f.complianceScore} status={f.complianceStatus}/>
              </div>

              <div className="flex flex-wrap items-center gap-x-5 gap-y-1.5 text-sm text-slate-300">
                <span className="flex items-center gap-1.5">
                  <MapPin className="w-3.5 h-3.5 text-emerald-400"/>
                  {f.district}
                </span>
                <span className="flex items-center gap-1.5">
                  <ClipboardCheck className="w-3.5 h-3.5 text-emerald-400"/>
                  {f.registrationNo}
                </span>
                <span className="flex items-center gap-1.5">
                  <Users className="w-3.5 h-3.5 text-emerald-400"/>
                  {f.totalWorkers?.toLocaleString()} {workerWord}
                </span>
              </div>
            </div>

            {/* Right: Gauge */}
            <div className="shrink-0">
              <ComplianceGauge score={f.complianceScore}/>
            </div>
          </div>
        </div>

        {/* ── TAB BAR ─────────────────────────────────────────────────────── */}
        <div className="flex border-b border-gray-100 overflow-x-auto">
          <Tab active={activeTab==='overview'}       onClick={() => setActiveTab('overview')}       icon={ShieldCheck}   label="Overview" />
          <Tab active={activeTab==='workers'}        onClick={() => setActiveTab('workers')}        icon={Users}         label="Workers"       count={f.totalWorkers} />
          <Tab active={activeTab==='audits'}         onClick={() => setActiveTab('audits')}         icon={ClipboardCheck} label="Audits" />
          <Tab active={activeTab==='certifications'} onClick={() => setActiveTab('certifications')} icon={BadgeCheck}    label="Certifications" count={f.activeCertsCount} />
        </div>
      </div>

      {/* ── TAB CONTENT ───────────────────────────────────────────────────── */}
      {activeTab === 'overview'        && <OverviewTab        factory={f} alerts={alerts}/>}
      {activeTab === 'workers'         && <WorkersTab         factoryId={id}/>}
      {activeTab === 'audits'          && <AuditsTab          factoryId={id}/>}
      {activeTab === 'certifications'  && <CertificationsTab  factoryId={id}/>}
    </div>
  );
}

export default FactoryDetail;
