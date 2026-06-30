import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShieldCheck, Lock, User, AlertCircle } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!username || !password) {
      setError('Please fill in all fields.');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const user = await login(username, password);
      
      // Redirect based on role
      const role = user.role.toLowerCase();
      if (role === 'worker') {
        navigate('/worker-portal');
      } else if (role === 'buyer' || role === 'buyer_representative') {
        navigate('/buyer');
      } else {
        navigate('/');
      }
    } catch (err) {
      console.error('Login error:', err);
      const msg = err.response?.data?.error || 'Invalid credentials. Please try again.';
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col justify-center py-12 sm:px-6 lg:px-8 relative overflow-hidden">
      
      {/* Visual background accents */}
      <div className="absolute top-0 left-0 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2"></div>
      <div className="absolute bottom-0 right-0 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl translate-x-1/2 translate-y-1/2"></div>

      <div className="sm:mx-auto sm:w-full sm:max-w-md z-10">
        <div className="flex justify-center items-center gap-2.5">
          <ShieldCheck className="w-10 h-10 text-emerald-500" />
          <span className="font-extrabold text-2xl tracking-wider text-white">
            GarmentGuard
          </span>
        </div>
        <h2 className="mt-6 text-center text-3xl font-extrabold text-slate-100">
          Compliance portal
        </h2>
        <p className="mt-2 text-center text-sm text-slate-400">
          Enter credentials to access RMG registries
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md z-10">
        <div className="bg-slate-900/50 backdrop-blur-md py-8 px-4 border border-slate-800/80 shadow-2xl rounded-2xl sm:px-10">
          
          <form className="space-y-6" onSubmit={handleSubmit}>
            
            {error && (
              <div className="bg-red-500/10 border border-red-500/20 text-red-400 p-3.5 rounded-xl text-xs flex gap-2.5 items-start">
                <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                <span className="font-medium leading-relaxed">{error}</span>
              </div>
            )}

            {/* Username Input */}
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                Username
              </label>
              <div className="mt-1.5 relative rounded-md shadow-sm">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-500">
                  <User className="w-4 h-4" />
                </div>
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="e.g. sysadmin, worker1"
                  className="block w-full pl-10 pr-3.5 py-2.5 bg-slate-950/80 border border-slate-800 rounded-xl text-slate-200 placeholder-slate-600 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-sm transition-all"
                  required
                />
              </div>
            </div>

            {/* Password Input */}
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                Password
              </label>
              <div className="mt-1.5 relative rounded-md shadow-sm">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-500">
                  <Lock className="w-4 h-4" />
                </div>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="block w-full pl-10 pr-3.5 py-2.5 bg-slate-950/80 border border-slate-800 rounded-xl text-slate-200 placeholder-slate-600 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 text-sm transition-all"
                  required
                />
              </div>
            </div>

            {/* Submit Button */}
            <div>
              <button
                type="submit"
                disabled={loading}
                className="w-full flex justify-center py-3 px-4 border border-transparent rounded-xl text-sm font-semibold text-white bg-emerald-600 hover:bg-emerald-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500 transition-all disabled:opacity-50"
              >
                {loading ? 'Authenticating...' : 'Sign In'}
              </button>
            </div>
            
          </form>

          {/* Quick Info */}
          <div className="mt-6 border-t border-slate-800/80 pt-5 text-center">
            <span className="text-slate-500 text-xs font-semibold uppercase tracking-wider block mb-2">Seed Accounts Info</span>
            <div className="grid grid-cols-2 gap-2 text-[10px] text-slate-400">
              <div className="bg-slate-950/50 p-2 border border-slate-800/50 rounded-lg">
                <span className="text-emerald-400 font-bold">sysadmin</span> / password123
              </div>
              <div className="bg-slate-950/50 p-2 border border-slate-800/50 rounded-lg">
                <span className="text-emerald-400 font-bold">worker1</span> / password123
              </div>
              <div className="bg-slate-950/50 p-2 border border-slate-800/50 rounded-lg">
                <span className="text-emerald-400 font-bold">hm_buyer</span> / password123
              </div>
              <div className="bg-slate-950/50 p-2 border border-slate-800/50 rounded-lg">
                <span className="text-emerald-400 font-bold">comp_dhaka</span> / password123
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
