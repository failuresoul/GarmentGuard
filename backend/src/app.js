require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { initializePool, closePool } = require('./db/pool');
const factoryRoutes = require('./routes/factories');
const workerRoutes = require('./routes/workers');
const auditRoutes = require('./routes/audits');
const oracleErrors = require('./middleware/oracleErrors');
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for frontend integration
app.use(cors());

// Body Parsers
app.use(express.json());


// API Routes
app.use('/api/factories', factoryRoutes);
app.use('/api/workers', workerRoutes);
app.use('/api/audits', auditRoutes);

// Error Handling Middlewares (Order of registration matters)
app.use(oracleErrors); // First translates Oracle Database specific errors
app.use(errorHandler); // Then handles general/global errors

let server;

/**
 * Start the connection pool and HTTP server listeners.
 */
async function startServer() {
  try {
    // 1. Start Oracle Connection Pool
    await initializePool();

    // 2. Start HTTP Listener
    server = app.listen(PORT, () => {
      console.log(`GarmentGuard Backend listening on port ${PORT}`);
    });
  } catch (err) {
    console.error('Critical failure starting server:', err.message);
    process.exit(1);
  }
}

/**
 * Perform graceful cleanup of HTTP listeners and DB connection pools.
 */
async function handleShutdown() {
  console.log('\nReceived terminate signal. Initiating graceful shutdown...');
  
  if (server) {
    server.close(async () => {
      console.log('HTTP server stopped.');
      try {
        await closePool();
        console.log('Graceful shutdown completed successfully.');
        process.exit(0);
      } catch (err) {
        console.error('Error closing database pool during shutdown:', err.message);
        process.exit(1);
      }
    });
  } else {
    process.exit(0);
  }
}

// Attach lifecycle termination signal listeners
process.on('SIGINT', handleShutdown);
process.on('SIGTERM', handleShutdown);

// Run the initialization sequence
startServer();
