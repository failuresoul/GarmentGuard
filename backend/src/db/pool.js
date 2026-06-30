const oracledb = require('oracledb');

// Fetch CLOB data types directly as JavaScript strings
oracledb.fetchAsString = [ oracledb.CLOB ];

// Enable node-oracledb Thick mode to support Oracle 11g connections
try {
  oracledb.initOracleClient();
  console.log('Oracle Client initialized in Thick mode (compiles with local 11g client binaries).');
} catch (err) {
  console.error('Failed to initialize Oracle Client in Thick mode:', err.message);
  console.error('Verify that your local Oracle XE bin folder or Oracle Instant Client is configured in the system PATH.');
}

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
    console.log('Oracle Database Connection Pool initialized successfully (Thick mode).');
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
