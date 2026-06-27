const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const oracledb = require('oracledb');
const { executeQuery } = require('../db/execute');

const router = Router();

/**
 * @route   POST /api/grievances
 * @desc    Submit a new worker grievance
 * @access  Public
 */
router.post(
  '/',
  [
    body('workerId').isInt({ min: 1 }).withMessage('workerId must be a positive integer'),
    body('category').trim().notEmpty().withMessage('category is required'),
    body('description').trim().notEmpty().withMessage('description is required')
  ],
  async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { workerId, category, description } = req.body;

    const sql = `
      BEGIN
        pkg_worker_mgmt.sp_submit_grievance(
          p_worker_id    => :p_worker_id,
          p_category     => :p_category,
          p_description  => :p_description,
          p_grievance_id => :p_grievance_id
        );
      END;
    `;

    const binds = {
      p_worker_id: parseInt(workerId, 10),
      p_category: category,
      p_description: description,
      p_grievance_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
    };

    let connection;
    try {
      connection = await oracledb.getConnection();
      const result = await connection.execute(sql, binds, { autoCommit: true });
      const grievanceId = result.outBinds.p_grievance_id;

      res.status(201).json({
        grievanceId,
        message: 'Grievance submitted successfully'
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

/**
 * @route   PATCH /api/grievances/:id/status
 * @desc    Update status and resolution details of a grievance
 * @access  Public
 */
router.patch(
  '/:id/status',
  [
    body('status')
      .isIn(['Open', 'In Progress', 'Resolved', 'Closed', 'Rejected'])
      .withMessage('Invalid grievance status'),
    body('resolutionNotes')
      .optional({ nullable: true })
      .trim()
  ],
  async (req, res, next) => {
    const grievanceId = parseInt(req.params.id, 10);
    if (isNaN(grievanceId)) return res.status(400).json({ error: 'Invalid grievance ID' });

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { status, resolutionNotes } = req.body;

    let connection;
    try {
      connection = await oracledb.getConnection();
      
      const sql = `
        UPDATE GRIEVANCE
        SET status = :status,
            resolved_date = CASE WHEN :status = 'Resolved' THEN SYSDATE ELSE NULL END,
            resolution_notes = :resolution_notes
        WHERE grievance_id = :gid
      `;

      const binds = {
        status,
        resolution_notes: resolutionNotes || null,
        gid: grievanceId
      };

      const result = await connection.execute(sql, binds, { autoCommit: true });

      if (result.rowsAffected === 0) {
        return res.status(404).json({ error: 'Grievance not found' });
      }

      res.json({
        message: 'Grievance status updated successfully',
        status,
        resolvedDate: status === 'Resolved' ? new Date().toISOString() : null
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
