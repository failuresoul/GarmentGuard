import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import FactoryList from './pages/FactoryList';
import FactoryDetail from './pages/FactoryDetail';

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
          
          {/* Details screen placeholder */}
          <Route path="factories/:id" element={<FactoryDetail />} />
          
          {/* Skeletons/placeholders for other navigation links */}
          <Route 
            path="workers" 
            element={
              <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                <h2 className="text-xl font-bold text-gray-900">Workers Registry</h2>
                <p className="text-gray-500 text-sm mt-1">
                  Manage worker personnel details, job roles, salary scales, and shifts.
                </p>
                <div className="mt-6 border-2 border-dashed border-gray-200 rounded-xl h-64 flex items-center justify-center text-gray-400 text-sm font-medium">
                  Workers Management System Coming Soon
                </div>
              </div>
            } 
          />
          
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

          <Route 
            path="grievances" 
            element={
              <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
                <h2 className="text-xl font-bold text-gray-900">Labor Disputes & Grievances</h2>
                <p className="text-gray-500 text-sm mt-1">
                  Track employee complaint filings, harassment claims, and union statements.
                </p>
                <div className="mt-6 border-2 border-dashed border-gray-200 rounded-xl h-64 flex items-center justify-center text-gray-400 text-sm font-medium">
                  Grievance Log and Resolution Board Coming Soon
                </div>
              </div>
            } 
          />

          {/* Catch-all redirect to factories list */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
