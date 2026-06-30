const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const { executeQuery } = require('../db/execute');

const router = Router();

/**
 * @route   GET /api/audits/meta
 * @desc    Get factory and inspector metadata for audit scheduling
 * @access  Private (Admin, Compliance Officer, Inspector)
 */
router.get('/meta', async (req, res, next) => {
  try {
    const factRes = await executeQuery('SELECT factory_id AS "factoryId", factory_name AS "factoryName" FROM FACTORY ORDER BY factory_name');
    const inspRes = await executeQuery("SELECT user_id AS \"userId\", full_name AS \"fullName\" FROM USER_ WHERE role = 'Inspector' OR role = 'Admin' ORDER BY full_name");
    res.json({
      factories: factRes.rows || [],
      inspectors: inspRes.rows || []
    });
  } catch (err) {
    next(err);
  }
});

/**
 * @route   GET /api/audits
 * @desc    Get all audits (scheduled & completed) with factory and inspector details
 * @access  Private (Admin, Compliance Officer, Inspector)
 */
router.get('/', async (req, res, next) => {
  const sql = `
    SELECT 
      a.audit_id AS "auditId",
      a.factory_id AS "factoryId",
      f.factory_name AS "factoryName",
      a.inspector_id AS "inspectorId",
      u.full_name AS "inspectorName",
      TO_CHAR(a.audit_date, 'YYYY-MM-DD') AS "auditDate",
      TO_CHAR(a.next_scheduled, 'YYYY-MM-DD') AS "nextScheduled",
      a.score AS "score",
      a.result AS "result",
      a.findings AS "findings",
      a.recommendations AS "recommendations"
    FROM "AUDIT" a
    JOIN FACTORY f ON a.factory_id = f.factory_id
    JOIN USER_ u ON a.inspector_id = u.user_id
    ORDER BY a.audit_date DESC, a.audit_id DESC
  `;
  try {
    const result = await executeQuery(sql);
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

/**
 * @route   POST /api/audits
 * @desc    Schedule a safety audit
 * @access  Private (Admin, Compliance Officer, Inspector)
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
      p_audit_date: new Date(auditDate)
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

/**
 * @route   PUT /api/audits/:id/record
 * @desc    Record audit findings, scores, and schedule next audit dates
 * @access  Private (Admin, Compliance Officer, Inspector)
 */
router.put('/:id/record', async (req, res, next) => {
  const auditId = parseInt(req.params.id, 10);
  const { score, result, findings, recommendations, nextScheduled } = req.body;

  if (isNaN(auditId)) {
    return res.status(400).json({ error: 'Invalid audit ID' });
  }

  const scoreVal = parseFloat(score);
  if (isNaN(scoreVal) || scoreVal < 0 || scoreVal > 100) {
    return res.status(400).json({ error: 'Score must be a number between 0 and 100' });
  }

  const allowedResults = ['Passed', 'Failed', 'Conditional'];
  if (!allowedResults.includes(result)) {
    return res.status(400).json({ error: `Result must be one of: ${allowedResults.join(', ')}` });
  }

  try {
    // 1. Get the factory_id of this audit to sync factory dates
    const selectSql = 'SELECT factory_id AS "factoryId", audit_date AS "auditDate" FROM "AUDIT" WHERE audit_id = :auditId';
    const auditRes = await executeQuery(selectSql, { auditId });
    if (!auditRes.rows || auditRes.rows.length === 0) {
      return res.status(404).json({ error: 'Audit not found' });
    }
    const { factoryId } = auditRes.rows[0];

    // 2. Update audit record (Triggers sp_update_compliance_status automatically in DB via trg_audit_score_status)
    const updateAuditSql = `
      UPDATE "AUDIT"
      SET 
        score = :score,
        result = :result,
        findings = :findings,
        recommendations = :recommendations,
        next_scheduled = :nextScheduled
      WHERE audit_id = :auditId
    `;

    const binds = {
      score: scoreVal,
      result,
      findings: findings || '',
      recommendations: recommendations || '',
      nextScheduled: nextScheduled ? new Date(nextScheduled) : null,
      auditId
    };

    await executeQuery(updateAuditSql, binds);

    // 3. Sync next audit date back to factory if nextScheduled is provided
    if (nextScheduled) {
      const updateFactorySql = `
        UPDATE FACTORY
        SET next_audit_date = :nextScheduled
        WHERE factory_id = :factoryId
      `;
      await executeQuery(updateFactorySql, {
        nextScheduled: new Date(nextScheduled),
        factoryId
      });
    }

    res.json({ message: 'Audit results recorded successfully' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
