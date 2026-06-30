const { Router } = require('express');
const { executeQuery } = require('../db/execute');

const router = Router();

/**
 * @route   GET /api/analytics/district-ranking
 * @desc    Get factories ranked by compliance score within each district (Query 1)
 * @access  Public
 */
router.get('/district-ranking', async (req, res, next) => {
  const sql = `
    SELECT 
      factory_id AS "factoryId", 
      factory_name AS "factoryName", 
      district AS "district", 
      compliance_score AS "complianceScore", 
      RANK() OVER (PARTITION BY district ORDER BY compliance_score DESC) AS "complianceRank"
    FROM FACTORY
    ORDER BY district, "complianceRank"
  `;
  try {
    const result = await executeQuery(sql);
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

/**
 * @route   GET /api/analytics/salary-trends/:workerId
 * @desc    Get cumulative net salary trends per worker per year (Query 2)
 * @access  Public
 */
router.get('/salary-trends/:workerId', async (req, res, next) => {
  const workerId = parseInt(req.params.workerId, 10);
  if (isNaN(workerId)) {
    return res.status(400).json({ error: 'Invalid worker ID' });
  }

  const sql = `
    SELECT 
      worker_id AS "workerId", 
      year AS "year", 
      month AS "month", 
      net_salary AS "netSalary", 
      SUM(net_salary) OVER (PARTITION BY worker_id, year ORDER BY month ROWS UNBOUNDED PRECEDING) AS "runningNetSalary"
    FROM SALARY_RECORD
    WHERE worker_id = :workerId
    ORDER BY year, month
  `;
  try {
    const result = await executeQuery(sql, { workerId });
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

/**
 * @route   GET /api/analytics/audit-trends
 * @desc    Get average compliance score trend across last 12 months (Backend 2)
 * @access  Public
 */
router.get('/audit-trends', async (req, res, next) => {
  const sql = `
    WITH Months AS (
      SELECT ADD_MONTHS(TRUNC(SYSDATE, 'MM'), - (11 - LEVEL)) AS month_date
      FROM DUAL
      CONNECT BY LEVEL <= 12
    ),
    MonthlyAvg AS (
      SELECT 
        TRUNC(audit_date, 'MM') AS audit_month,
        AVG(score) AS avg_score
      FROM "AUDIT"
      WHERE audit_date >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -11)
      GROUP BY TRUNC(audit_date, 'MM')
    )
    SELECT 
      TO_CHAR(m.month_date, 'YYYY-MM') AS "month",
      TO_CHAR(m.month_date, 'Mon YY') AS "label",
      ROUND(ma.avg_score, 2) AS "avgScore"
    FROM Months m
    LEFT JOIN MonthlyAvg ma ON m.month_date = ma.audit_month
    ORDER BY m.month_date
  `;
  try {
    const result = await executeQuery(sql);
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

/**
 * @route   GET /api/analytics/grievance-breakdown
 * @desc    Get grievance category breakdown and average resolution times (Backend 3)
 * @access  Public
 */
router.get('/grievance-breakdown', async (req, res, next) => {
  const sql = `
    SELECT 
      category AS "category",
      COUNT(*) AS "totalCount",
      COUNT(CASE WHEN status IN ('Resolved', 'Closed') THEN 1 END) AS "resolvedCount",
      COUNT(CASE WHEN status IN ('Pending', 'Investigating', 'Open', 'In Progress') THEN 1 END) AS "openCount",
      ROUND(AVG(CASE WHEN resolved_date IS NOT NULL THEN (resolved_date - submitted_date) END), 2) AS "avgResolutionTime"
    FROM GRIEVANCE
    GROUP BY category
    ORDER BY "totalCount" DESC
  `;
  try {
    const result = await executeQuery(sql);
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
