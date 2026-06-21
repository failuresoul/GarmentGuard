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
    
    const executionOptions = {
      outFormat: oracledb.OUT_FORMAT_OBJECT,
      autoCommit: true, // Default to autocommit for simple DML/PLSQL execution
      ...opts
    };

    const result = await connection.execute(sql, params, executionOptions);

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
