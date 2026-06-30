/**
 * audits.js — API functions for all audit-related endpoints.
 * Used via TanStack Query hooks (useQuery/useMutation).
 */
import api from './axios';

const OPTS = { suppressToast: true };

/** Get all audits in the system */
export const fetchAudits = () =>
  api.get('/api/audits', OPTS).then((r) => r.data);

/** Get factory and inspector metadata for audits */
export const fetchAuditMeta = () =>
  api.get('/api/audits/meta', OPTS).then((r) => r.data);

/** Schedule a new safety audit */
export const scheduleAudit = (data) =>
  api.post('/api/audits', data, OPTS).then((r) => r.data);

/** Record safety audit findings and recommendations */
export const recordAuditResults = (id, data) =>
  api.put(`/api/audits/${id}/record`, data, OPTS).then((r) => r.data);
