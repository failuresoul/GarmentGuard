import { useState, useEffect, useCallback } from 'react';
import api from '../api/axios';

/**
 * Custom React hook to fetch and reload factory data.
 * Returns state variables and refresh callback helper.
 */
export function useFactories() {
  const [factories, setFactories] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchFactories = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get('/api/factories');
      setFactories(response.data || []);
    } catch (err) {
      setError(err.message || 'Failed to retrieve factory data.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchFactories();
  }, [fetchFactories]);

  return { factories, loading, error, fetchFactories };
}
