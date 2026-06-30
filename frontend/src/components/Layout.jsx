import React, { useState, useEffect } from 'react';
import { Outlet, NavLink, useLocation } from 'react-router-dom';
import { LayoutDashboard, Factory, BarChart3, Users, ClipboardCheck, AlertTriangle, ShieldCheck, X, Menu } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';

/**
 * Layout Component.
 * Contains the main sidebar layout, navigation links, and a listener to display error toasts.
 * Responsive: sidebar collapses behind a hamburger on mobile.
 */
export function Layout() {
  const location = useLocation();
  const { user } = useAuth();
  const [toast, setToast] = useState(null);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  // Close mobile sidebar on route change
  useEffect(() => {
    setSidebarOpen(false);
  }, [location.pathname]);

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
    { name: 'Dashboard', to: '/', icon: LayoutDashboard },
    { name: 'Factories', to: '/factories', icon: Factory },
    { name: 'Analytics', to: '/analytics', icon: BarChart3 },
    { name: 'Workers', to: '/workers', icon: Users },
    { name: 'Safety Audits', to: '/audits', icon: ClipboardCheck },
    { name: 'Grievances', to: '/grievances', icon: AlertTriangle }
  ];

  const SidebarContent = () => (
    <>
      {/* Branding header */}
      <div className="h-16 px-6 flex items-center border-b border-slate-800 gap-2 shrink-0">
        <ShieldCheck className="w-7 h-7 text-emerald-500" />
        <span className="font-bold text-lg tracking-wider bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
          GarmentGuard
        </span>
        {/* Close button visible only on mobile */}
        <button 
          onClick={() => setSidebarOpen(false)}
          className="ml-auto md:hidden text-slate-400 hover:text-white transition-colors"
        >
          <X className="w-5 h-5" />
        </button>
      </div>

      {/* Navigation list */}
      <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
        {navItems.map((item) => {
          const isActive = item.to === '/'
            ? location.pathname === '/'
            : location.pathname.startsWith(item.to);
          return (
            <NavLink
              key={item.name}
              to={item.to}
              className={`flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-emerald-600 text-white shadow-md'
                  : 'text-slate-400 hover:bg-slate-800 hover:text-white'
              }`}
            >
              <item.icon className="w-5 h-5 shrink-0" />
              <span>{item.name}</span>
            </NavLink>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-slate-800 text-xs text-slate-500 shrink-0">
        GarmentGuard v1.0.0
        <br />
        RMG Compliance Monitor
      </div>
    </>
  );

  return (
    <div className="flex h-screen overflow-hidden bg-gray-50">
      {/* ── MOBILE SIDEBAR OVERLAY ───────────────────────────────── */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm md:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* ── MOBILE SIDEBAR (slides in) ───────────────────────────── */}
      <aside className={`
        fixed inset-y-0 left-0 z-50 w-64 bg-slate-900 text-white flex flex-col
        transform transition-transform duration-300 ease-in-out
        md:hidden
        ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <SidebarContent />
      </aside>

      {/* ── DESKTOP SIDEBAR (always visible) ─────────────────────── */}
      <aside className="hidden md:flex w-64 bg-slate-900 text-white flex-col border-r border-slate-800 shrink-0">
        <SidebarContent />
      </aside>

      {/* Main Viewport Container */}
      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-16 bg-white border-b border-gray-200 px-4 md:px-8 flex items-center justify-between shadow-sm shrink-0 gap-3">
          {/* Hamburger for mobile */}
          <button 
            onClick={() => setSidebarOpen(true)} 
            className="md:hidden text-gray-600 hover:text-gray-900 transition-colors p-1"
          >
            <Menu className="w-6 h-6" />
          </button>

          <h1 className="text-base md:text-lg font-semibold text-gray-800 truncate">Compliance & Welfare Dashboard</h1>
          
          <div className="flex items-center gap-3 shrink-0">
            {user && (
              <span className="hidden sm:inline-flex text-xs text-slate-500 font-medium bg-slate-100 border border-slate-200 px-2.5 py-1 rounded-full truncate max-w-[160px]">
                {user.fullName} ({user.role.replace(/_/g, ' ')})
              </span>
            )}
            <div className="text-xs text-emerald-600 font-semibold bg-emerald-50 border border-emerald-200 px-2.5 py-0.5 rounded-full whitespace-nowrap">
              Bangladesh RMG
            </div>
          </div>
        </header>

        {/* Render child routing endpoints here */}
        <main className="flex-1 overflow-auto p-4 md:p-8">
          <Outlet />
        </main>
      </div>

      {/* Global Toast Notification Container */}
      {toast && (
        <div className="fixed bottom-4 right-4 z-50 max-w-sm w-full bg-white rounded-lg shadow-xl border border-gray-200 p-4 transition-all duration-300 transform translate-y-0 animate-scaleIn">
          <div className="flex items-start gap-3">
            <div className="flex-1">
              <p className={`text-xs font-semibold uppercase tracking-wider ${toast.type === 'error' ? 'text-red-600' : 'text-emerald-600'}`}>
                {toast.type === 'error' ? 'Database Alert' : 'Success'}
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
