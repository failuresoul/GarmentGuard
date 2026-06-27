import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import FactoryList from './pages/FactoryList';
import FactoryDetail from './pages/FactoryDetail';
import GrievanceBoard from './pages/GrievanceBoard';
import WorkerForm from './pages/WorkerForm';
import SalaryProcessor from './pages/SalaryProcessor';

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
    <div className="space-y-6">
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
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          {/* Default dashboard home displays factories */}
          <Route index element={<FactoryList />} />
          
          {/* Details screen */}
          <Route path="factories/:id" element={<FactoryDetail />} />
          
          {/* Workers tab wrapper */}
          <Route path="workers" element={<WorkersDashboard />} />
          
          {/* Audits coming soon skeleton */}
          <Route 
            path="audits" 
            element={
              <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                <h2 className="text-xl font-bold text-gray-900">Safety Audits Management</h2>
                <p className="text-gray-500 text-sm mt-1">
                  Schedule and record safety reviews, fire safety equipment, and structural tests.
                </p>
                <div className="mt-6 border-2 border-dashed border-gray-200 rounded-xl h-64 flex items-center justify-center text-gray-400 text-sm font-medium">
                  Audits Registry and Assessment System Coming Soon
                </div>
              </div>
            } 
          />

          {/* Grievance Kanban Board */}
          <Route path="grievances" element={<GrievanceBoard />} />

          {/* Catch-all redirect to factories list */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
