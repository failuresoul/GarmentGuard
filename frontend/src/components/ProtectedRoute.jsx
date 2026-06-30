import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export default function ProtectedRoute({ allowedRoles }) {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-emerald-600"></div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  const userRole = user.role.toLowerCase();
  const hasRole = allowedRoles.map(r => r.toLowerCase().replace(/_/g, '')).some(role => {
    const cleanUserRole = userRole.replace(/_/g, '');
    return (
      cleanUserRole === role ||
      (role === 'buyer' && cleanUserRole === 'buyerrepresentative') ||
      (role === 'buyerrepresentative' && cleanUserRole === 'buyer') ||
      (role === 'admin' && cleanUserRole === 'sysadmin')
    );
  });

  if (!hasRole) {
    // Redirect unauthorized users to their correct landing page
    if (userRole === 'worker') {
      return <Navigate to="/worker-portal" replace />;
    }
    if (userRole === 'buyer' || userRole === 'buyer_representative') {
      return <Navigate to="/buyer" replace />;
    }
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
}
