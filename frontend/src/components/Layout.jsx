import React, { useState, useEffect } from 'react';
import { Outlet, NavLink } from 'react-router-dom';
import { Factory, Users, ClipboardCheck, AlertTriangle, ShieldCheck, X } from 'lucide-react';

/**
 * Layout Component.
 * Contains the main sidebar layout, navigation links, and a listener to display error toasts.
 */
export function Layout() {
  const [toast, setToast] = useState(null);

  useEffect(() => {
    const handleToast = (e) => {
      setToast(e.detail);
      
      // Auto-dismiss notification after 5 seconds
      const timer = setTimeout(() => {
        setToast(null);
      }, 5000);
      return () => clearTimeout(timer);
    };

    window.addEventListener('app-toast', handleToast);
    return () => window.removeEventListener('app-toast', handleToast);
  }, []);

  const navItems = [
    { name: 'Factories', to: '/', icon: Factory },
    { name: 'Workers', to: '/workers', icon: Users },
    { name: 'Safety Audits', to: '/audits', icon: ClipboardCheck },
    { name: 'Grievances', to: '/grievances', icon: AlertTriangle }
  ];

  return (
    <div className="flex h-screen overflow-hidden bg-gray-50">
      {/* Sidebar Nav */}
      <aside className="w-64 bg-slate-900 text-white flex flex-col border-r border-slate-800 shrink-0">
        {/* Branding header */}
        <div className="h-16 px-6 flex items-center border-b border-slate-800 gap-2">
          <ShieldCheck className="w-7 h-7 text-emerald-500" />
          <span className="font-bold text-lg tracking-wider bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
            GarmentGuard
          </span>
        </div>

        {/* Navigation list */}
        <nav className="flex-1 px-4 py-6 space-y-1">
          {navItems.map((item) => (
            <NavLink
              key={item.name}
              to={item.to}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-emerald-600 text-white shadow-md'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                }`
              }
            >
              <item.icon className="w-5 h-5 shrink-0" />
              <span>{item.name}</span>
            </NavLink>
          ))}
        </nav>

        {/* Footer */}
        <div className="p-4 border-t border-slate-800 text-xs text-slate-500">
          GarmentGuard v1.0.0
          <br />
          RMG Compliance Monitor
        </div>
      </aside>

      {/* Main Viewport Container */}
      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-16 bg-white border-b border-gray-200 px-8 flex items-center justify-between shadow-sm shrink-0">
          <h1 className="text-lg font-semibold text-gray-800">Compliance & Welfare Dashboard</h1>
          <div className="text-xs text-emerald-600 font-semibold bg-emerald-50 border border-emerald-200 px-2.5 py-0.5 rounded-full">
            Bangladesh RMG Sector
          </div>
        </header>

        {/* Render child routing endpoints here */}
        <main className="flex-1 overflow-auto p-8">
          <Outlet />
        </main>
      </div>

      {/* Global Toast Notification Container */}
      {toast && (
        <div className="fixed bottom-4 right-4 z-50 max-w-sm w-full bg-white rounded-lg shadow-xl border border-gray-200 p-4 transition-all duration-300 transform translate-y-0">
          <div className="flex items-start gap-3">
            <div className="flex-1">
              <p className="text-xs font-semibold uppercase tracking-wider text-red-600">
                {toast.type === 'error' ? 'Database Alert' : 'Notification'}
              </p>
              <p className="text-sm text-gray-600 mt-1">{toast.message}</p>
            </div>
            <button
              onClick={() => setToast(null)}
              className="text-gray-400 hover:text-gray-600 transition-colors shrink-0"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default Layout;
