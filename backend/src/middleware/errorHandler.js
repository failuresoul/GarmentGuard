/**
 * Global Express error handling middleware.
 * Ensures all unhandled exceptions return a standardized JSON format.
 */
function errorHandler(err, req, res, next) {
  // Log the error stack for server monitoring
  console.error('Express Error Handler caught error:', err);

  const status = err.status || 500;
  const code = err.code || 'INTERNAL_SERVER_ERROR';
  const message = err.message || 'An unexpected error occurred on the server.';

  // Prevent response header issues if response was already sent
  if (res.headersSent) {
    return next(err);
  }

  res.status(status).json({
    error: {
      code,
      message,
      timestamp: new Date().toISOString()
    }
  });
}

module.exports = errorHandler;
