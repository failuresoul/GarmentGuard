const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const oracledb = require('oracledb');
const { executeQuery } = require('../db/execute');

const router = Router();

/**
 * @route   POST /api/workers
 * @desc    Hire a new worker
 * @access  Public
 */
router.post(
  '/',
  [
    body('factoryId').isInt({ min: 1 }).withMessage('factoryId must be a positive integer'),
    body('fullName').trim().notEmpty().withMessage('fullName is required'),
    body('nationalId').trim().notEmpty().withMessage('nationalId is required'),
    body('designation').trim().notEmpty().withMessage('designation is required'),
    body('joinDate').isISO8601().withMessage('joinDate must be a valid ISO8601 date (YYYY-MM-DD)'),
    body('baseSalary').isFloat({ gt: 0 }).withMessage('baseSalary must be a positive number'),
    body('shift')
      .isIn(['Morning', 'Evening', 'Night', 'Day', 'Roster'])
      .withMessage('shift must be one of: Morning, Evening, Night, Day, Roster'),
    body('status')
      .optional()
      .isIn(['Active', 'Inactive', 'Suspended', 'Terminated'])
      .withMessage('status must be one of: Active, Inactive, Suspended, Terminated')
  ],
  async (req, res, next) => {
    // Validate request inputs
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      factoryId,
      fullName,
      nationalId,
      designation,
      joinDate,
      baseSalary,
      shift,
      status
    } = req.body;

    const sql = `
      BEGIN
        pkg_worker_mgmt.sp_hire_worker(
          p_factory_id  => :p_factory_id,
          p_full_name   => :p_full_name,
          p_national_id => :p_national_id,
          p_designation => :p_designation,
          p_join_date   => :p_join_date,
          p_base_salary => :p_base_salary,
          p_shift       => :p_shift,
          p_status      => :p_status,
          p_worker_id   => :p_worker_id
        );
      END;
    `;

    const binds = {
      p_factory_id: parseInt(factoryId, 10),
      p_full_name: fullName,
      p_national_id: nationalId,
      p_designation: designation,
      p_join_date: new Date(joinDate), // Pass standard Date object to Oracle
      p_base_salary: parseFloat(baseSalary),
      p_shift: shift,
      p_status: status || 'Active',
      p_worker_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
    };

    try {
      const result = await executeQuery(sql, binds);
      const workerId = result.outBinds.p_worker_id;

      res.status(201).json({
        workerId,
        message: 'Worker hired successfully'
      });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * @route   GET /api/workers
 * @desc    Get all workers with factory name join
 * @access  Public
 */
router.get('/', async (req, res, next) => {
  let connection;
  try {
    connection = await oracledb.getConnection();
    const result = await connection.execute(
      `SELECT 
         w.worker_id   AS "workerId",
         w.full_name   AS "fullName",
         w.national_id AS "nationalId",
         w.designation AS "designation",
         w.join_date   AS "joinDate",
         w.base_salary AS "baseSalary",
         w.shift       AS "shift",
         w.status      AS "status",
         f.factory_name AS "factoryName"
       FROM WORKER w
       JOIN FACTORY f ON w.factory_id = f.factory_id
       ORDER BY w.full_name`,
      [],
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  } finally {
    if (connection) {
      try { await connection.close(); } catch {}
    }
  }
});

/**
 * @route   POST /api/workers/:id/salary
 * @desc    Process monthly salary for a worker
 * @access  Public
 */
router.post(
  '/:id/salary',
  [
    body('month').isInt({ min: 1, max: 12 }).withMessage('month must be between 1 and 12'),
    body('year').isInt({ min: 2000, max: 2100 }).withMessage('year must be a valid 4-digit year'),
    body('overtimeHours').isInt({ min: 0 }).withMessage('overtimeHours must be a non-negative integer')
  ],
  async (req, res, next) => {
    const workerId = parseInt(req.params.id, 10);
    if (isNaN(workerId)) return res.status(400).json({ error: 'Invalid worker ID' });

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { month, year, overtimeHours } = req.body;

    const sql = `
      BEGIN
        pkg_worker_mgmt.sp_process_salary(
          p_worker_id      => :p_worker_id,
          p_month          => :p_month,
          p_year           => :p_year,
          p_overtime_hours => :p_overtime_hours
        );
      END;
    `;

    const binds = {
      p_worker_id: workerId,
      p_month: parseInt(month, 10),
      p_year: parseInt(year, 10),
      p_overtime_hours: parseInt(overtimeHours, 10)
    };

    let connection;
    try {
      connection = await oracledb.getConnection();
      await connection.execute(sql, binds, { autoCommit: true });

      // After processing, fetch the generated salary record's net salary to return
      const salaryRes = await connection.execute(
        `SELECT net_salary AS "netSalary", overtime_paid AS "overtimePaid", base_amount AS "baseAmount"
         FROM SALARY_RECORD 
         WHERE worker_id = :wid AND month = :mth AND year = :yr`,
        { wid: workerId, mth: parseInt(month, 10), yr: parseInt(year, 10) },
        { outFormat: oracledb.OUT_FORMAT_OBJECT }
      );
      
      const record = salaryRes.rows?.[0];
      const netSalary = record ? record.netSalary : null;
      const overtimePaid = record ? record.overtimePaid : null;
      const baseAmount = record ? record.baseAmount : null;

      res.status(201).json({
        message: 'Salary processed successfully',
        netSalary,
        overtimePaid,
        baseAmount
      });
    } catch (err) {
      next(err);
    } finally {
      if (connection) {
        try { await connection.close(); } catch {}
      }
    }
  }
);

module.exports = router;
