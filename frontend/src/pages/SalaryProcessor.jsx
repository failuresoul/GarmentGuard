import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { 
  CreditCard, Search, Calendar, Clock, DollarSign, 
  X, ShieldCheck, AlertCircle, Building2, User, ChevronLeft, ChevronRight,
  ArrowUpDown, ArrowUp, ArrowDown
} from 'lucide-react';

export default function SalaryProcessor() {
  const [workers, setWorkers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  
  // Filter & Grid States
  const [selectedFactory, setSelectedFactory] = useState('All');
  const [selectedShift, setSelectedShift] = useState('All');
  const [selectedStatus, setSelectedStatus] = useState('All');
  const [sortBy, setSortBy] = useState('fullName');
  const [order, setOrder] = useState('asc');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  
  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedWorker, setSelectedWorker] = useState(null);
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const [year, setYear] = useState(new Date().getFullYear());
  const [overtimeHours, setOvertimeHours] = useState('');
  
  // Validation and API Results State
  const [otError, setOtError] = useState('');
  const [processing, setProcessing] = useState(false);
  const [apiError, setApiError] = useState('');
  const [payrollResult, setPayrollResult] = useState(null);

  const fetchWorkers = async () => {
    setLoading(true);
    try {
      const res = await api.get('/api/workers');
      setWorkers(res.data || []);
    } catch (err) {
      console.error('Failed to fetch workers:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWorkers();
  }, []);

  const handleOpenModal = (worker) => {
    setSelectedWorker(worker);
    setMonth(new Date().getMonth() + 1);
    setYear(new Date().getFullYear());
    setOvertimeHours('');
    setOtError('');
    setApiError('');
    setPayrollResult(null);
    setIsModalOpen(true);
  };

  const handleOvertimeChange = (value) => {
    setOvertimeHours(value);
    const hrs = parseInt(value, 10);
    if (!isNaN(hrs) && hrs > 60) {
      setOtError('Overtime hours cannot exceed the statutory limit of 60 hours.');
    } else {
      setOtError('');
    }
  };

  const handleProcessSalary = async (e) => {
    e.preventDefault();
    if (!selectedWorker) return;
    
    const hrs = parseInt(overtimeHours, 10);
    if (isNaN(hrs) || hrs < 0) {
      setOtError('Please enter a valid number of overtime hours.');
      return;
    }
    
    if (hrs > 60) {
      setOtError('Statutory compliance error: Overtime hours must be 60 or less.');
      return;
    }

    setProcessing(true);
    setApiError('');
    setPayrollResult(null);

    try {
      // Suppress toast so we can display the exception details directly inside the modal
      const res = await api.post(`/api/workers/${selectedWorker.workerId}/salary`, {
        month: parseInt(month, 10),
        year: parseInt(year, 10),
        overtimeHours: hrs
      }, { suppressToast: true });

      setPayrollResult(res.data);
      
      // Dispatch success toast
      window.dispatchEvent(new CustomEvent('app-toast', {
        detail: { type: 'success', message: 'Salary record created successfully!' }
      }));
    } catch (err) {
      const code = err.response?.data?.error?.code;
      const dbMessage = err.response?.data?.error?.message;

      if (code === 'DUPLICATE_PAYROLL_CYCLE') {
        setApiError(`Payroll Conflict: Salary has already been processed for this worker for month ${month}/${year}.`);
      } else if (code === 'OVERTIME_LIMIT_EXCEEDED') {
        setApiError('Overtime limit exceeded statutory cap of 60 hours.');
      } else {
        setApiError(dbMessage || 'An error occurred during payroll processing.');
      }
    } finally {
      setProcessing(false);
    }
  };

  // Memoized processing pipeline: filter -> sort -> page
  const processedWorkers = React.useMemo(() => {
    let result = [...workers];

    // 1. Text Search Filter
    if (search.trim() !== '') {
      const term = search.toLowerCase();
      result = result.filter(w => 
        (w.fullName || '').toLowerCase().includes(term) ||
        (w.nationalId || '').toLowerCase().includes(term) ||
        (w.designation || '').toLowerCase().includes(term)
      );
    }

    // 2. Factory Filter
    if (selectedFactory !== 'All') {
      result = result.filter(w => w.factoryName === selectedFactory);
    }

    // 3. Shift Filter
    if (selectedShift !== 'All') {
      result = result.filter(w => w.shift === selectedShift);
    }

    // 4. Status Filter
    if (selectedStatus !== 'All') {
      result = result.filter(w => w.status === selectedStatus);
    }

    // 5. Column Sorting
    if (sortBy) {
      result.sort((a, b) => {
        let valA = a[sortBy];
        let valB = b[sortBy];

        if (sortBy === 'baseSalary') {
          valA = parseFloat(valA) || 0;
          valB = parseFloat(valB) || 0;
        } else {
          valA = String(valA || '').toLowerCase();
          valB = String(valB || '').toLowerCase();
        }

        if (valA < valB) return order === 'asc' ? -1 : 1;
        if (valA > valB) return order === 'asc' ? 1 : -1;
        return 0;
      });
    }

    return result;
  }, [workers, search, selectedFactory, selectedShift, selectedStatus, sortBy, order]);

  // Pagination Calculations
  const totalRows = processedWorkers.length;
  const totalPages = Math.ceil(totalRows / pageSize) || 1;
  
  // Adjust current page if it is out of bounds
  useEffect(() => {
    if (page > totalPages) {
      setPage(1);
    }
  }, [totalPages, page]);

  const startIndex = (page - 1) * pageSize;
  const paginatedWorkers = processedWorkers.slice(startIndex, startIndex + pageSize);

  // Extract unique factories for dropdown filter list
  const uniqueFactories = React.useMemo(() => {
    const names = workers.map(w => w.factoryName).filter(Boolean);
    return ['All', ...Array.from(new Set(names))];
  }, [workers]);

  const fmtCurrency = (n) => (n !== undefined && n !== null)
    ? '৳ ' + Number(n).toLocaleString('en-BD', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    : '—';

  const handleSort = (colKey) => {
    if (sortBy === colKey) {
      setOrder(prev => prev === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(colKey);
      setOrder('asc');
    }
    setPage(1);
  };

  const renderSortIcon = (colKey) => {
    if (sortBy !== colKey) return <ArrowUpDown className="w-3 h-3 ml-1 shrink-0 text-gray-300 transition-colors group-hover:text-gray-400" />;
    return order === 'asc' 
      ? <ArrowUp className="w-3 h-3 ml-1 shrink-0 text-emerald-600" />
      : <ArrowDown className="w-3 h-3 ml-1 shrink-0 text-emerald-600" />;
  };

  return (
    <div className="space-y-4">
      {/* Search and control bar */}
      <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm space-y-4">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
              <CreditCard className="w-5 h-5 text-emerald-600" />
              Payroll & Stored Salary Processor
            </h2>
            <p className="text-xs text-gray-400 mt-0.5 uppercase tracking-wider font-semibold">
              Calculate Labour Law overtime rates and process monthly disbursals
            </p>
          </div>

          <div className="relative w-full md:max-w-xs">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
            <input
              type="text"
              placeholder="Search worker NID, designation..."
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              className="w-full pl-10 pr-4 py-2 text-sm bg-gray-50 border border-gray-100 rounded-xl focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all placeholder:text-gray-400 font-medium"
            />
          </div>
        </div>

        {/* Multi-Filters Bar */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-3 border-t border-gray-50">
          {/* Factory Selector */}
          <div>
            <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1">Factory</label>
            <select
              value={selectedFactory}
              onChange={(e) => { setSelectedFactory(e.target.value); setPage(1); }}
              className="w-full text-xs font-semibold bg-gray-50 border border-gray-200 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-emerald-500 transition-all text-gray-700"
            >
              {uniqueFactories.map(fac => (
                <option key={fac} value={fac}>{fac === 'All' ? 'All Factories' : fac}</option>
              ))}
            </select>
          </div>

          {/* Shift Selector */}
          <div>
            <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1">Shift</label>
            <select
              value={selectedShift}
              onChange={(e) => { setSelectedShift(e.target.value); setPage(1); }}
              className="w-full text-xs font-semibold bg-gray-50 border border-gray-200 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-emerald-500 transition-all text-gray-700"
            >
              <option value="All">All Shifts</option>
              <option value="Morning">Morning</option>
              <option value="Evening">Evening</option>
              <option value="Night">Night</option>
              <option value="Day">Day</option>
              <option value="Roster">Roster</option>
            </select>
          </div>

          {/* Status Selector */}
          <div>
            <label className="block text-[10px] font-bold text-gray-400 uppercase tracking-wider mb-1">Status</label>
            <select
              value={selectedStatus}
              onChange={(e) => { setSelectedStatus(e.target.value); setPage(1); }}
              className="w-full text-xs font-semibold bg-gray-50 border border-gray-200 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-emerald-500 transition-all text-gray-700"
            >
              <option value="All">All Statuses</option>
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
            </select>
          </div>
        </div>
      </div>

      {/* Workers table */}
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 select-none">
                <th 
                  onClick={() => handleSort('fullName')}
                  className="px-6 py-3.5 text-left text-[11px] font-bold text-gray-400 uppercase tracking-widest cursor-pointer hover:bg-gray-100/50 group transition-all"
                >
                  <div className="flex items-center">
                    Worker {renderSortIcon('fullName')}
                  </div>
                </th>
                <th 
                  onClick={() => handleSort('factoryName')}
                  className="px-6 py-3.5 text-left text-[11px] font-bold text-gray-400 uppercase tracking-widest cursor-pointer hover:bg-gray-100/50 group transition-all"
                >
                  <div className="flex items-center">
                    Factory {renderSortIcon('factoryName')}
                  </div>
                </th>
                <th 
                  onClick={() => handleSort('designation')}
                  className="px-6 py-3.5 text-left text-[11px] font-bold text-gray-400 uppercase tracking-widest cursor-pointer hover:bg-gray-100/50 group transition-all"
                >
                  <div className="flex items-center">
                    Designation {renderSortIcon('designation')}
                  </div>
                </th>
                <th 
                  onClick={() => handleSort('baseSalary')}
                  className="px-6 py-3.5 text-left text-[11px] font-bold text-gray-400 uppercase tracking-widest cursor-pointer hover:bg-gray-100/50 group transition-all"
                >
                  <div className="flex items-center">
                    Base Salary {renderSortIcon('baseSalary')}
                  </div>
                </th>
                <th 
                  onClick={() => handleSort('shift')}
                  className="px-6 py-3.5 text-left text-[11px] font-bold text-gray-400 uppercase tracking-widest cursor-pointer hover:bg-gray-100/50 group transition-all"
                >
                  <div className="flex items-center">
                    Shift {renderSortIcon('shift')}
                  </div>
                </th>
                <th 
                  onClick={() => handleSort('status')}
                  className="px-6 py-3.5 text-left text-[11px] font-bold text-gray-400 uppercase tracking-widest cursor-pointer hover:bg-gray-100/50 group transition-all"
                >
                  <div className="flex items-center">
                    Status {renderSortIcon('status')}
                  </div>
                </th>
                <th className="px-6 py-3.5 text-center text-[11px] font-bold text-gray-400 uppercase tracking-widest">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    {Array.from({ length: 7 }).map((_, j) => (
                      <td key={j} className="px-6 py-4"><div className="h-4 bg-gray-200 rounded w-24" /></td>
                    ))}
                  </tr>
                ))
              ) : paginatedWorkers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-6 py-16 text-center text-gray-400 text-sm">
                    No workers matched search filters.
                  </td>
                </tr>
              ) : (
                paginatedWorkers.map(w => (
                  <tr key={w.workerId} className="hover:bg-gray-50/50 transition-colors">
                    <td className="px-6 py-4">
                      <p className="font-semibold text-gray-900">{w.fullName}</p>
                      <p className="text-xs text-gray-400 mt-0.5">{w.nationalId}</p>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1.5 text-gray-700">
                        <Building2 className="w-3.5 h-3.5 text-gray-400" />
                        {w.factoryName}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-gray-600">{w.designation}</td>
                    <td className="px-6 py-4 font-mono font-semibold text-gray-700">{fmtCurrency(w.baseSalary)}</td>
                    <td className="px-6 py-4">
                      <span className="inline-flex text-xs font-semibold px-2 py-0.5 rounded-full bg-slate-100 text-slate-700">
                        {w.shift}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`text-xs font-bold px-2.5 py-0.5 rounded-full ${
                        w.status === 'Active' ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700'
                      }`}>
                        {w.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-center">
                      <button
                        onClick={() => handleOpenModal(w)}
                        className="bg-emerald-50 hover:bg-emerald-100 text-emerald-700 font-bold text-xs px-3.5 py-1.5 rounded-xl border border-emerald-100 hover:border-emerald-200 transition-all"
                      >
                        Process Salary
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Footer */}
        {totalRows > 0 && (
          <div className="px-6 py-4 bg-gray-50 border-t border-gray-100 flex flex-col sm:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-3 text-xs text-gray-500">
              <span>
                Showing {startIndex + 1}–{Math.min(startIndex + pageSize, totalRows)} of {totalRows} workers
              </span>
              <div className="flex items-center gap-1.5 bg-white border border-gray-200 rounded-lg px-2 py-1">
                <span className="text-[10px] font-bold text-gray-400 uppercase">Page Size</span>
                <select
                  value={pageSize}
                  onChange={(e) => { setPageSize(parseInt(e.target.value, 10)); setPage(1); }}
                  className="bg-transparent text-xs font-bold text-gray-700 outline-none cursor-pointer border-none p-0 focus:ring-0"
                >
                  <option value={5}>5</option>
                  <option value={10}>10</option>
                  <option value={20}>20</option>
                  <option value={50}>50</option>
                </select>
              </div>
            </div>

            {totalPages > 1 && (
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="p-1.5 rounded-lg border border-gray-200 bg-white text-gray-500 hover:bg-gray-50 disabled:opacity-30 transition-all"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
                  <button
                    key={p}
                    onClick={() => setPage(p)}
                    className={`w-8 h-8 rounded-lg text-xs font-bold transition-all border ${
                      p === page
                        ? 'bg-emerald-600 border-emerald-600 text-white shadow-sm'
                        : 'bg-white border-gray-200 text-gray-600 hover:bg-gray-50'
                    }`}
                  >
                    {p}
                  </button>
                ))}
                <button
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="p-1.5 rounded-lg border border-gray-200 bg-white text-gray-500 hover:bg-gray-50 disabled:opacity-30 transition-all"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Process Salary Modal */}
      {isModalOpen && selectedWorker && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full shadow-2xl border border-gray-100 overflow-hidden transform transition-all">
            {/* Header */}
            <div className="bg-slate-900 p-6 text-white flex items-center justify-between">
              <div>
                <h3 className="font-bold text-lg flex items-center gap-2">
                  <CreditCard className="w-5 h-5 text-emerald-400" />
                  Process Monthly Payroll
                </h3>
                <p className="text-xs text-slate-400 mt-1">Compute base scale & labor-law overtime rates</p>
              </div>
              <button 
                onClick={() => setIsModalOpen(false)}
                className="p-1.5 rounded-lg bg-white/10 hover:bg-white/20 text-white transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleProcessSalary} className="p-6 space-y-4">
              {/* Worker summary panel */}
              <div className="bg-slate-50 border border-slate-100 rounded-xl p-3.5 space-y-1.5">
                <div className="flex items-center gap-1.5 text-xs font-bold text-slate-400 uppercase tracking-wider">
                  <User className="w-3.5 h-3.5" />
                  Worker Summary
                </div>
                <div className="grid grid-cols-2 gap-2 text-xs text-slate-600 font-medium">
                  <div>
                    <span className="text-slate-400">Name:</span> {selectedWorker.fullName}
                  </div>
                  <div>
                    <span className="text-slate-400">Base Salary:</span> {fmtCurrency(selectedWorker.baseSalary)}
                  </div>
                  <div>
                    <span className="text-slate-400">Role:</span> {selectedWorker.designation}
                  </div>
                  <div>
                    <span className="text-slate-400">Factory:</span> {selectedWorker.factoryName}
                  </div>
                </div>
              </div>

              {/* Show errors */}
              {apiError && (
                <div className="p-3.5 bg-red-50 border border-red-200 text-red-600 text-xs font-bold rounded-xl flex items-start gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                  <div>{apiError}</div>
                </div>
              )}

              {/* Show success results */}
              {payrollResult && (
                <div className="p-4 bg-emerald-50 border border-emerald-100 text-emerald-800 rounded-xl space-y-2">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-700 uppercase tracking-wider">
                    <ShieldCheck className="w-4 h-4 text-emerald-600" />
                    Salary Record Processed
                  </div>
                  <div className="grid grid-cols-3 gap-2 text-xs font-semibold font-mono border-t border-emerald-100/60 pt-2 text-emerald-800">
                    <div>
                      <div className="text-[10px] text-emerald-600 font-bold uppercase tracking-wider">Base</div>
                      {fmtCurrency(payrollResult.baseAmount)}
                    </div>
                    <div>
                      <div className="text-[10px] text-emerald-600 font-bold uppercase tracking-wider">OT Paid</div>
                      {fmtCurrency(payrollResult.overtimePaid)}
                    </div>
                    <div className="border-l border-emerald-200 pl-2">
                      <div className="text-[10px] text-emerald-600 font-bold uppercase tracking-wider text-emerald-700 font-bold">Net Salary</div>
                      <span className="text-sm font-extrabold">{fmtCurrency(payrollResult.netSalary)}</span>
                    </div>
                  </div>
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                {/* Month Selector */}
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5 flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5" />
                    Month
                  </label>
                  <select
                    value={month}
                    onChange={(e) => setMonth(e.target.value)}
                    className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700 font-medium"
                  >
                    {Array.from({ length: 12 }, (_, i) => i + 1).map(m => (
                      <option key={m} value={m}>{new Date(2020, m - 1).toLocaleString('en-US', { month: 'long' })}</option>
                    ))}
                  </select>
                </div>

                {/* Year Selector */}
                <div>
                  <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5 flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5" />
                    Year
                  </label>
                  <select
                    value={year}
                    onChange={(e) => setYear(e.target.value)}
                    className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700 font-medium"
                  >
                    {Array.from({ length: 11 }, (_, i) => 2020 + i).map(y => (
                      <option key={y} value={y}>{y}</option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Overtime Hours */}
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5 flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5" />
                  Overtime Hours
                </label>
                <div className="relative">
                  <input
                    type="number"
                    min="0"
                    placeholder="e.g. 25"
                    value={overtimeHours}
                    onChange={(e) => handleOvertimeChange(e.target.value)}
                    className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700 font-mono placeholder:text-gray-400"
                  />
                  <span className="absolute right-3.5 top-1/2 -translate-y-1/2 text-xs font-bold text-gray-400">hours</span>
                </div>
                {otError && (
                  <p className="text-red-500 text-[11px] font-bold mt-1">{otError}</p>
                )}
              </div>

              {/* Footer Buttons */}
              <div className="flex items-center justify-end gap-3 pt-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 border border-gray-200 text-gray-500 font-semibold text-sm rounded-xl hover:bg-gray-50 transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={processing || otError !== ''}
                  className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm rounded-xl shadow-md transition-all disabled:opacity-50 flex items-center gap-1.5"
                >
                  {processing ? 'Processing...' : 'Run Payroll'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
