import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  fetchAudits, 
  fetchAuditMeta, 
  scheduleAudit, 
  recordAuditResults 
} from '../api/audits';
import { 
  ClipboardCheck, 
  Calendar, 
  User, 
  Plus, 
  FileText, 
  CheckCircle2, 
  AlertCircle, 
  HelpCircle,
  Clock,
  Search,
  Filter,
  X,
  TrendingUp,
  Sparkles
} from 'lucide-react';

export default function SafetyAudits() {
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [resultFilter, setResultFilter] = useState('All');

  // Modals state
  const [isScheduleOpen, setIsScheduleOpen] = useState(false);
  const [isRecordOpen, setIsRecordOpen] = useState(false);

  // Form states
  const [scheduleForm, setScheduleForm] = useState({
    factoryId: '',
    inspectorId: '',
    auditDate: new Date().toISOString().split('T')[0]
  });

  const [recordForm, setRecordForm] = useState({
    auditId: '',
    factoryName: '',
    score: '',
    result: 'Passed',
    findings: '',
    recommendations: '',
    nextScheduled: ''
  });

  const [formError, setFormError] = useState('');

  // Queries
  const { data: audits, isLoading: loadingAudits, error: auditsError } = useQuery({
    queryKey: ['audits'],
    queryFn: fetchAudits
  });

  const { data: metaData } = useQuery({
    queryKey: ['audit-meta'],
    queryFn: fetchAuditMeta
  });

  // Default dropdown selections when metadata is loaded
  useEffect(() => {
    if (metaData) {
      if (metaData.factories?.length > 0 && !scheduleForm.factoryId) {
        setScheduleForm(prev => ({ ...prev, factoryId: metaData.factories[0].factoryId }));
      }
      if (metaData.inspectors?.length > 0 && !scheduleForm.inspectorId) {
        setScheduleForm(prev => ({ ...prev, inspectorId: metaData.inspectors[0].userId }));
      }
    }
  }, [metaData]);

  // Mutations
  const scheduleMutation = useMutation({
    mutationFn: scheduleAudit,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['audits'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-data'] });
      setIsScheduleOpen(false);
      setFormError('');
      // dispatch global toast
      window.dispatchEvent(
        new CustomEvent('app-toast', {
          detail: { type: 'success', message: 'Audit scheduled successfully!' }
        })
      );
    },
    onError: (err) => {
      const dbMessage = err.response?.data?.error || err.response?.data?.errors?.[0]?.msg || err.message;
      setFormError(dbMessage);
    }
  });

  const recordMutation = useMutation({
    mutationFn: ({ id, data }) => recordAuditResults(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['audits'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-data'] });
      setIsRecordOpen(false);
      setFormError('');
      window.dispatchEvent(
        new CustomEvent('app-toast', {
          detail: { type: 'success', message: 'Audit results recorded and factory compliance scores updated!' }
        })
      );
    },
    onError: (err) => {
      const dbMessage = err.response?.data?.error || err.message;
      setFormError(dbMessage);
    }
  });

  const handleScheduleSubmit = (e) => {
    e.preventDefault();
    if (!scheduleForm.factoryId || !scheduleForm.inspectorId || !scheduleForm.auditDate) {
      setFormError('All fields are required.');
      return;
    }
    setFormError('');
    scheduleMutation.mutate({
      factoryId: parseInt(scheduleForm.factoryId, 10),
      inspectorId: parseInt(scheduleForm.inspectorId, 10),
      auditDate: scheduleForm.auditDate
    });
  };

  const handleRecordSubmit = (e) => {
    e.preventDefault();
    const scoreNum = parseFloat(recordForm.score);
    if (isNaN(scoreNum) || scoreNum < 0 || scoreNum > 100) {
      setFormError('Score must be a number between 0 and 100.');
      return;
    }
    setFormError('');
    recordMutation.mutate({
      id: recordForm.auditId,
      data: {
        score: scoreNum,
        result: recordForm.result,
        findings: recordForm.findings,
        recommendations: recordForm.recommendations,
        nextScheduled: recordForm.nextScheduled || null
      }
    });
  };

  const openRecordModal = (audit) => {
    setRecordForm({
      auditId: audit.auditId,
      factoryName: audit.factoryName,
      score: audit.score !== null ? audit.score.toString() : '80',
      result: audit.result === 'Pending' ? 'Passed' : audit.result,
      findings: audit.findings || '',
      recommendations: audit.recommendations || '',
      nextScheduled: audit.nextScheduled || new Date(new Date().setDate(new Date().getDate() + 180)).toISOString().split('T')[0]
    });
    setFormError('');
    setIsRecordOpen(true);
  };

  // Calculations for KPI Cards
  const stats = React.useMemo(() => {
    if (!audits) return { scheduled: 0, passed: 0, failed: 0, pending: 0 };
    return audits.reduce(
      (acc, curr) => {
        if (curr.result === 'Pending') acc.pending++;
        else if (curr.result === 'Passed') acc.passed++;
        else if (curr.result === 'Failed' || curr.result === 'Conditional') acc.failed++;
        return acc;
      },
      { scheduled: audits.length, passed: 0, failed: 0, pending: 0 }
    );
  }, [audits]);

  // Filtering list
  const filteredAudits = React.useMemo(() => {
    if (!audits) return [];
    return audits.filter((audit) => {
      const matchesSearch = audit.factoryName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        audit.inspectorName.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesResult = resultFilter === 'All' || audit.result === resultFilter;
      return matchesSearch && matchesResult;
    });
  }, [audits, searchTerm, resultFilter]);

  return (
    <div className="space-y-8 animate-fadeIn">
      {/* Header and Call to Action */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-gray-900 tracking-tight flex items-center gap-2">
            <ClipboardCheck className="w-7 h-7 text-emerald-600" />
            Safety Inspections & Audits
          </h2>
          <p className="text-gray-500 text-sm mt-1">
            Schedule new facility reviews, record compliance findings, and log structural checkups.
          </p>
        </div>
        <button
          onClick={() => {
            setFormError('');
            setIsScheduleOpen(true);
          }}
          className="flex items-center justify-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold px-5 py-2.5 rounded-xl shadow-md hover:shadow-lg transition-all duration-200"
        >
          <Plus className="w-5 h-5" />
          Schedule Safety Audit
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {/* Card 1 */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-5 hover:shadow-md transition-all">
          <div className="p-3.5 bg-blue-50 text-blue-600 rounded-xl">
            <ClipboardCheck className="w-6 h-6" />
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-400">Total Audits</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{stats.scheduled}</p>
          </div>
        </div>
        {/* Card 2 */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-5 hover:shadow-md transition-all">
          <div className="p-3.5 bg-yellow-50 text-yellow-600 rounded-xl">
            <Clock className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-400">Pending Reviews</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{stats.pending}</p>
          </div>
        </div>
        {/* Card 3 */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-5 hover:shadow-md transition-all">
          <div className="p-3.5 bg-emerald-50 text-emerald-600 rounded-xl">
            <CheckCircle2 className="w-6 h-6" />
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-400">Passed Audits</p>
            <p className="text-2xl font-bold text-gray-900 mt-1 text-emerald-600">{stats.passed}</p>
          </div>
        </div>
        {/* Card 4 */}
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-5 hover:shadow-md transition-all">
          <div className="p-3.5 bg-rose-50 text-rose-600 rounded-xl">
            <AlertCircle className="w-6 h-6" />
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-400">Failed / Conditional</p>
            <p className="text-2xl font-bold text-gray-900 mt-1 text-rose-600">{stats.failed}</p>
          </div>
        </div>
      </div>

      {/* Filters and List */}
      <div className="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
        {/* Filter Bar */}
        <div className="p-5 border-b border-gray-200 bg-gray-50/50 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4.5 h-4.5 text-gray-400" />
            <input
              type="text"
              placeholder="Search by factory or inspector name..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 bg-white text-sm"
            />
          </div>
          <div className="flex items-center gap-2">
            <Filter className="w-4.5 h-4.5 text-gray-400" />
            <span className="text-sm font-medium text-gray-500">Result Filter:</span>
            <select
              value={resultFilter}
              onChange={(e) => setResultFilter(e.target.value)}
              className="border border-gray-300 rounded-xl px-3 py-1.5 bg-white text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
            >
              <option value="All">All Results</option>
              <option value="Pending">Pending</option>
              <option value="Passed">Passed</option>
              <option value="Failed">Failed</option>
              <option value="Conditional">Conditional</option>
            </select>
          </div>
        </div>

        {/* Audit List Table */}
        <div className="overflow-x-auto">
          {loadingAudits ? (
            <div className="p-12 flex flex-col items-center justify-center text-gray-500 gap-3">
              <div className="w-8 h-8 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin"></div>
              <span className="text-sm font-medium">Loading audit history...</span>
            </div>
          ) : filteredAudits.length === 0 ? (
            <div className="p-12 flex flex-col items-center justify-center text-gray-400 text-sm font-medium gap-2">
              <ClipboardCheck className="w-12 h-12 text-gray-200" />
              <span>No audits matching the criteria were found.</span>
            </div>
          ) : (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-50/50 border-b border-gray-100 text-xs font-bold uppercase tracking-wider text-gray-500">
                  <th className="px-6 py-4">Audit ID</th>
                  <th className="px-6 py-4">Factory</th>
                  <th className="px-6 py-4">Inspector</th>
                  <th className="px-6 py-4">Inspection Date</th>
                  <th className="px-6 py-4">Score</th>
                  <th className="px-6 py-4">Result</th>
                  <th className="px-6 py-4">Next Audit</th>
                  <th className="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 text-sm">
                {filteredAudits.map((audit) => {
                  const resultColor = 
                    audit.result === 'Passed' ? 'bg-emerald-50 text-emerald-700 border-emerald-200' :
                    audit.result === 'Failed' ? 'bg-rose-50 text-rose-700 border-rose-200' :
                    audit.result === 'Conditional' ? 'bg-amber-50 text-amber-700 border-amber-200' :
                    'bg-sky-50 text-sky-700 border-sky-200';

                  return (
                    <tr key={audit.auditId} className="hover:bg-gray-50/40 transition-colors">
                      <td className="px-6 py-4 font-mono text-xs font-semibold text-gray-400">
                        #{audit.auditId}
                      </td>
                      <td className="px-6 py-4 font-semibold text-gray-900">
                        {audit.factoryName}
                      </td>
                      <td className="px-6 py-4 text-gray-600">
                        {audit.inspectorName}
                      </td>
                      <td className="px-6 py-4 text-gray-600 flex items-center gap-2">
                        <Calendar className="w-4 h-4 text-gray-400" />
                        {audit.auditDate}
                      </td>
                      <td className="px-6 py-4 font-bold text-gray-900">
                        {audit.score !== null ? (
                          <span className={audit.score >= 75 ? 'text-emerald-600' : audit.score >= 40 ? 'text-amber-500' : 'text-rose-600'}>
                            {audit.score.toFixed(1)}%
                          </span>
                        ) : (
                          <span className="text-gray-300 font-normal">--</span>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2.5 py-1 rounded-full text-xs font-bold border ${resultColor}`}>
                          {audit.result}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-gray-500">
                        {audit.nextScheduled || 'Not scheduled'}
                      </td>
                      <td className="px-6 py-4 text-right">
                        {audit.result === 'Pending' ? (
                          <button
                            onClick={() => openRecordModal(audit)}
                            className="text-xs font-bold text-emerald-600 hover:text-emerald-700 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 px-3 py-1.5 rounded-lg transition-colors"
                          >
                            Record Results
                          </button>
                        ) : (
                          <button
                            onClick={() => openRecordModal(audit)}
                            className="text-xs font-semibold text-slate-500 hover:text-slate-700 bg-slate-50 hover:bg-slate-100 border border-slate-200 px-3 py-1.5 rounded-lg transition-colors"
                          >
                            Update Report
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* SCHEDULE MODAL */}
      {isScheduleOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full shadow-2xl border border-gray-100 overflow-hidden animate-scaleIn">
            <div className="bg-slate-900 px-6 py-5 flex items-center justify-between text-white">
              <h3 className="font-bold text-lg flex items-center gap-2">
                <Calendar className="w-5 h-5 text-emerald-400" />
                Schedule Safety Audit
              </h3>
              <button onClick={() => setIsScheduleOpen(false)} className="text-slate-400 hover:text-white transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleScheduleSubmit} className="p-6 space-y-4">
              {formError && (
                <div className="bg-rose-50 text-rose-700 px-4 py-3 rounded-xl text-xs border border-rose-200 font-semibold flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{formError}</span>
                </div>
              )}

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-1.5">Target Factory</label>
                <select
                  value={scheduleForm.factoryId}
                  onChange={(e) => setScheduleForm(prev => ({ ...prev, factoryId: e.target.value }))}
                  className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                >
                  {metaData?.factories?.map((f) => (
                    <option key={f.factoryId} value={f.factoryId}>{f.factoryName}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-1.5">Assigned Inspector</label>
                <select
                  value={scheduleForm.inspectorId}
                  onChange={(e) => setScheduleForm(prev => ({ ...prev, inspectorId: e.target.value }))}
                  className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                >
                  {metaData?.inspectors?.map((ins) => (
                    <option key={ins.userId} value={ins.userId}>{ins.fullName}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-1.5">Inspection Date</label>
                <input
                  type="date"
                  value={scheduleForm.auditDate}
                  onChange={(e) => setScheduleForm(prev => ({ ...prev, auditDate: e.target.value }))}
                  className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                />
              </div>

              <div className="flex gap-3 justify-end pt-4 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setIsScheduleOpen(false)}
                  className="px-4 py-2.5 border border-gray-300 text-gray-700 font-semibold rounded-xl text-sm hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={scheduleMutation.isPending}
                  className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-xl text-sm shadow-md hover:shadow-lg transition-all duration-200 flex items-center justify-center gap-2"
                >
                  {scheduleMutation.isPending ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                      Scheduling...
                    </>
                  ) : (
                    'Confirm Schedule'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* RECORD RESULTS MODAL */}
      {isRecordOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full shadow-2xl border border-gray-100 overflow-hidden animate-scaleIn">
            <div className="bg-slate-900 px-6 py-5 flex items-center justify-between text-white">
              <h3 className="font-bold text-lg flex items-center gap-2">
                <FileText className="w-5 h-5 text-emerald-400" />
                Record Results: {recordForm.factoryName}
              </h3>
              <button onClick={() => setIsRecordOpen(false)} className="text-slate-400 hover:text-white transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleRecordSubmit} className="p-6 space-y-4">
              {formError && (
                <div className="bg-rose-50 text-rose-700 px-4 py-3 rounded-xl text-xs border border-rose-200 font-semibold flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{formError}</span>
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-1.5">Compliance Score (%)</label>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    step="0.1"
                    required
                    value={recordForm.score}
                    onChange={(e) => setRecordForm(prev => ({ ...prev, score: e.target.value }))}
                    placeholder="e.g. 85.5"
                    className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 font-semibold text-gray-900"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-1.5">Inspection Status</label>
                  <select
                    value={recordForm.result}
                    onChange={(e) => setRecordForm(prev => ({ ...prev, result: e.target.value }))}
                    className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 font-semibold"
                  >
                    <option value="Passed">Passed</option>
                    <option value="Failed">Failed</option>
                    <option value="Conditional">Conditional</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-1.5">Next Scheduled Audit Date</label>
                <input
                  type="date"
                  value={recordForm.nextScheduled}
                  onChange={(e) => setRecordForm(prev => ({ ...prev, nextScheduled: e.target.value }))}
                  className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-1.5">Audit Findings</label>
                <textarea
                  rows="3"
                  value={recordForm.findings}
                  onChange={(e) => setRecordForm(prev => ({ ...prev, findings: e.target.value }))}
                  placeholder="Describe electrical safety findings, exits accessibility, fire alarm status..."
                  className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-gray-700"
                ></textarea>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-1.5">Recommendations</label>
                <textarea
                  rows="2"
                  value={recordForm.recommendations}
                  onChange={(e) => setRecordForm(prev => ({ ...prev, recommendations: e.target.value }))}
                  placeholder="Required fixes or remediation steps..."
                  className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-gray-700"
                ></textarea>
              </div>

              <div className="flex gap-3 justify-end pt-4 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setIsRecordOpen(false)}
                  className="px-4 py-2.5 border border-gray-300 text-gray-700 font-semibold rounded-xl text-sm hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={recordMutation.isPending}
                  className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-xl text-sm shadow-md hover:shadow-lg transition-all duration-200 flex items-center justify-center gap-2"
                >
                  {recordMutation.isPending ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                      Saving Report...
                    </>
                  ) : (
                    'Record Findings'
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
