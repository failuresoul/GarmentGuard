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

module.exports = router;
