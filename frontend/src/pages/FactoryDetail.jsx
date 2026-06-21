import React from 'react';

/**
 * FactoryDetail Page.
 * Renders a simple mockup skeleton loader representing the detailed page of a factory.
 */
export function FactoryDetail() {
  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      {/* Title skeleton */}
      <div className="animate-pulse space-y-4">
        <div className="h-6 bg-gray-200 rounded w-1/4"></div>
        <div className="h-4 bg-gray-200 rounded w-1/2"></div>
        
        {/* Info Grid mockup */}
        <div className="grid grid-cols-3 gap-6 pt-6">
          <div className="h-24 bg-gray-100 rounded-lg"></div>
          <div className="h-24 bg-gray-100 rounded-lg"></div>
          <div className="h-24 bg-gray-100 rounded-lg"></div>
        </div>

        {/* Detailed audit list mockup */}
        <div className="space-y-2 pt-6">
          <div className="h-4 bg-gray-200 rounded w-full"></div>
          <div className="h-4 bg-gray-200 rounded w-11/12"></div>
          <div className="h-4 bg-gray-200 rounded w-4/5"></div>
        </div>
      </div>
    </div>
  );
}

export default FactoryDetail;
