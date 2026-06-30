const { Router } = require('express');
const { executeQuery } = require('../db/execute');

const router = Router();

/**
 * @route   GET /api/dashboard
 * @desc    Get main dashboard metrics, factories, and recent feeds (Backend 1)
 * @access  Public
 */
router.get('/', async (req, res, next) => {
  const sqlAgg = `
    SELECT
      (SELECT COUNT(*) FROM FACTORY) AS "totalFactories",
      (SELECT COUNT(*) FROM FACTORY WHERE compliance_status = 'Compliant') AS "compliantCount",
      (SELECT COUNT(*) FROM FACTORY WHERE compliance_status IN ('Partially Compliant', 'Pending', 'Review Needed')) AS "atRiskCount",
      (SELECT COUNT(*) FROM FACTORY WHERE compliance_status IN ('Non-Compliant', 'Suspended')) AS "nonCompliantCount",
      (SELECT COUNT(*) FROM WORKER) AS "totalWorkers",
      COALESCE((SELECT SUM(open_grievances) FROM mv_compliance_dashboard), 0) AS "openGrievances",
      COALESCE((SELECT SUM(equipment_expiring_soon) FROM mv_compliance_dashboard), 0) AS "equipmentAlerts"
    FROM DUAL
  `;

  const sqlMView = `
    SELECT 
      factory_id AS "factoryId", 
      factory_name AS "factoryName", 
      latest_score AS "latestScore", 
      cert_count AS "certCount", 
      open_grievances AS "openGrievances", 
      equipment_expiring_soon AS "equipmentExpiringSoon"
    FROM mv_compliance_dashboard
    ORDER BY factory_id
  `;

  const sqlGrievances = `
    SELECT * FROM (
      SELECT 
        g.grievance_id AS "grievanceId",
        g.category AS "category",
        g.status AS "status",
        TO_CHAR(g.submitted_date, 'YYYY-MM-DD') AS "submittedDate",
        w.full_name AS "workerName",
        f.factory_name AS "factoryName"
      FROM GRIEVANCE g
      JOIN WORKER w ON g.worker_id = w.worker_id
      JOIN FACTORY f ON w.factory_id = f.factory_id
      ORDER BY g.submitted_date DESC
    ) WHERE ROWNUM <= 5
  `;

  const sqlAudits = `
    SELECT * FROM (
      SELECT 
        a.audit_id AS "auditId",
        TO_CHAR(a.audit_date, 'YYYY-MM-DD') AS "auditDate",
        TO_CHAR(a.next_scheduled, 'YYYY-MM-DD') AS "nextScheduled",
        f.factory_name AS "factoryName"
      FROM "AUDIT" a
      JOIN FACTORY f ON a.factory_id = f.factory_id
      WHERE a.next_scheduled IS NOT NULL
      ORDER BY a.audit_date DESC
    ) WHERE ROWNUM <= 3
  `;

  try {
    const aggResult = await executeQuery(sqlAgg);
    const mviewResult = await executeQuery(sqlMView);
    const grievancesResult = await executeQuery(sqlGrievances);
    const auditsResult = await executeQuery(sqlAudits);

    res.json({
      aggregates: aggResult.rows ? aggResult.rows[0] : {},
      factories: mviewResult.rows || [],
      recentGrievances: grievancesResult.rows || [],
      recentAudits: auditsResult.rows || []
    });
  } catch (err) {
    next(err);
  }
});

/**
 * @route   GET /api/dashboard/summary
 * @desc    Get compliance dashboard summary querying the materialized view (Query 6)
 * @access  Public
 */
router.get('/summary', async (req, res, next) => {
  const sql = `
    SELECT 
      factory_id AS "factoryId", 
      factory_name AS "factoryName", 
      latest_score AS "latestScore", 
      cert_count AS "certCount", 
      open_grievances AS "openGrievances", 
      equipment_expiring_soon AS "equipmentExpiringSoon"
    FROM mv_compliance_dashboard
    ORDER BY factory_id
  `;
  try {
    const result = await executeQuery(sql);
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
