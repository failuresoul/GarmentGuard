import React, { useState, useEffect } from 'react';
import { 
  Building2, 
  Award, 
  Clock, 
  FileText, 
  ShieldCheck, 
  Calendar,
  ArrowRight,
  LogOut,
  X,
  CheckCircle,
  AlertCircle
} from 'lucide-react';
import api from '../api/axios';
import { useAuth } from '../hooks/useAuth';

export default function BuyerDashboard() {
  const { user, logout } = useAuth();
  const [factories, setFactories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Certifications modal/drawer state
  const [selectedFactory, setSelectedFactory] = useState(null);
  const [certs, setCerts] = useState([]);
  const [loadingCerts, setLoadingCerts] = useState(false);

  useEffect(() => {
    if (!user || !user.buyerId) return;

    async function loadBuyerFactories() {
      try {
        setLoading(true);
        const res = await api.get(`/api/buyer/factories/${user.buyerId}`);
        setFactories(res.data || []);
      } catch (err) {
        console.error('Failed to load buyer factories:', err);
        setError('Failed to retrieve factory compliance data.');
      } finally {
        setLoading(false);
      }
    }
    loadBuyerFactories();
  }, [user]);

  const handleOpenCerts = async (factory) => {
    setSelectedFactory(factory);
    try {
      setLoadingCerts(true);
      const res = await api.get(`/api/buyer/factory/${factory.factoryId}/certifications`);
      setCerts(res.data || []);
    } catch (err) {
      console.error('Failed to load certifications:', err);
      setCerts([]);
    } finally {
      setLoadingCerts(false);
    }
  };

  const handleCloseCerts = () => {
    setSelectedFactory(null);
    setCerts([]);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-emerald-500"></div>
        <span className="ml-3 text-sm text-slate-400 font-medium">Loading Buyer Compliance Panel...</span>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col relative overflow-hidden">
      
      {/* Top Background Accents */}
      <div className="absolute top-0 left-1/4 w-96 h-96 bg-emerald-500/5 rounded-full blur-3xl -translate-y-1/2"></div>

      {/* Header Banner */}
      <header className="border-b border-slate-900 bg-slate-950/80 backdrop-blur-md sticky top-0 z-20 px-8 py-4 flex items-center justify-between shrink-0">
        <div className="flex items-center gap-3">
          <ShieldCheck className="w-8 h-8 text-emerald-500" />
          <div>
            <h1 className="font-extrabold text-lg tracking-wider text-white">GarmentGuard</h1>
            <p className="text-[10px] text-emerald-500 font-bold uppercase tracking-widest">Buyer Sourcing Panel</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="text-right hidden sm:block">
            <p className="text-xs text-slate-400 font-semibold">Welcome, {user?.fullName || 'Buyer representative'}</p>
            <span className="text-[10px] text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-2 py-0.5 rounded-full font-bold">
              International Partner
            </span>
          </div>
          <button
            onClick={logout}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-slate-400 hover:text-red-400 hover:bg-red-500/10 transition-all border border-slate-800"
          >
            <LogOut className="w-3.5 h-3.5" /> Sign Out
          </button>
        </div>
      </header>

      {/* Main Sourcing Area */}
      <main className="flex-1 p-8 overflow-auto max-w-7xl mx-auto w-full space-y-8 z-10">
        
        {/* Brand Hero Banner */}
        <div className="bg-gradient-to-r from-slate-900 via-slate-900 to-slate-950 border border-slate-800/80 rounded-2xl p-6 sm:p-8 shadow-xl flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div className="space-y-1">
            <span className="text-[10px] font-bold text-emerald-500 uppercase tracking-widest">Certified Portfolio</span>
            <h2 className="text-2xl font-bold text-slate-100">Global Supply Chain Compliance</h2>
            <p className="text-xs text-slate-400 leading-relaxed max-w-xl">
              Inspect live compliance statuses, safety credentials, and certification records for all garment factories in your supply chain contract.
            </p>
          </div>
          <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-xl px-5 py-4 text-center sm:text-right shrink-0">
            <span className="block text-[10px] font-bold uppercase text-slate-400 tracking-wider">Contracted Units</span>
            <h4 className="text-2xl font-extrabold text-white">{factories.length} Factories</h4>
          </div>
        </div>

        {error && (
          <div className="bg-red-500/10 border border-red-500/20 text-red-400 p-4 rounded-xl text-sm flex gap-2">
            <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* Factory Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {factories.map((f) => {
            const score = f.complianceScore || 0;
            const status = f.complianceStatus;
            
            return (
              <div 
                key={f.factoryId} 
                className="bg-slate-900/40 border border-slate-800/80 rounded-2xl p-6 hover:border-slate-700/60 shadow-md hover:shadow-lg transition-all flex flex-col justify-between group relative"
              >
                {/* Score badge top-right */}
                <div className="absolute top-6 right-6 text-right">
                  <span className="text-[10px] uppercase font-bold text-slate-500 tracking-widest block mb-0.5">Score</span>
                  <span className={`text-lg font-black px-2.5 py-0.5 rounded-lg ${
                    score >= 75 ? 'text-emerald-400 bg-emerald-400/10 border border-emerald-400/20' :
                    score >= 50 ? 'text-amber-400 bg-amber-400/10 border border-amber-400/20' : 'text-red-400 bg-red-400/10 border border-red-400/20'
                  }`}>
                    {score.toFixed(1)}
                  </span>
                </div>

                <div className="space-y-4">
                  
                  {/* Status Indicator */}
                  <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold border ${
                    status === 'Compliant' ? 'bg-emerald-400/10 text-emerald-400 border-emerald-400/20' :
                    status === 'Partially Compliant' || status === 'Pending' ? 'bg-amber-400/10 text-amber-400 border-amber-400/20' : 'bg-red-400/10 text-red-400 border-red-400/20'
                  }`}>
                    <span className={`w-1.5 h-1.5 rounded-full ${
                      status === 'Compliant' ? 'bg-emerald-400' :
                      status === 'Partially Compliant' || status === 'Pending' ? 'bg-amber-400' : 'bg-red-400'
                    }`} />
                    {status}
                  </span>

                  {/* Title & Address */}
                  <div>
                    <h3 className="text-base font-extrabold text-white group-hover:text-emerald-400 transition-colors">
                      {f.factoryName}
                    </h3>
                    <p className="text-xs text-slate-500 mt-1">{f.address}, {f.district}</p>
                  </div>

                  {/* Compliance Stats Info Grid */}
                  <div className="grid grid-cols-2 gap-4 py-3 border-t border-b border-slate-800/80 text-xs">
                    <div className="space-y-1">
                      <span className="text-[10px] text-slate-500 uppercase font-semibold">Last Audit</span>
                      <p className="font-bold text-slate-200 flex items-center gap-1">
                        <Clock className="w-3.5 h-3.5 text-slate-500" />
                        {f.latestAuditScore !== null ? `${f.latestAuditScore} / 100` : 'N/A'}
                      </p>
                    </div>
                    <div className="space-y-1">
                      <span className="text-[10px] text-slate-500 uppercase font-semibold">Active Certs</span>
                      <p className="font-bold text-slate-200 flex items-center gap-1">
                        <Award className="w-3.5 h-3.5 text-emerald-500" />
                        {f.activeCertsCount}
                      </p>
                    </div>
                  </div>

                  {/* Contract status */}
                  <div className="flex justify-between items-center text-xs text-slate-400">
                    <span>Sourcing Since: <span className="text-slate-300 font-bold">{f.sinceDate}</span></span>
                    <span className={`px-2 py-0.5 rounded font-bold ${
                      f.contractStatus === 'Active' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'
                    }`}>
                      {f.contractStatus}
                    </span>
                  </div>

                </div>

                {/* Open Certifications Drawer Button */}
                <button
                  onClick={() => handleOpenCerts(f)}
                  className="w-full mt-5 flex items-center justify-center gap-1.5 py-2.5 px-4 rounded-xl text-xs font-semibold text-slate-200 bg-slate-800 hover:bg-slate-700/80 hover:text-white transition-all border border-slate-700/50"
                >
                  View Certificates <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            );
          })}
        </div>

      </main>

      {/* Footer */}
      <footer className="py-6 border-t border-slate-900 text-center text-xs text-slate-600 shrink-0 z-10">
        GarmentGuard read-only buyer portal. Data updates dynamically on audit completion.
      </footer>

      {/* ── CERTIFICATIONS MODAL/DRAWER ────────────────────────────────────── */}
      {selectedFactory && (
        <div className="fixed inset-0 z-50 overflow-hidden flex items-center justify-end bg-black/60 backdrop-blur-sm animate-fadeIn">
          
          <div className="w-full max-w-md h-full bg-slate-900 border-l border-slate-800/80 shadow-2xl p-8 flex flex-col justify-between overflow-y-auto">
            
            <div className="space-y-6">
              {/* Header */}
              <div className="flex justify-between items-start border-b border-slate-800 pb-5">
                <div>
                  <span className="text-[10px] font-bold uppercase text-emerald-500 tracking-wider">Certifications</span>
                  <h3 className="text-lg font-bold text-white mt-1">{selectedFactory.factoryName}</h3>
                  <p className="text-xs text-slate-500 mt-1">{selectedFactory.address}</p>
                </div>
                <button 
                  onClick={handleCloseCerts}
                  className="p-1 rounded-lg text-slate-500 hover:text-white hover:bg-slate-800 transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Certifications List */}
              <div className="space-y-4">
                {loadingCerts ? (
                  <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-500"></div>
                  </div>
                ) : certs.length > 0 ? (
                  certs.map((c) => (
                    <div key={c.certId} className="bg-slate-950/80 border border-slate-800 p-4 rounded-xl flex gap-3.5 items-start">
                      <div className="p-2.5 bg-slate-900 border border-slate-800 rounded-lg text-emerald-500">
                        <FileText className="w-5 h-5" />
                      </div>
                      <div className="space-y-1 flex-1">
                        <div className="flex items-center justify-between">
                          <h4 className="text-xs font-bold text-slate-200">{c.certName}</h4>
                          <span className={`px-1.5 py-0.5 rounded text-[8px] font-bold ${
                            c.status === 'Active' ? 'bg-emerald-400/10 text-emerald-400' :
                            c.status === 'Expired' ? 'bg-red-400/10 text-red-400' : 'bg-slate-800 text-slate-400'
                          }`}>
                            {c.status}
                          </span>
                        </div>
                        <p className="text-[10px] text-slate-500">{c.issuingBody}</p>
                        
                        <div className="grid grid-cols-2 gap-2 pt-2 text-[9px] text-slate-400 font-semibold">
                          <span className="flex items-center gap-1"><Calendar className="w-3 h-3 text-slate-600" /> Issued: {c.issueDate}</span>
                          <span className="flex items-center gap-1"><Clock className="w-3 h-3 text-slate-600" /> Expires: {c.expiryDate}</span>
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="text-center py-12 border-2 border-dashed border-slate-800 rounded-xl">
                    <Award className="w-8 h-8 text-slate-700 mx-auto mb-2" />
                    <p className="text-xs text-slate-500">No certification records registered.</p>
                  </div>
                )}
              </div>
            </div>

            {/* Bottom info banner */}
            <div className="bg-slate-950 p-4 rounded-xl border border-slate-800/80 flex gap-2.5 items-start mt-8">
              <CheckCircle className="w-4 h-4 text-emerald-500 shrink-0 mt-0.5" />
              <p className="text-[10px] leading-relaxed text-slate-500">
                All certification dates and statuses are certified and verified by independent international accrediting bodies.
              </p>
            </div>

          </div>
        </div>
      )}

    </div>
  );
}
