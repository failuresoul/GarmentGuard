import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import FactoryList from './pages/FactoryList';
import FactoryDetail from './pages/FactoryDetail';
import GrievanceBoard from './pages/GrievanceBoard';
import WorkerForm from './pages/WorkerForm';
import SalaryProcessor from './pages/SalaryProcessor';
import Dashboard from './pages/Dashboard';
import Analytics from './pages/Analytics';
import LoginPage from './pages/LoginPage';
import BuyerDashboard from './pages/BuyerDashboard';
import WorkerPortal from './pages/WorkerPortal';
import SafetyAudits from './pages/SafetyAudits';
import ProtectedRoute from './components/ProtectedRoute';
import { AuthProvider } from './hooks/useAuth';

/**
 * Tabbed dashboard wrapper for Worker Personnel registry and Payroll operations.
 */
function WorkersDashboard() {
  const [activeTab, setActiveTab] = useState('registry');
  const [refreshKey, setRefreshKey] = useState(0);

  const handleWorkerHired = () => {
    setRefreshKey(prev => prev + 1);
    setActiveTab('registry');
  };

  return (
    <div className="space-y-6 animate-fadeIn">
      {/* Tab bar header */}
      <div className="flex gap-2 border-b border-gray-200">
        <button
          onClick={() => setActiveTab('registry')}
          className={`px-5 py-3 text-sm font-semibold border-b-2 transition-all
            ${activeTab === 'registry' 
              ? 'border-emerald-600 text-emerald-600 font-bold border-b-2' 
              : 'border-transparent text-gray-500 hover:text-gray-700'}`}
        >
          Workers Registry & Payroll
        </button>
        <button
          onClick={() => setActiveTab('hire')}
          className={`px-5 py-3 text-sm font-semibold border-b-2 transition-all
            ${activeTab === 'hire' 
              ? 'border-emerald-600 text-emerald-600 font-bold border-b-2' 
              : 'border-transparent text-gray-500 hover:text-gray-700'}`}
        >
          Hire Worker Form
        </button>
      </div>

      {/* Tab Panels */}
      <div>
        {activeTab === 'registry' ? (
          <SalaryProcessor key={refreshKey} />
        ) : (
          <WorkerForm onWorkerHired={handleWorkerHired} />
        )}
      </div>
    </div>
  );
}

/**
 * Main Application Component.
 * Sets up routing structure under React Router 6 <BrowserRouter>.
 */
export function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public login page */}
          <Route path="login" element={<LoginPage />} />

          {/* Protected buyer dashboard */}
          <Route element={<ProtectedRoute allowedRoles={['Buyer', 'Buyer_Representative', 'Admin']} />}>
            <Route path="buyer" element={<BuyerDashboard />} />
          </Route>

          {/* Protected worker portal */}
          <Route element={<ProtectedRoute allowedRoles={['Worker', 'Admin']} />}>
            <Route path="worker-portal" element={<WorkerPortal />} />
          </Route>

          {/* Protected main workspace (Compliance officers, Inspectors, Admins) */}
          <Route element={<ProtectedRoute allowedRoles={['Admin', 'Inspector', 'Compliance_Officer', 'Factory_Manager']} />}>
            <Route path="/" element={<Layout />}>
              <Route index element={<Dashboard />} />
              <Route path="factories" element={<FactoryList />} />
              <Route path="factories/:id" element={<FactoryDetail />} />
              <Route path="analytics" element={<Analytics />} />
              <Route path="workers" element={<WorkersDashboard />} />
              
              {/* Safety Audits Management */}
              <Route path="audits" element={<SafetyAudits />} />

              {/* Grievance Kanban Board */}
              <Route path="grievances" element={<GrievanceBoard />} />
            </Route>
          </Route>

          {/* Catch-all redirect to index home */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
