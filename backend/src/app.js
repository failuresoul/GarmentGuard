require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const { initializePool, closePool } = require('./db/pool');

const { verifyJWT, requireRole } = require('./middleware/auth');

const authRoutes = require('./routes/auth');
const factoryRoutes = require('./routes/factories');
const workerRoutes = require('./routes/workers');
const auditRoutes = require('./routes/audits');
const reportRoutes = require('./routes/reports');
const grievanceRoutes = require('./routes/grievances');
const analyticsRoutes = require('./routes/analytics');
const dashboardRoutes = require('./routes/dashboard');
const buyerRoutes = require('./routes/buyer');
const workerPortalRoutes = require('./routes/workerPortal');

const oracleErrors = require('./middleware/oracleErrors');
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS with credentials support for cookie sharing in development
app.use(cors({
  origin: ['http://localhost:5173', 'http://127.0.0.1:5173'],
  credentials: true
}));

// Body & Cookie Parsers
app.use(express.json());
app.use(cookieParser());


// API Routes
app.use('/api/auth', authRoutes); // Public auth endpoints

// Role-protected endpoints
app.use('/api/factories', verifyJWT, requireRole(['Admin', 'Compliance_Officer', 'Inspector']), factoryRoutes);
app.use('/api/workers', verifyJWT, requireRole(['Admin', 'Compliance_Officer']), workerRoutes);
app.use('/api/audits', verifyJWT, requireRole(['Admin', 'Compliance_Officer', 'Inspector']), auditRoutes);
app.use('/api/reports', verifyJWT, requireRole(['Admin', 'Compliance_Officer']), reportRoutes);
app.use('/api/grievances', verifyJWT, requireRole(['Admin', 'Compliance_Officer', 'Inspector']), grievanceRoutes);
app.use('/api/analytics', verifyJWT, requireRole(['Admin', 'Compliance_Officer', 'Inspector', 'Worker']), analyticsRoutes);
app.use('/api/dashboard', verifyJWT, requireRole(['Admin', 'Compliance_Officer', 'Inspector']), dashboardRoutes);

// Special role endpoints (protection handled inside the routes)
app.use('/api/buyer', buyerRoutes);
app.use('/api/worker-portal', workerPortalRoutes);

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
