import React, { useState, useEffect } from 'react';
import { 
  ShieldCheck, 
  LogOut, 
  ClipboardList, 
  PlusCircle, 
  CreditCard,
  FileText,
  Calendar,
  AlertCircle,
  CheckCircle,
  HelpCircle,
  Clock
} from 'lucide-react';
import api from '../api/axios';
import { useAuth } from '../hooks/useAuth';

export default function WorkerPortal() {
  const { user, logout } = useAuth();
  const [grievances, setGrievances] = useState([]);
  const [salaries, setSalaries] = useState([]);
  const [loadingGrievances, setLoadingGrievances] = useState(true);
  const [loadingSalaries, setLoadingSalaries] = useState(true);
  
  // Submit grievance form state
  const [category, setCategory] = useState('Salary Dispute');
  const [description, setDescription] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState(null);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  // Tab state
  const [activeTab, setActiveTab] = useState('grievances');

  const categories = [
    'Salary Dispute',
    'Safety Concern',
    'Harassment',
    'Working Hours',
    'Leave Denial',
    'Wrongful Termination',
    'Other'
  ];

  const loadGrievances = async () => {
    try {
      setLoadingGrievances(true);
      const res = await api.get('/api/worker-portal/grievances');
      setGrievances(res.data || []);
    } catch (err) {
      console.error('Failed to load grievances:', err);
    } finally {
      setLoadingGrievances(false);
    }
  };

  const loadSalaries = async () => {
    try {
      setLoadingSalaries(true);
      const res = await api.get('/api/worker-portal/salaries');
      setSalaries(res.data || []);
    } catch (err) {
      console.error('Failed to load salaries:', err);
    } finally {
      setLoadingSalaries(false);
    }
  };

  useEffect(() => {
    if (!user) return;
    loadGrievances();
    loadSalaries();
  }, [user]);

  const handleSubmitGrievance = async (e) => {
    e.preventDefault();
    if (!description.trim()) {
      setSubmitError('Please enter a description for your grievance.');
      return;
    }

    try {
      setSubmitting(true);
      setSubmitError(null);
      setSubmitSuccess(false);

      await api.post('/api/worker-portal/grievances', { category, description });
      
      setSubmitSuccess(true);
      setDescription('');
      setCategory('Salary Dispute');
      
      // Reload grievances feed
      loadGrievances();
    } catch (err) {
      console.error('Failed to submit grievance:', err);
      setSubmitError(err.response?.data?.error || 'Failed to submit grievance. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <header className="bg-slate-900 text-white px-8 py-4 flex items-center justify-between shadow-md shrink-0">
        <div className="flex items-center gap-3">
          <ShieldCheck className="w-8 h-8 text-emerald-500" />
          <div>
            <h1 className="font-extrabold text-base tracking-wider">GarmentGuard</h1>
            <p className="text-[10px] text-emerald-400 font-bold uppercase tracking-widest">Worker Portal</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="text-right hidden sm:block">
            <p className="text-xs text-slate-300 font-semibold">{user?.fullName}</p>
            <span className="text-[9px] font-bold text-slate-400">Worker ID: #{user?.workerId}</span>
          </div>
          <button
            onClick={logout}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-slate-400 hover:text-red-400 hover:bg-red-500/10 transition-all border border-slate-800"
          >
            <LogOut className="w-3.5 h-3.5" /> Sign Out
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 p-6 max-w-5xl mx-auto w-full space-y-6">
        
        {/* Banner */}
        <div className="bg-gradient-to-br from-emerald-800 to-emerald-600 rounded-2xl p-6 shadow-sm text-white flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div className="space-y-1">
            <span className="text-[9px] font-bold uppercase tracking-widest bg-white/20 px-2 py-0.5 rounded-full">Secure Session</span>
            <h2 className="text-xl font-bold">Personal Compliance & Wage Portal</h2>
            <p className="text-xs text-emerald-50 leading-relaxed max-w-xl">
              Submit workplace concerns anonymously or review your official payroll history. Your data is encrypted and protected.
            </p>
          </div>
        </div>

        {/* Tab Controls */}
        <div className="flex gap-2 border-b border-gray-200">
          <button
            onClick={() => setActiveTab('grievances')}
            className={`px-5 py-3 text-xs font-bold uppercase tracking-wider border-b-2 transition-all
              ${activeTab === 'grievances' 
                ? 'border-emerald-600 text-emerald-600 border-b-2' 
                : 'border-transparent text-gray-500 hover:text-gray-700'}`}
          >
            My Grievances
          </button>
          <button
            onClick={() => setActiveTab('salaries')}
            className={`px-5 py-3 text-xs font-bold uppercase tracking-wider border-b-2 transition-all
              ${activeTab === 'salaries' 
                ? 'border-emerald-600 text-emerald-600 border-b-2' 
                : 'border-transparent text-gray-500 hover:text-gray-700'}`}
          >
            Salary History
          </button>
        </div>

        {/* Tab Panels */}
        <div>
          
          {/* TAB 1: GRIEVANCES */}
          {activeTab === 'grievances' && (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
              
              {/* Left 2 cols: Grievances List */}
              <div className="lg:col-span-2 space-y-4">
                <h3 className="text-sm font-bold text-gray-800 uppercase tracking-wider flex items-center gap-2">
                  <ClipboardList className="w-4 h-4 text-emerald-600" />
                  Concern Registry
                </h3>
                
                {loadingGrievances ? (
                  <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
                  </div>
                ) : grievances.length > 0 ? (
                  <div className="space-y-4">
                    {grievances.map((g) => (
                      <div key={g.grievanceId} className="bg-white border border-gray-100 p-5 rounded-2xl shadow-sm space-y-3">
                        <div className="flex justify-between items-start">
                          <div>
                            <span className="text-xs font-bold text-emerald-600 bg-emerald-50 px-2.5 py-0.5 rounded-lg border border-emerald-200">
                              {g.category}
                            </span>
                            <p className="text-[10px] text-gray-400 mt-1 flex items-center gap-1">
                              <Calendar className="w-3.5 h-3.5" /> Filed: {g.submittedDate}
                            </p>
                          </div>
                          
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            g.status === 'Resolved' || g.status === 'Closed' ? 'bg-emerald-50 text-emerald-600' :
                            g.status === 'In Progress' || g.status === 'Investigating' ? 'bg-amber-50 text-amber-600' : 'bg-red-50 text-red-500'
                          }`}>
                            {g.status}
                          </span>
                        </div>

                        <p className="text-xs text-gray-600 leading-relaxed bg-slate-50/50 p-3 rounded-xl border border-slate-100">
                          {g.description}
                        </p>

                        {/* Resolution details if resolved */}
                        {g.resolutionNotes && (
                          <div className="border-t border-gray-100 pt-3 space-y-1">
                            <span className="text-[9px] uppercase font-bold text-emerald-600 flex items-center gap-1">
                              <CheckCircle className="w-3.5 h-3.5" /> Resolution Update ({g.resolvedDate}):
                            </span>
                            <p className="text-xs text-gray-500 italic pl-1 leading-relaxed">
                              {g.resolutionNotes}
                            </p>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-12 bg-white border border-gray-100 rounded-2xl">
                    <HelpCircle className="w-8 h-8 text-gray-300 mx-auto mb-2" />
                    <p className="text-xs text-gray-400 italic">You have not submitted any workplace concerns.</p>
                  </div>
                )}
              </div>

              {/* Right 1 col: Grievance Submission Form */}
              <div className="bg-white border border-gray-100 p-5 rounded-2xl shadow-sm space-y-4">
                <h3 className="text-sm font-bold text-gray-800 uppercase tracking-wider flex items-center gap-2">
                  <PlusCircle className="w-4 h-4 text-emerald-600" />
                  Submit Concern
                </h3>
                
                <form onSubmit={handleSubmitGrievance} className="space-y-4">
                  {submitError && (
                    <div className="bg-red-50 border border-red-200 text-red-700 p-3 rounded-xl text-xs flex gap-2">
                      <AlertCircle className="w-4 h-4 shrink-0" />
                      <span>{submitError}</span>
                    </div>
                  )}

                  {submitSuccess && (
                    <div className="bg-emerald-50 border border-emerald-200 text-emerald-700 p-3 rounded-xl text-xs flex gap-2">
                      <CheckCircle className="w-4 h-4 shrink-0" />
                      <span>Grievance submitted successfully. Compliance officers will inspect.</span>
                    </div>
                  )}

                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
                      Concern Category
                    </label>
                    <select
                      value={category}
                      onChange={(e) => setCategory(e.target.value)}
                      className="w-full text-xs font-medium text-gray-700 bg-white border border-gray-200 rounded-xl px-3 py-2.5 focus:border-emerald-500 focus:outline-none shadow-sm cursor-pointer"
                    >
                      {categories.map((cat) => (
                        <option key={cat} value={cat}>{cat}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
                      Detailed Description
                    </label>
                    <textarea
                      rows={5}
                      value={description}
                      onChange={(e) => setDescription(e.target.value)}
                      placeholder="Please details what happened, dates, names, or locations..."
                      className="w-full text-xs text-gray-700 bg-white border border-gray-200 rounded-xl px-3 py-2.5 focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500 shadow-sm"
                      required
                    />
                  </div>

                  <button
                    type="submit"
                    disabled={submitting}
                    className="w-full py-2.5 px-4 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-500 transition-colors shadow-sm disabled:opacity-50"
                  >
                    {submitting ? 'Submitting...' : 'File Secure Concern'}
                  </button>
                </form>

              </div>

            </div>
          )}

          {/* TAB 2: SALARY HISTORY */}
          {activeTab === 'salaries' && (
            <div className="space-y-4">
              <h3 className="text-sm font-bold text-gray-800 uppercase tracking-wider flex items-center gap-2">
                <CreditCard className="w-4 h-4 text-emerald-600" />
                Payroll Statement Registry
              </h3>

              {loadingSalaries ? (
                <div className="flex justify-center py-12">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
                </div>
              ) : salaries.length > 0 ? (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {salaries.map((s) => {
                    const monthName = s.month === 4 ? 'April' : s.month === 5 ? 'May' : `Month ${s.month}`;
                    return (
                      <div key={s.recordId} className="bg-white border border-gray-100 p-5 rounded-2xl shadow-sm flex flex-col justify-between hover:shadow-md transition-shadow relative">
                        <div className="flex justify-between items-start border-b border-gray-50 pb-3 mb-3">
                          <div>
                            <span className="text-xs font-bold text-slate-800">{monthName} {s.year}</span>
                            <span className="block text-[9px] text-gray-400 mt-0.5">Pay Slip #{s.recordId}</span>
                          </div>
                          <span className={`px-2 py-0.5 rounded text-[9px] font-bold ${
                            s.paymentStatus === 'Paid' ? 'bg-emerald-50 text-emerald-600' : 'bg-amber-50 text-amber-600'
                          }`}>
                            {s.paymentStatus}
                          </span>
                        </div>

                        <div className="space-y-2 text-xs text-gray-500 font-semibold">
                          <div className="flex justify-between">
                            <span>Base Salary:</span>
                            <span className="text-slate-800 font-bold">{s.baseAmount.toFixed(2)} BDT</span>
                          </div>
                          <div className="flex justify-between">
                            <span>Overtime Pay ({s.overtimeHours} hrs):</span>
                            <span className="text-slate-800 font-bold">+{s.overtimePaid.toFixed(2)} BDT</span>
                          </div>
                          <div className="flex justify-between">
                            <span>Deductions:</span>
                            <span className="text-red-500 font-bold">-{s.deductions.toFixed(2)} BDT</span>
                          </div>
                          <div className="flex justify-between border-t border-gray-100 pt-2 text-sm">
                            <span className="text-slate-800 font-bold">Net Salary Paid:</span>
                            <span className="text-emerald-600 font-extrabold">{s.netSalary.toFixed(2)} BDT</span>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <div className="text-center py-12 bg-white border border-gray-100 rounded-2xl">
                  <FileText className="w-8 h-8 text-gray-300 mx-auto mb-2" />
                  <p className="text-xs text-gray-400 italic">No payroll statements found on record.</p>
                </div>
              )}
            </div>
          )}

        </div>

      </main>

      {/* Footer */}
      <footer className="py-6 bg-slate-900 border-t border-slate-950 text-center text-xs text-slate-500">
        GarmentGuard worker workspace. Grievances are routed under virtual row filtration laws.
      </footer>
    </div>
  );
}
