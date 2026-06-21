const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const { executeQuery } = require('../db/execute');

const router = Router();

/**
 * @route   POST /api/audits
 * @desc    Schedule a safety audit
 * @access  Public
 */
router.post(
  '/',
  [
    body('factoryId').isInt({ min: 1 }).withMessage('factoryId must be a positive integer'),
    body('inspectorId').isInt({ min: 1 }).withMessage('inspectorId must be a positive integer'),
    body('auditDate').isISO8601().withMessage('auditDate must be a valid ISO8601 date (YYYY-MM-DD)')
  ],
  async (req, res, next) => {
    // Validate request inputs
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { factoryId, inspectorId, auditDate } = req.body;

    const sql = `
      BEGIN
        pkg_factory_mgmt.sp_schedule_audit(
          p_factory_id   => :p_factory_id,
          p_inspector_id => :p_inspector_id,
          p_audit_date   => :p_audit_date
        );
      END;
    `;

    const binds = {
      p_factory_id: parseInt(factoryId, 10),
      p_inspector_id: parseInt(inspectorId, 10),
      p_audit_date: new Date(auditDate) // Pass standard Date object to Oracle
    };

    try {
      await executeQuery(sql, binds);

      res.status(201).json({
        message: 'Audit scheduled successfully'
      });
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
