import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useFactories } from '../hooks/useFactories';
import { ComplianceBadge } from '../components/ComplianceBadge';
import api from '../api/axios';
import { Plus, RotateCw, X, AlertCircle, Users, Mail, Phone, MapPin, Building, Clipboard, ArrowRight } from 'lucide-react';

/**
 * FactoryList Page Component.
 * Fetches and displays garment factories, their compliance score, and audit statuses.
 * Includes a slide-over panel to register new factories.
 */
export function FactoryList() {
  const navigate = useNavigate();
  const { factories, loading, error, fetchFactories } = useFactories();
  const [isSlideOverOpen, setIsSlideOverOpen] = useState(false);
  
  // Controlled Form State
  const [formData, setFormData] = useState({
    name: '',
    registrationNo: '',
    address: '',
    district: '',
    totalWorkers: '',
    contactPerson: '',
    phone: '',
    email: ''
  });
  
  const [formErrors, setFormErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);

  // Validate form fields on the client side
  const validateForm = () => {
    const errors = {};
    if (!formData.name.trim()) errors.name = 'Factory name is required';
    if (!formData.registrationNo.trim()) errors.registrationNo = 'Registration number is required';
    if (!formData.address.trim()) errors.address = 'Address is required';
    if (!formData.district.trim()) errors.district = 'District is required';
    if (formData.totalWorkers && parseInt(formData.totalWorkers, 10) < 0) {
      errors.totalWorkers = 'Total workers cannot be negative';
    }
    if (!formData.contactPerson.trim()) errors.contactPerson = 'Contact person is required';
    if (!formData.phone.trim()) errors.phone = 'Phone number is required';
    if (!formData.email.trim()) {
      errors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      errors.email = 'Email format is invalid';
    }
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    // Clear validation error when user types
    if (formErrors[name]) {
      setFormErrors((prev) => ({ ...prev, [name]: '' }));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    setSubmitting(true);
    try {
      await api.post('/api/factories', {
        name: formData.name,
        registrationNo: formData.registrationNo,
        address: formData.address,
        district: formData.district,
        totalWorkers: formData.totalWorkers ? parseInt(formData.totalWorkers, 10) : 0,
        contactPerson: formData.contactPerson,
        phone: formData.phone,
        email: formData.email
      });

      // Show success toast-like signal
      window.dispatchEvent(new CustomEvent('app-toast', {
        detail: { type: 'success', message: 'Factory registered successfully!' }
      }));

      // Reset Form & Close Slide-over
      setFormData({
        name: '',
        registrationNo: '',
        address: '',
        district: '',
        totalWorkers: '',
        contactPerson: '',
        phone: '',
        email: ''
      });
      setFormErrors({});
      setIsSlideOverOpen(false);

      // Reload factories list
      fetchFactories();
    } catch (err) {
      console.error('Error submitting factory registration:', err);
    } finally {
      setSubmitting(false);
    }
  };

  // Helper to render score color-coded gauge bar
  const renderScoreGauge = (score) => {
    if (score === null || score === undefined) {
      return (
        <div className="flex items-center gap-2">
          <div className="w-24 h-2 bg-gray-200 rounded-full overflow-hidden"></div>
          <span className="text-xs text-gray-400">N/A</span>
        </div>
      );
    }

    const numericScore = parseFloat(score);
    let barColor = 'bg-red-500';
    let textColor = 'text-red-600';

    if (numericScore >= 75) {
      barColor = 'bg-green-500';
      textColor = 'text-green-600';
    } else if (numericScore >= 40) {
      barColor = 'bg-amber-500';
      textColor = 'text-amber-600';
    }

    return (
      <div className="flex flex-col gap-1 w-28">
        <div className="flex items-center justify-between text-xs font-semibold">
          <span className={`${textColor}`}>{numericScore}%</span>
        </div>
        <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
          <div 
            className={`h-full ${barColor} transition-all duration-500`}
            style={{ width: `${Math.min(numericScore, 100)}%` }}
          ></div>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header section */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">RMG Factories</h2>
          <p className="text-sm text-gray-500 mt-1">
            Monitor and manage compliance, worker count, safety statuses and audits.
          </p>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <button
            onClick={fetchFactories}
            disabled={loading}
            className="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-emerald-500 disabled:opacity-50 transition-colors"
          >
            <RotateCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
          <button
            onClick={() => setIsSlideOverOpen(true)}
            className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-white bg-emerald-600 border border-transparent rounded-lg hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 shadow-sm transition-colors"
          >
            <Plus className="w-4 h-4" />
            Register Factory
          </button>
        </div>
      </div>

      {/* Error state alert */}
      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 rounded-lg flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
          <div className="flex-1">
            <h3 className="text-sm font-bold text-red-800">Connection Failed</h3>
            <p className="text-xs text-red-700 mt-1">{error}</p>
            <button
              onClick={fetchFactories}
              className="text-xs font-semibold text-red-600 hover:text-red-800 underline mt-2"
            >
              Click here to retry connection
            </button>
          </div>
        </div>
      )}

      {/* Main factories table */}
      {!error && (
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200 text-left text-sm">
              <thead className="bg-gray-50 text-xs text-gray-500 uppercase tracking-wider">
                <tr>
                  <th className="px-6 py-3 font-semibold">Factory Name</th>
                  <th className="px-6 py-3 font-semibold">District</th>
                  <th className="px-6 py-3 font-semibold">Compliance Score</th>
                  <th className="px-6 py-3 font-semibold">Status</th>
                  <th className="px-6 py-3 font-semibold">Open Grievances</th>
                  <th className="px-6 py-3 font-semibold">Workers</th>
                  <th className="px-6 py-3 font-semibold">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 text-gray-700">
                {loading ? (
                  // Skeleton loader rows
                  Array.from({ length: 5 }).map((_, idx) => (
                    <tr key={idx} className="animate-pulse">
                      <td className="px-6 py-4">
                        <div className="h-4 bg-gray-200 rounded w-40"></div>
                        <div className="h-3 bg-gray-200 rounded w-24 mt-2"></div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="h-4 bg-gray-200 rounded w-16"></div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="h-4 bg-gray-200 rounded w-24"></div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="h-6 bg-gray-200 rounded w-20"></div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="h-4 bg-gray-200 rounded w-12 mx-auto"></div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="h-4 bg-gray-200 rounded w-16"></div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="h-4 bg-gray-200 rounded w-12"></div>
                      </td>
                    </tr>
                  ))
                ) : factories.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="px-6 py-12 text-center text-gray-500">
                      <Building className="w-10 h-10 text-gray-300 mx-auto mb-2" />
                      <p className="font-semibold text-gray-600">No Factories Registered</p>
                      <p className="text-xs text-gray-400 mt-1">Get started by clicking the "Register Factory" button.</p>
                    </td>
                  </tr>
                ) : (
                  factories.map((factory) => (
                    <tr key={factory.factoryId} className="hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-4">
                        <div className="font-bold text-gray-900">{factory.name}</div>
                        <div className="text-xs text-gray-500 mt-0.5">{factory.registrationNo}</div>
                      </td>
                      <td className="px-6 py-4 text-gray-600">{factory.district}</td>
                      <td className="px-6 py-4">
                        {renderScoreGauge(factory.latestAuditScore ?? factory.complianceScore)}
                      </td>
                      <td className="px-6 py-4">
                        <ComplianceBadge 
                          score={factory.latestAuditScore ?? factory.complianceScore} 
                          status={factory.complianceStatus} 
                        />
                      </td>
                      <td className="px-6 py-4 text-center">
                        {factory.openGrievancesCount > 0 ? (
                          <span className="inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-red-100 bg-red-600 rounded-full">
                            {factory.openGrievancesCount}
                          </span>
                        ) : (
                          <span className="text-xs text-gray-400">0</span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-gray-600 font-medium">
                        {factory.totalWorkers.toLocaleString()}
                      </td>
                      <td className="px-6 py-4">
                        <button
                          onClick={() => navigate(`/factories/${factory.factoryId}`)}
                          className="text-xs font-bold text-emerald-600 hover:text-emerald-700 inline-flex items-center gap-0.5 hover:underline"
                        >
                          View details
                          <ArrowRight className="w-3.5 h-3.5" />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Slide-over Panel for factory registration */}
      {isSlideOverOpen && (
        <div className="fixed inset-0 z-50 overflow-hidden">
          {/* Backdrop overlay */}
          <div 
            onClick={() => setIsSlideOverOpen(false)}
            className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity duration-300"
          ></div>

          <div className="absolute inset-y-0 right-0 max-w-full flex pl-10">
            {/* Panel */}
            <div className="w-screen max-w-md bg-white shadow-2xl flex flex-col h-full transform transition-transform duration-300">
              {/* Slide-over header */}
              <div className="h-16 px-6 bg-slate-900 text-white flex items-center justify-between border-b border-slate-800 shrink-0">
                <div className="flex items-center gap-2">
                  <Building className="w-5 h-5 text-emerald-500" />
                  <h3 className="font-bold text-lg">Register RMG Factory</h3>
                </div>
                <button 
                  onClick={() => setIsSlideOverOpen(false)}
                  className="text-slate-400 hover:text-white transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Form Content */}
              <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-5">
                {/* Factory Name */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700">Factory Name *</label>
                  <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    placeholder="e.g. Ashulia Fashion Ltd."
                    className={`mt-1.5 block w-full px-3 py-2 border rounded-lg text-sm shadow-sm focus:outline-none focus:ring-1 ${
                      formErrors.name 
                        ? 'border-red-300 focus:ring-red-500 focus:border-red-500' 
                        : 'border-gray-300 focus:ring-emerald-500 focus:border-emerald-500'
                    }`}
                  />
                  {formErrors.name && <p className="text-xs text-red-500 mt-1">{formErrors.name}</p>}
                </div>

                {/* Registration Number */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700">Registration Number *</label>
                  <input
                    type="text"
                    name="registrationNo"
                    value={formData.registrationNo}
                    onChange={handleInputChange}
                    placeholder="e.g. REG-DHA-101"
                    className={`mt-1.5 block w-full px-3 py-2 border rounded-lg text-sm shadow-sm focus:outline-none focus:ring-1 ${
                      formErrors.registrationNo 
                        ? 'border-red-300 focus:ring-red-500 focus:border-red-500' 
                        : 'border-gray-300 focus:ring-emerald-500 focus:border-emerald-500'
                    }`}
                  />
                  {formErrors.registrationNo && <p className="text-xs text-red-500 mt-1">{formErrors.registrationNo}</p>}
                </div>

                <div className="grid grid-cols-2 gap-4">
                  {/* District */}
                  <div>
                    <label className="block text-sm font-semibold text-gray-700">District *</label>
                    <input
                      type="text"
                      name="district"
                      value={formData.district}
                      onChange={handleInputChange}
                      placeholder="e.g. Dhaka"
                      className={`mt-1.5 block w-full px-3 py-2 border rounded-lg text-sm shadow-sm focus:outline-none focus:ring-1 ${
                        formErrors.district 
                          ? 'border-red-300 focus:ring-red-500 focus:border-red-500' 
                          : 'border-gray-300 focus:ring-emerald-500 focus:border-emerald-500'
                      }`}
                    />
                    {formErrors.district && <p className="text-xs text-red-500 mt-1">{formErrors.district}</p>}
                  </div>

                  {/* Total Workers */}
                  <div>
                    <label className="block text-sm font-semibold text-gray-700">Initial Workers</label>
                    <input
                      type="number"
                      name="totalWorkers"
                      value={formData.totalWorkers}
                      onChange={handleInputChange}
                      placeholder="0"
                      min="0"
                      className={`mt-1.5 block w-full px-3 py-2 border rounded-lg text-sm shadow-sm focus:outline-none focus:ring-1 ${
                        formErrors.totalWorkers 
                          ? 'border-red-300 focus:ring-red-500 focus:border-red-500' 
                          : 'border-gray-300 focus:ring-emerald-500 focus:border-emerald-500'
                      }`}
                    />
                    {formErrors.totalWorkers && <p className="text-xs text-red-500 mt-1">{formErrors.totalWorkers}</p>}
                  </div>
                </div>

                {/* Address */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700">Address *</label>
                  <textarea
                    name="address"
                    value={formData.address}
                    onChange={handleInputChange}
                    placeholder="Factory street address details..."
                    rows="2"
                    className={`mt-1.5 block w-full px-3 py-2 border rounded-lg text-sm shadow-sm focus:outline-none focus:ring-1 ${
                      formErrors.address 
                        ? 'border-red-300 focus:ring-red-500 focus:border-red-500' 
                        : 'border-gray-300 focus:ring-emerald-500 focus:border-emerald-500'
                    }`}
                  ></textarea>
                  {formErrors.address && <p className="text-xs text-red-500 mt-1">{formErrors.address}</p>}
                </div>

                {/* Contact Person */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700">Contact Person *</label>
                  <input
                    type="text"
                    name="contactPerson"
                    value={formData.contactPerson}
                    onChange={handleInputChange}
                    placeholder="e.g. Mr. S. A. Khan"
                    className={`mt-1.5 block w-full px-3 py-2 border rounded-lg text-sm shadow-sm focus:outline-none focus:ring-1 ${
                      formErrors.contactPerson 
                        ? 'border-red-300 focus:ring-red-500 focus:border-red-500' 
                        : 'border-gray-300 focus:ring-emerald-500 focus:border-emerald-500'
                    }`}
                  />
                  {formErrors.contactPerson && <p className="text-xs text-red-500 mt-1">{formErrors.contactPerson}</p>}
                </div>

                {/* Phone */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700">Phone Number *</label>
                  <input
                    type="text"
                    name="phone"
                    value={formData.phone}
                    onChange={handleInputChange}
                    placeholder="e.g. +8801711000000"
                    className={`mt-1.5 block w-full px-3 py-2 border rounded-lg text-sm shadow-sm focus:outline-none focus:ring-1 ${
                      formErrors.phone 
                        ? 'border-red-300 focus:ring-red-500 focus:border-red-500' 
                        : 'border-gray-300 focus:ring-emerald-500 focus:border-emerald-500'
                    }`}
                  />
                  {formErrors.phone && <p className="text-xs text-red-500 mt-1">{formErrors.phone}</p>}
                </div>

                {/* Email */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700">Email Address *</label>
                  <input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleInputChange}
                    placeholder="e.g. compliance@ashuliafashion.com"
                    className={`mt-1.5 block w-full px-3 py-2 border rounded-lg text-sm shadow-sm focus:outline-none focus:ring-1 ${
                      formErrors.email 
                        ? 'border-red-300 focus:ring-red-500 focus:border-red-500' 
                        : 'border-gray-300 focus:ring-emerald-500 focus:border-emerald-500'
                    }`}
                  />
                  {formErrors.email && <p className="text-xs text-red-500 mt-1">{formErrors.email}</p>}
                </div>

                {/* Buttons footer */}
                <div className="pt-4 border-t border-gray-100 flex items-center justify-end gap-2 shrink-0">
                  <button
                    type="button"
                    onClick={() => setIsSlideOverOpen(false)}
                    className="px-4 py-2 text-sm font-semibold text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={submitting}
                    className="px-4 py-2 text-sm font-semibold text-white bg-emerald-600 border border-transparent rounded-lg hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 shadow-sm disabled:opacity-50 transition-colors"
                  >
                    {submitting ? 'Registering...' : 'Register Factory'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default FactoryList;
