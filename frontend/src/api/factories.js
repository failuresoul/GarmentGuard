/**
 * factories.js — API functions for all factory-related endpoints.
 * Used exclusively via TanStack Query hooks (useQuery).
 *
 * All requests pass { suppressToast: true } so that React Query's own
 * isError handling is used instead of the global toast interceptor.
 */
import api from './axios';

const OPTS = { suppressToast: true };

/** Full factory row + compliance stats */
export const fetchFactory = (id) =>
  api.get(`/api/factories/${id}`, OPTS).then((r) => r.data);

/**
 * Paginated workers for a factory.
 * @param {number} id
 * @param {number} page   1-based
 * @param {number} limit  rows per page
 * @param {number} year   for YTD salary calculation
 */
export const fetchFactoryWorkers = (id, page = 1, limit = 20, year = new Date().getFullYear(), search = '', sortBy = '', order = '') =>
  api.get(`/api/factories/${id}/workers`, { ...OPTS, params: { page, limit, year, search, sortBy, order } }).then((r) => r.data);

/** Full audit history, most-recent first */
export const fetchFactoryAudits = (id) =>
  api.get(`/api/factories/${id}/audits`, OPTS).then((r) => r.data);

/** Certifications with isValid flag + daysUntilExpiry */
export const fetchFactoryCertifications = (id) =>
  api.get(`/api/factories/${id}/certifications`, OPTS).then((r) => r.data);

/** Equipment expiry alert: { allOk: boolean, alerts: string[] } */
export const fetchEquipmentAlerts = (id) =>
  api.get(`/api/factories/${id}/equipment-alerts`, OPTS).then((r) => r.data);
