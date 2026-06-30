const oracledb = require('oracledb');

/**
 * Execute a SQL query or PL/SQL block utilizing the connection pool.
 * Automatically handles getting and releasing the connection.
 * 
 * @param {string} sql The SQL statement or PL/SQL block
 * @param {object|array} params The bind parameters
 * @param {object} opts Execution options overrides
 * @returns {Promise<{rows: any[]|null, rowsAffected: number, outBinds: any}>}
 */
async function executeQuery(sql, params = {}, opts = {}) {
  let connection;
  try {
    connection = await oracledb.getConnection();
    
    // Set Oracle client info context if clientId is passed (for row-level security)
    if (opts.clientId !== undefined) {
      await connection.execute(
        `BEGIN DBMS_APPLICATION_INFO.SET_CLIENT_INFO(:id); END;`,
        { id: String(opts.clientId) }
      );
    }
    
    const executionOptions = {
      outFormat: oracledb.OUT_FORMAT_OBJECT,
      autoCommit: true, // Default to autocommit for simple DML/PLSQL execution
      ...opts
    };

    const start = Date.now();
    const result = await connection.execute(sql, params, executionOptions);
    const duration = Date.now() - start;

    // Log slow queries (>500ms) to the ERROR_LOG table
    if (duration > 500) {
      try {
        const slowMsg = `Slow query detected (${duration}ms): ${sql.substring(0, 1500)}`;
        await connection.execute(
          `INSERT INTO ERROR_LOG (username, procedure_name, error_code, error_message, error_backtrace)
           VALUES (:username, :proc, :code, :msg, :backtrace)`,
          {
            username: 'SYSTEM_DB_POOL',
            proc: 'NodeJS executeQuery timing',
            code: 500,
            msg: slowMsg,
            backtrace: new Error().stack ? new Error().stack.substring(0, 2000) : null
          }
        );
      } catch (logErr) {
        console.error('Failed to log slow query to ERROR_LOG:', logErr.message);
      }
    }

    return {
      rows: result.rows || null,
      rowsAffected: result.rowsAffected || 0,
      outBinds: result.outBinds || null
    };
  } catch (err) {
    // Re-throw so that error routing middleware handles it
    throw err;
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (closeErr) {
        console.error('Error closing database connection:', closeErr.message);
      }
    }
  }
}

module.exports = {
  executeQuery
};
