/**
 * Middleware to catch Oracle Database exceptions (ORA codes) and translate
 * them into standard HTTP status codes and uniform JSON error objects.
 */
function oracleErrors(err, req, res, next) {
  // Check if this error is an Oracle DB error (typically has errorNum or ORA- in the message)
  if (err && (err.errorNum || (typeof err.message === 'string' && err.message.includes('ORA-')))) {
    const errorNum = err.errorNum || (err.message.match(/ORA-(\d+)/) ? parseInt(err.message.match(/ORA-(\d+)/)[1], 10) : null);
    
    if (errorNum !== null) {
      let status;
      let code;
      
      // Clean up the error message by removing ORA-XXXXX code and stack trace noise
      const cleanMessageMatch = err.message.match(/ORA-\d+:\s*(.*)/);
      const message = cleanMessageMatch 
        ? cleanMessageMatch[1].split('\n')[0].trim() 
        : err.message;

      switch (errorNum) {
        case 1: // ORA-00001: Unique constraint violated
          status = 409;
          code = 'CONFLICT';
          break;
        case 2291: // ORA-02291: Integrity constraint (FK) violated
          status = 422;
          code = 'FOREIGN_KEY_VIOLATION';
          break;
        case 20001: // Factory inactive/suspended
          status = 422;
          code = 'FACTORY_INACTIVE';
          break;
        case 20002: // Overtime limit exceeded
          status = 400;
          code = 'OVERTIME_LIMIT_EXCEEDED';
          break;
        case 20003: // Month already processed for worker
          status = 409;
          code = 'DUPLICATE_PAYROLL_CYCLE';
          break;
        case 20004: // Audit schedule conflict
          status = 409;
          code = 'AUDIT_SCHEDULE_CONFLICT';
          break;
        case 20005: // Invalid inspector role
        case 20006: // Inspector not found
        case 20007: // Worker not found
        case 20008: // Worker not found during salary calculation
          status = 422;
          code = 'DATABASE_VALIDATION_ERROR';
          break;
      }

      if (status) {
        console.warn(`Oracle Exception mapped: ORA-${errorNum} -> HTTP ${status} (${code})`);
        return res.status(status).json({
          error: {
            code,
            message,
            timestamp: new Date().toISOString()
          }
        });
      }
    }
  }

  // Not a mapped Oracle error, pass to the global error handler
  next(err);
}

module.exports = oracleErrors;
