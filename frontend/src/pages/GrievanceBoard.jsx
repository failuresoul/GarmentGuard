import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { useFactories } from '../hooks/useFactories';
import { 
  AlertTriangle, Clock, Plus, Search, Calendar, 
  Building2, User, CheckCircle2, ChevronRight, X, Sparkles
} from 'lucide-react';

export default function GrievanceBoard() {
  const { factories, loading: loadingFactories } = useFactories();
  const [selectedFactoryId, setSelectedFactoryId] = useState('');
  const [grievances, setGrievances] = useState([]);
  const [loadingGrievances, setLoadingGrievances] = useState(false);
  const [isSubmitModalOpen, setIsSubmitModalOpen] = useState(false);
  
  // Filter States
  const [selectedStatusTab, setSelectedStatusTab] = useState('All');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [searchText, setSearchText] = useState('');
  
  // Submit Form State
  const [workers, setWorkers] = useState([]);
  const [selectedWorkerId, setSelectedWorkerId] = useState('');
  const [category, setCategory] = useState('');
  const [description, setDescription] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState('');

  // Auto-select first factory when loaded
  useEffect(() => {
    if (factories && factories.length > 0 && !selectedFactoryId) {
      setSelectedFactoryId(factories[0].factoryId || factories[0].FACTORY_ID);
    }
  }, [factories, selectedFactoryId]);

  // Load grievances for selected factory
  const fetchGrievances = async (id) => {
    if (!id) return;
    setLoadingGrievances(true);
    try {
      const res = await api.get(`/api/factories/${id}/grievances`);
      setGrievances(res.data || []);
    } catch (err) {
      console.error('Failed to load grievances:', err);
    } finally {
      setLoadingGrievances(false);
    }
  };

  useEffect(() => {
    if (selectedFactoryId) {
      fetchGrievances(selectedFactoryId);
    }
  }, [selectedFactoryId]);

  // Process filtered grievances
  const filteredGrievances = React.useMemo(() => {
    return grievances.filter(g => {
      // Category filter
      if (selectedCategory !== 'All' && g.category !== selectedCategory) {
        return false;
      }
      // Free-text search
      if (searchText.trim() !== '') {
        const term = searchText.toLowerCase();
        const matchesName = (g.workerName || '').toLowerCase().includes(term);
        const matchesDesc = (g.description || '').toLowerCase().includes(term);
        const matchesCategory = (g.category || '').toLowerCase().includes(term);
        if (!matchesName && !matchesDesc && !matchesCategory) {
          return false;
        }
      }
      return true;
    });
  }, [grievances, selectedCategory, searchText]);

  // Load workers of the selected factory for grievance submission dropdown
  const loadWorkers = async (id) => {
    if (!id) return;
    try {
      const res = await api.get(`/api/factories/${id}/workers`);
      setWorkers(res.data?.data || []);
    } catch (err) {
      console.error('Failed to load workers:', err);
    }
  };

  const handleOpenSubmitModal = () => {
    loadWorkers(selectedFactoryId);
    setSelectedWorkerId('');
    setCategory('');
    setDescription('');
    setSubmitError('');
    setIsSubmitModalOpen(true);
  };

  const handleSubmitGrievance = async (e) => {
    e.preventDefault();
    if (!selectedWorkerId || !category || !description) {
      setSubmitError('All fields are required.');
      return;
    }
    setSubmitting(true);
    setSubmitError('');
    try {
      await api.post('/api/grievances', {
        workerId: selectedWorkerId,
        category,
        description
      });
      setIsSubmitModalOpen(false);
      fetchGrievances(selectedFactoryId); // Refresh list
      
      // Dispatch success toast
      window.dispatchEvent(new CustomEvent('app-toast', {
        detail: { type: 'success', message: 'Grievance submitted successfully.' }
      }));
    } catch (err) {
      setSubmitError(err.response?.data?.error?.message || 'Failed to submit grievance.');
    } finally {
      setSubmitting(false);
    }
  };

  // Drag-and-drop mechanics
  const handleDragStart = (e, grievanceId, sourceColumn) => {
    e.dataTransfer.setData('text/plain', JSON.stringify({ grievanceId, sourceColumn }));
  };

  const handleDrop = async (e, targetColumn) => {
    const { grievanceId, sourceColumn } = JSON.parse(e.dataTransfer.getData('text/plain'));
    if (sourceColumn === targetColumn) return;

    // Save previous state for rollback
    const prevGrievances = [...grievances];

    // Optimistic Update
    setGrievances(prev => prev.map(g => 
      g.grievanceId === grievanceId ? { ...g, status: targetColumn } : g
    ));

    try {
      await api.patch(`/api/grievances/${grievanceId}/status`, { 
        status: targetColumn,
        resolutionNotes: targetColumn === 'Resolved' ? 'Status updated via Kanban drag.' : null
      });
    } catch (error) {
      // Rollback
      setGrievances(prevGrievances);
      window.dispatchEvent(new CustomEvent('app-toast', {
        detail: { type: 'error', message: 'Failed to update status. Rolled back.' }
      }));
    }
  };

  const columns = [
    { id: 'Open', title: 'Open Issues', colorClass: 'border-t-amber-500 bg-amber-50/20 text-amber-800' },
    { id: 'In Progress', title: 'In Progress', colorClass: 'border-t-blue-500 bg-blue-50/20 text-blue-800' },
    { id: 'Resolved', title: 'Resolved', colorClass: 'border-t-emerald-500 bg-emerald-50/20 text-emerald-800' }
  ];

  const visibleColumns = React.useMemo(() => {
    if (selectedStatusTab === 'All') return columns;
    return columns.filter(c => c.id === selectedStatusTab);
  }, [selectedStatusTab]);

  const getGrievanceDays = (g) => {
    if (!g.resolvedDate || !g.submittedDate) return null;
    const diffTime = Math.abs(new Date(g.resolvedDate) - new Date(g.submittedDate));
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  };

  return (
    <div className="space-y-6">
      {/* Top action bar */}
      <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
            <AlertTriangle className="w-5 h-5 text-amber-500" />
            Labor Grievance Board
          </h2>
          <p className="text-xs text-gray-400 mt-0.5 uppercase tracking-wider font-semibold">
            Track and manage worker complaints and resolutions
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Factory Selector */}
          <div className="flex items-center gap-2 bg-gray-50 border border-gray-100 rounded-xl px-3 py-1.5">
            <Building2 className="w-4 h-4 text-gray-400" />
            <select
              value={selectedFactoryId}
              onChange={(e) => setSelectedFactoryId(e.target.value)}
              className="bg-transparent text-sm font-semibold text-gray-700 outline-none cursor-pointer border-none p-0 focus:ring-0"
            >
              <option value="" disabled>Select Factory</option>
              {factories.map((fac) => (
                <option key={fac.factoryId || fac.FACTORY_ID} value={fac.factoryId || fac.FACTORY_ID}>
                  {fac.name}
                </option>
              ))}
            </select>
          </div>

          {/* New Grievance button */}
          <button
            onClick={handleOpenSubmitModal}
            disabled={!selectedFactoryId}
            className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-sm px-4 py-2 rounded-xl shadow-md transition-all hover:-translate-y-0.5 disabled:opacity-50 disabled:pointer-events-none"
          >
            <Plus className="w-4 h-4" />
            New Grievance
          </button>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        {/* Status Tabs */}
        <div className="flex gap-1 bg-gray-100/80 p-1 rounded-xl shrink-0">
          {['All', 'Open', 'In Progress', 'Resolved'].map(tab => (
            <button
              key={tab}
              onClick={() => setSelectedStatusTab(tab)}
              className={`px-4 py-1.5 text-xs font-bold rounded-lg transition-all ${
                selectedStatusTab === tab
                  ? 'bg-white text-emerald-800 shadow-sm'
                  : 'text-gray-500 hover:text-gray-800'
              }`}
            >
              {tab === 'All' ? 'All Statuses' : tab}
            </button>
          ))}
        </div>

        <div className="flex flex-wrap items-center gap-3 w-full md:justify-end">
          {/* Category Selector */}
          <div className="flex items-center gap-1.5 bg-gray-50 border border-gray-100 rounded-xl px-3 py-1.5">
            <span className="text-[10px] font-bold text-gray-400 uppercase">Category</span>
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="bg-transparent text-xs font-bold text-gray-700 outline-none cursor-pointer border-none p-0 focus:ring-0"
            >
              <option value="All">All Categories</option>
              <option value="Salary Dispute">Salary Dispute</option>
              <option value="Overtime Violation">Overtime Violation</option>
              <option value="Harassment">Harassment</option>
              <option value="Safety Hazard">Safety Hazard</option>
              <option value="Leave Rejection">Leave Rejection</option>
              <option value="Other">Other</option>
            </select>
          </div>

          {/* Search text */}
          <div className="relative w-full md:max-w-xs">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400 pointer-events-none" />
            <input
              type="text"
              placeholder="Search worker or description..."
              value={searchText}
              onChange={(e) => setSearchText(e.target.value)}
              className="w-full pl-8 pr-4 py-1.5 text-xs bg-gray-50 border border-gray-100 rounded-xl focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all placeholder:text-gray-400 font-medium"
            />
          </div>
        </div>
      </div>

      {/* Kanban Board Container */}
      <div className={`grid grid-cols-1 ${visibleColumns.length === 1 ? 'md:grid-cols-1 max-w-2xl mx-auto' : 'sm:grid-cols-2 lg:grid-cols-3'} gap-6`}>
        {visibleColumns.map(col => {
          const colGrievances = filteredGrievances.filter(g => g.status === col.id);
          return (
            <div
              key={col.id}
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => handleDrop(e, col.id)}
              className={`flex flex-col min-h-[500px] bg-slate-50/50 rounded-2xl border border-gray-100/80 p-4 transition-all duration-200`}
            >
              {/* Column Header */}
              <div className="flex items-center justify-between mb-4 pb-2 border-b border-gray-100">
                <h3 className="font-bold text-gray-800 text-sm tracking-wide flex items-center gap-2">
                  <span className={`w-2.5 h-2.5 rounded-full ${
                    col.id === 'Open' ? 'bg-amber-500' : col.id === 'In Progress' ? 'bg-blue-500' : 'bg-emerald-500'
                  }`} />
                  {col.title}
                </h3>
                <span className="text-xs px-2 py-0.5 bg-gray-100 text-gray-500 font-bold rounded-full">
                  {colGrievances.length}
                </span>
              </div>

              {/* Cards list */}
              <div className="flex-1 space-y-3 overflow-y-auto max-h-[600px] pr-1">
                {loadingGrievances ? (
                  <div className="space-y-3">
                    {[1, 2].map(i => (
                      <div key={i} className="bg-white p-4 rounded-xl border border-gray-100 animate-pulse">
                        <div className="h-4 bg-gray-200 rounded w-16 mb-2" />
                        <div className="h-3 bg-gray-200 rounded w-full mb-1" />
                        <div className="h-3 bg-gray-200 rounded w-3/4" />
                      </div>
                    ))}
                  </div>
                ) : colGrievances.length === 0 ? (
                  <div className="h-32 flex flex-col items-center justify-center border-2 border-dashed border-gray-200 rounded-xl text-gray-400 text-xs">
                    Drop items here
                  </div>
                ) : (
                  colGrievances.map(g => (
                    <div
                      key={g.grievanceId}
                      draggable
                      onDragStart={(e) => handleDragStart(e, g.grievanceId, col.id)}
                      className="bg-white p-4 rounded-xl border border-gray-100/90 shadow-sm cursor-grab hover:shadow-md hover:border-gray-200 hover:-translate-y-0.5 active:cursor-grabbing transition-all duration-200"
                    >
                      <div className="flex items-center justify-between">
                        <span className="text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 bg-slate-100 text-slate-600 rounded-full">
                          {g.category}
                        </span>
                        <span className="text-[10px] text-gray-400 font-medium flex items-center gap-1">
                          <Calendar className="w-3 h-3" />
                          {new Date(g.submittedDate).toLocaleDateString('en-GB')}
                        </span>
                      </div>

                      <h4 className="font-semibold text-gray-800 text-xs mt-3 flex items-center gap-1.5">
                        <User className="w-3.5 h-3.5 text-gray-400" />
                        {g.workerName}
                      </h4>

                      <p className="text-xs text-gray-500 mt-1 line-clamp-3 leading-relaxed">
                        {g.description}
                      </p>

                      {col.id === 'Resolved' && g.resolvedDate && (
                        <div className="mt-3 pt-3 border-t border-gray-50 flex items-center gap-1.5 text-[11px] text-emerald-600 font-semibold">
                          <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
                          Resolved in {getGrievanceDays(g) || 0} days
                        </div>
                      )}
                    </div>
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Submit Grievance Modal */}
      {isSubmitModalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full shadow-2xl border border-gray-100 overflow-hidden transform transition-all">
            <div className="bg-emerald-950 p-6 text-white flex items-center justify-between">
              <div>
                <h3 className="font-bold text-lg flex items-center gap-2">
                  <Sparkles className="w-5 h-5 text-emerald-400" />
                  Submit Stored Grievance
                </h3>
                <p className="text-xs text-emerald-300 mt-1">Record a formal complaint from a worker</p>
              </div>
              <button 
                onClick={() => setIsSubmitModalOpen(false)}
                className="p-1.5 rounded-lg bg-white/10 hover:bg-white/20 text-white transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmitGrievance} className="p-6 space-y-4">
              {submitError && (
                <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-xs font-semibold text-red-600">
                  {submitError}
                </div>
              )}

              {/* Worker Dropdown */}
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">Worker Name</label>
                <select
                  value={selectedWorkerId}
                  onChange={(e) => setSelectedWorkerId(e.target.value)}
                  className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700"
                >
                  <option value="">Select Worker</option>
                  {workers.map((w) => (
                    <option key={w.workerId} value={w.workerId}>
                      {w.fullName} ({w.designation})
                    </option>
                  ))}
                </select>
              </div>

              {/* Category */}
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">Category</label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700"
                >
                  <option value="">Select Category</option>
                  <option value="Salary Dispute">Salary Dispute</option>
                  <option value="Overtime Violation">Overtime Violation</option>
                  <option value="Harassment">Harassment</option>
                  <option value="Safety Hazard">Safety Hazard</option>
                  <option value="Leave Rejection">Leave Rejection</option>
                  <option value="Other">Other</option>
                </select>
              </div>

              {/* Description */}
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">Grievance Description</label>
                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Details of complaint..."
                  rows="4"
                  className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700"
                />
              </div>

              <div className="flex items-center justify-end gap-3 pt-3">
                <button
                  type="button"
                  onClick={() => setIsSubmitModalOpen(false)}
                  className="px-4 py-2 border border-gray-200 text-gray-500 font-semibold text-sm rounded-xl hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-sm rounded-xl shadow-md transition-all disabled:opacity-50"
                >
                  {submitting ? 'Submitting...' : 'Submit Grievance'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
