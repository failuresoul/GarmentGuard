import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3000',
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Response interceptor for unified error message extraction and dispatch
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    let errorMessage = 'An unexpected network error occurred.';

    if (error.response) {
      // Server responded with non-2xx status
      const data = error.response.data;
      if (data && data.error && data.error.message) {
        errorMessage = data.error.message;
      } else if (data && data.message) {
        errorMessage = data.message;
      } else if (data && data.errors && Array.isArray(data.errors)) {
        // Validation errors array from express-validator
        errorMessage = data.errors.map(err => `${err.path}: ${err.msg}`).join('; ');
      } else {
        errorMessage = `Error (${error.response.status}): ${error.response.statusText}`;
      }
    } else if (error.request) {
      // Request made but no response was received
      errorMessage = 'Could not contact the backend server. Please verify it is running.';
    } else {
      errorMessage = error.message;
    }

    // Dispatch a global event so the UI can catch it and display a toast
    if (typeof window !== 'undefined') {
      window.dispatchEvent(new CustomEvent('app-toast', {
        detail: { type: 'error', message: errorMessage }
      }));
    }

    return Promise.reject(error);
  }
);

export default api;
