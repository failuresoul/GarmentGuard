const oracledb = require('oracledb');

// Enable oracledb 6 Thin mode explicitly
oracledb.thin = true;

async function initializePool() {
  const poolConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString: process.env.DB_CONNECTION_STRING,
    poolMin: 2,
    poolMax: 10,
    poolTimeout: 60
  };

  try {
    await oracledb.createPool(poolConfig);
    console.log('Oracle Database Connection Pool initialized successfully (Thin mode).');
  } catch (err) {
    console.error('Failed to initialize Oracle connection pool:', err.message);
    throw err;
  }
}

async function closePool() {
  try {
    const pool = oracledb.getPool();
    await pool.close(10);
    console.log('Oracle Database Connection Pool closed successfully.');
  } catch (err) {
    console.error('Failed to close Oracle connection pool:', err.message);
    throw err;
  }
}

module.exports = {
  initializePool,
  closePool
};
