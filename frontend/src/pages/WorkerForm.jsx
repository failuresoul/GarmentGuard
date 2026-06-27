import React, { useState, useEffect } from 'react';
import api from '../api/axios';
import { useFactories } from '../hooks/useFactories';
import { UserPlus, Sparkles, Building, Briefcase, Calendar, DollarSign, Clock } from 'lucide-react';

export default function WorkerForm({ onWorkerHired }) {
  const { factories, loading: loadingFactories } = useFactories();
  
  const [factoryId, setFactoryId] = useState('');
  const [fullName, setFullName] = useState('');
  const [nationalId, setNationalId] = useState('');
  const [designation, setDesignation] = useState('');
  const [joinDate, setJoinDate] = useState(new Date().toISOString().split('T')[0]);
  const [baseSalary, setBaseSalary] = useState('');
  const [shift, setShift] = useState('Morning');
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Auto-select first factory when loaded
  useEffect(() => {
    if (factories && factories.length > 0 && !factoryId) {
      setFactoryId(factories[0].factoryId || factories[0].FACTORY_ID);
    }
  }, [factories, factoryId]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!factoryId || !fullName || !nationalId || !designation || !joinDate || !baseSalary || !shift) {
      setError('Please fill in all required fields.');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      // Use config options to suppress the global toast so we can display a custom one
      const response = await api.post('/api/workers', {
        factoryId: parseInt(factoryId, 10),
        fullName,
        nationalId,
        designation,
        joinDate,
        baseSalary: parseFloat(baseSalary),
        shift,
        status: 'Active'
      }, { suppressToast: true });

      setSuccess(`Successfully hired ${fullName} (Worker ID: ${response.data.workerId}).`);
      
      // Clear form except factory select and date
      setFullName('');
      setNationalId('');
      setDesignation('');
      setBaseSalary('');
      setShift('Morning');

      // Notify parent if callback provided
      if (onWorkerHired) {
        onWorkerHired();
      }

      // Dispatch success toast
      window.dispatchEvent(new CustomEvent('app-toast', {
        detail: { type: 'success', message: 'Worker registered successfully!' }
      }));

    } catch (err) {
      const code = err.response?.data?.error?.code;
      const dbMessage = err.response?.data?.error?.message;
      
      if (code === 'FACTORY_INACTIVE') {
        // Dispatch special custom toast for FACTORY_INACTIVE (-20001)
        window.dispatchEvent(new CustomEvent('app-toast', {
          detail: { type: 'error', message: 'Factory must be Active to hire workers' }
        }));
        setError('Factory must be Active to hire workers.');
      } else {
        setError(dbMessage || 'Failed to hire worker.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto bg-white rounded-2xl border border-gray-100 p-6 shadow-sm">
      <div className="mb-6 flex items-center gap-3">
        <div className="w-10 h-10 bg-emerald-50 text-emerald-600 rounded-xl flex items-center justify-center">
          <UserPlus className="w-5 h-5" />
        </div>
        <div>
          <h3 className="text-lg font-bold text-gray-900 flex items-center gap-1.5">
            Hire New Factory Worker
          </h3>
          <p className="text-xs text-gray-400 font-semibold uppercase tracking-wider">
            Register personnel and generate workforce assignments
          </p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-5">
        {error && (
          <div className="p-3.5 bg-red-50 border border-red-200 text-red-600 text-xs font-bold rounded-xl animate-shake">
            {error}
          </div>
        )}

        {success && (
          <div className="p-3.5 bg-emerald-50 border border-emerald-100 text-emerald-700 text-xs font-bold rounded-xl">
            {success}
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          {/* Factory */}
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5 flex items-center gap-1">
              <Building className="w-3.5 h-3.5" />
              Factory Assignment
            </label>
            <select
              value={factoryId}
              onChange={(e) => setFactoryId(e.target.value)}
              className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700 font-medium"
            >
              {loadingFactories ? (
                <option>Loading factories...</option>
              ) : (
                factories.map(fac => (
                  <option key={fac.factoryId || fac.FACTORY_ID} value={fac.factoryId || fac.FACTORY_ID}>
                    {fac.name} ({fac.complianceStatus})
                  </option>
                ))
              )}
            </select>
          </div>

          {/* Full Name */}
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5 flex items-center gap-1">
              <Sparkles className="w-3.5 h-3.5" />
              Full Name
            </label>
            <input
              type="text"
              placeholder="e.g. Abul Kashem"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700 placeholder:text-gray-400"
            />
          </div>

          {/* National ID */}
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5 flex items-center gap-1">
              National ID / NID
            </label>
            <input
              type="text"
              placeholder="e.g. NID-45678"
              value={nationalId}
              onChange={(e) => setNationalId(e.target.value)}
              className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700 placeholder:text-gray-400"
            />
          </div>

          {/* Designation */}
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5 flex items-center gap-1">
              <Briefcase className="w-3.5 h-3.5" />
              Designation
            </label>
            <input
              type="text"
              placeholder="e.g. Sewing Operator, Line Supervisor"
              value={designation}
              onChange={(e) => setDesignation(e.target.value)}
              className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700 placeholder:text-gray-400"
            />
          </div>

          {/* Join Date */}
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5 flex items-center gap-1">
              <Calendar className="w-3.5 h-3.5" />
              Join Date
            </label>
            <input
              type="date"
              value={joinDate}
              onChange={(e) => setJoinDate(e.target.value)}
              className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700"
            />
          </div>

          {/* Base Salary */}
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5 flex items-center gap-1">
              <DollarSign className="w-3.5 h-3.5" />
              Base Salary (BDT)
            </label>
            <input
              type="number"
              placeholder="e.g. 12500"
              value={baseSalary}
              onChange={(e) => setBaseSalary(e.target.value)}
              className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700 placeholder:text-gray-400 font-mono"
            />
          </div>

          {/* Shift */}
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5 flex items-center gap-1">
              <Clock className="w-3.5 h-3.5" />
              Shift Schedule
            </label>
            <select
              value={shift}
              onChange={(e) => setShift(e.target.value)}
              className="w-full text-sm bg-gray-50 border border-gray-200 rounded-xl px-3.5 py-2.5 outline-none focus:bg-white focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all text-gray-700 font-medium"
            >
              <option value="Morning">Morning</option>
              <option value="Evening">Evening</option>
              <option value="Night">Night</option>
              <option value="Day">Day</option>
              <option value="Roster">Roster</option>
            </select>
          </div>
        </div>

        <div className="pt-3 flex justify-end">
          <button
            type="submit"
            disabled={loading}
            className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm px-6 py-2.5 rounded-xl shadow-md transition-all hover:-translate-y-0.5 disabled:opacity-50 flex items-center gap-2"
          >
            {loading ? 'Hiring...' : 'Hire & Register Worker'}
          </button>
        </div>
      </form>
    </div>
  );
}
