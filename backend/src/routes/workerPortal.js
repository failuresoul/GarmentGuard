const { Router } = require('express');
const { executeQuery } = require('../db/execute');
const { verifyJWT, requireRole } = require('../middleware/auth');

const router = Router();

// Protect worker portal endpoints to Worker role only
router.use(verifyJWT);
router.use(requireRole(['Worker', 'Admin']));

/**
 * @route   GET /api/worker-portal/grievances
 * @desc    Get logged in worker's own grievances via RLS view (Backend 7)
 * @access  Private (Worker)
 */
router.get('/grievances', async (req, res, next) => {
  const sql = `
    SELECT 
      grievance_id AS "grievanceId", 
      category AS "category", 
      description AS "description", 
      TO_CHAR(submitted_date, 'YYYY-MM-DD') AS "submittedDate", 
      status AS "status", 
      TO_CHAR(resolved_date, 'YYYY-MM-DD') AS "resolvedDate",
      resolution_notes AS "resolutionNotes"
    FROM vw_my_grievances
    ORDER BY submitted_date DESC
  `;
  try {
    const result = await executeQuery(sql, {}, { clientId: req.user.workerId });
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

/**
 * @route   POST /api/worker-portal/grievances
 * @desc    Submit a new grievance for the logged in worker (Backend 8)
 * @access  Private (Worker)
 */
router.post('/grievances', async (req, res, next) => {
  const { category, description } = req.body;
  if (!category || !description) {
    return res.status(400).json({ error: 'Category and description are required' });
  }

  const sql = `
    INSERT INTO GRIEVANCE (worker_id, category, description, submitted_date, status)
    VALUES (:workerId, :category, :description, SYSDATE, 'Open')
  `;
  try {
    await executeQuery(sql, { 
      workerId: req.user.workerId, 
      category, 
      description 
    });
    res.status(201).json({ message: 'Grievance submitted successfully' });
  } catch (err) {
    next(err);
  }
});

/**
 * @route   GET /api/worker-portal/salaries
 * @desc    Get logged in worker's own salary records via RLS view (Backend 9)
 * @access  Private (Worker)
 */
router.get('/salaries', async (req, res, next) => {
  const sql = `
    SELECT 
      record_id AS "recordId", 
      month AS "month", 
      year AS "year", 
      base_amount AS "baseAmount", 
      overtime_hours AS "overtimeHours", 
      overtime_paid AS "overtimePaid", 
      deductions AS "deductions", 
      net_salary AS "netSalary", 
      payment_status AS "paymentStatus"
    FROM vw_my_salary_records
    ORDER BY year DESC, month DESC
  `;
  try {
    const result = await executeQuery(sql, {}, { clientId: req.user.workerId });
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
