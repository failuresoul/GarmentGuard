const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const oracledb = require('oracledb');
const { executeQuery } = require('../db/execute');

const router = Router();

/**
 * @route   POST /api/factories
 * @desc    Register a new factory
 * @access  Public
 */
router.post(
  '/',
  [
    body('name').trim().notEmpty().withMessage('name is required'),
    body('registrationNo').trim().notEmpty().withMessage('registrationNo is required'),
    body('address').trim().notEmpty().withMessage('address is required'),
    body('district').trim().notEmpty().withMessage('district is required'),
    body('totalWorkers')
      .optional()
      .isInt({ min: 0 })
      .withMessage('totalWorkers must be a non-negative integer'),
    body('contactPerson').trim().notEmpty().withMessage('contactPerson is required'),
    body('phone').trim().notEmpty().withMessage('phone is required'),
    body('email').trim().isEmail().withMessage('email must be a valid email address')
  ],
  async (req, res, next) => {
    // Validate request inputs
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      name,
      registrationNo,
      address,
      district,
      totalWorkers,
      contactPerson,
      phone,
      email
    } = req.body;

    const sql = `
      BEGIN
        pkg_factory_mgmt.sp_register_factory(
          p_name       => :p_name,
          p_reg_no     => :p_reg_no,
          p_address    => :p_address,
          p_district   => :p_district,
          p_workers    => :p_workers,
          p_contact    => :p_contact,
          p_phone      => :p_phone,
          p_email      => :p_email,
          p_factory_id => :p_factory_id
        );
      END;
    `;

    const binds = {
      p_name: name,
      p_reg_no: registrationNo,
      p_address: address,
      p_district: district,
      p_workers: totalWorkers !== undefined ? parseInt(totalWorkers, 10) : 0,
      p_contact: contactPerson,
      p_phone: phone,
      p_email: email,
      p_factory_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
    };

    try {
      const result = await executeQuery(sql, binds);
      const factoryId = result.outBinds.p_factory_id;

      res.status(201).json({
        factoryId,
        message: 'Factory registered successfully'
      });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * @route   GET /api/factories
 * @desc    Get all factories with compliance details
 * @access  Public
 */
router.get('/', async (req, res, next) => {
  const sql = `
    SELECT 
      factory_id AS "factoryId",
      factory_name AS "name",
      registration_no AS "registrationNo",
      address AS "address",
      district AS "district",
      total_workers AS "totalWorkers",
      compliance_status AS "complianceStatus",
      compliance_score AS "complianceScore",
      latest_audit_score AS "latestAuditScore",
      active_certs_count AS "activeCertsCount",
      open_grievances_count AS "openGrievancesCount"
    FROM vw_factory_compliance
    ORDER BY factory_name
  `;
  try {
    const result = await executeQuery(sql);
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

/**
 * @route   GET /api/factories/:id
 * @desc    Single factory with full compliance data (vw_factory_compliance)
 * @access  Public
 */
router.get('/:id', async (req, res, next) => {
  const factoryId = parseInt(req.params.id, 10);
  if (isNaN(factoryId)) return res.status(400).json({ error: 'Invalid factory ID' });

  const sql = `
    SELECT
      factory_id            AS "factoryId",
      factory_name          AS "name",
      registration_no       AS "registrationNo",
      address               AS "address",
      district              AS "district",
      contact_person        AS "contactPerson",
      phone                 AS "phone",
      email                 AS "email",
      total_workers         AS "totalWorkers",
      compliance_status     AS "complianceStatus",
      compliance_score      AS "complianceScore",
      latest_audit_score    AS "latestAuditScore",
      active_certs_count    AS "activeCertsCount",
      open_grievances_count AS "openGrievancesCount"
    FROM vw_factory_compliance
    WHERE factory_id = :id
  `;
  try {
    const result = await executeQuery(sql, { id: factoryId });
    if (!result.rows || result.rows.length === 0) {
      return res.status(404).json({ error: 'Factory not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

/**
 * @route   GET /api/factories/:id/workers
 * @desc    Paginated worker list via pkg_reporting.sp_get_factory_workers REF CURSOR
 * @access  Public
 * @query   page (default 1), limit (default 20)
 */
router.get('/:id/workers', async (req, res, next) => {
  const factoryId = parseInt(req.params.id, 10);
  if (isNaN(factoryId)) return res.status(400).json({ error: 'Invalid factory ID' });

  const page  = Math.max(1, parseInt(req.query.page  || '1',  10));
  const limit = Math.min(100, Math.max(1, parseInt(req.query.limit || '20', 10)));
  const year  = parseInt(req.query.year || new Date().getFullYear(), 10);
  const search = req.query.search ? String(req.query.search).trim() : '';
  const sortBy = req.query.sortBy ? String(req.query.sortBy).trim() : '';
  const order = req.query.order ? String(req.query.order).trim().toUpperCase() : 'ASC';

  const sortWhitelist = {
    workerId: 'w.worker_id',
    fullName: 'w.full_name',
    nationalId: 'w.national_id',
    designation: 'w.designation',
    joinDate: 'w.join_date',
    baseSalary: 'w.base_salary',
    shift: 'w.shift',
    status: 'w.status'
  };

  const dbSortColumn = sortWhitelist[sortBy] || 'w.full_name';
  const dbOrder = (order === 'DESC') ? 'DESC' : 'ASC';

  let connection;
  try {
    connection = await oracledb.getConnection();

    const binds = { fid: factoryId };
    let whereClause = 'WHERE w.factory_id = :fid';

    if (search) {
      whereClause += ' AND (UPPER(w.full_name) LIKE :searchVal OR UPPER(w.national_id) LIKE :searchVal OR UPPER(w.designation) LIKE :searchVal)';
      binds.searchVal = `%${search.toUpperCase()}%`;
    }

    // ── Workers: direct SELECT with dynamic sort/filter ──
    const workersResult = await connection.execute(
      `SELECT
         w.worker_id   AS worker_id,
         w.full_name   AS full_name,
         w.national_id AS national_id,
         w.designation AS designation,
         w.join_date   AS join_date,
         w.base_salary AS base_salary,
         w.shift       AS shift,
         w.status      AS status
       FROM WORKER w
       ${whereClause}
       ORDER BY ${dbSortColumn} ${dbOrder}`,
      binds,
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const allRows = workersResult.rows || [];
    const total = allRows.length;
    const totalPages = Math.ceil(total / limit) || 1;
    const offset = (page - 1) * limit;
    const pageRows = allRows.slice(offset, offset + limit);

    // ── YTD salary: direct SUM on pageRows only (optimized) ─────
    const enriched = await Promise.all(
      pageRows.map(async (w) => {
        let ytdSalary = 0;
        try {
          const ytdRes = await connection.execute(
            `SELECT NVL(SUM(net_salary), 0) AS ytd_salary
               FROM SALARY_RECORD
              WHERE worker_id = :wid AND year = :yr`,
            { wid: w.WORKER_ID, yr: year },
            { outFormat: oracledb.OUT_FORMAT_OBJECT }
          );
          ytdSalary = ytdRes.rows?.[0]?.YTD_SALARY ?? 0;
        } catch { /* leave as 0 */ }
        return {
          workerId:    w.WORKER_ID,
          fullName:    w.FULL_NAME,
          nationalId:  w.NATIONAL_ID,
          designation: w.DESIGNATION,
          joinDate:    w.JOIN_DATE,
          baseSalary:  w.BASE_SALARY,
          shift:       w.SHIFT,
          status:      w.STATUS,
          ytdSalary
        };
      })
    );

    res.json({ data: enriched, page, limit, total, totalPages });
  } catch (err) {
    // Return empty page instead of 500 so the UI degrades gracefully
    console.error('[workers route]', err.message);
    res.json({ data: [], page, limit, total: 0, totalPages: 1 });
  } finally {
    if (connection) {
      try { await connection.close(); } catch {}
    }
  }
});

/**
 * @route   GET /api/factories/:id/audits
 * @desc    Audit history via pkg_reporting.sp_get_audit_history REF CURSOR
 * @access  Public
 */
router.get('/:id/audits', async (req, res, next) => {
  const factoryId = parseInt(req.params.id, 10);
  if (isNaN(factoryId)) return res.status(400).json({ error: 'Invalid factory ID' });

  // Direct SELECT: avoids REF CURSOR dependency on pkg_reporting
  // fetchAsString ensures CLOB columns (findings, recommendations) come back
  // as plain JS strings instead of Lob stream objects that crash React.
  const sql = `
    SELECT
      a.audit_id        AS "auditId",
      a.audit_date      AS "auditDate",
      a.score           AS "score",
      a.result          AS "result",
      a.next_scheduled  AS "nextScheduled",
      u.full_name       AS "inspectorName",
      u.email           AS "inspectorEmail",
      DBMS_LOB.SUBSTR(a.findings, 4000, 1)        AS "findings",
      DBMS_LOB.SUBSTR(a.recommendations, 4000, 1) AS "recommendations"
    FROM "AUDIT" a
    JOIN USER_ u ON a.inspector_id = u.user_id
    WHERE a.factory_id = :fid
    ORDER BY a.audit_date DESC, a.audit_id DESC
  `;
  try {
    const result = await executeQuery(sql, { fid: factoryId });
    res.json(result.rows || []);
  } catch (err) {
    console.error('[audits route]', err.message);
    res.json([]);  // graceful empty fallback
  }
});

/**
 * @route   GET /api/factories/:id/certifications
 * @desc    All certifications with fn_is_cert_valid result included
 * @access  Public
 */
router.get('/:id/certifications', async (req, res, next) => {
  const factoryId = parseInt(req.params.id, 10);
  if (isNaN(factoryId)) return res.status(400).json({ error: 'Invalid factory ID' });

  // isValid logic replicated as a CASE expression — no fn_is_cert_valid dependency
  const sql = `
    SELECT
      c.cert_id                                          AS "certId",
      c.cert_name                                        AS "certName",
      c.issuing_body                                     AS "issuingBody",
      c.issue_date                                       AS "issueDate",
      c.expiry_date                                      AS "expiryDate",
      c.status                                           AS "status",
      CASE
        WHEN c.status = 'Active' AND c.expiry_date > SYSDATE THEN 'Y'
        ELSE 'N'
      END                                                AS "isValid",
      TRUNC(c.expiry_date) - TRUNC(SYSDATE)             AS "daysUntilExpiry"
    FROM CERTIFICATION c
    WHERE c.factory_id = :fid
    ORDER BY c.expiry_date ASC
  `;
  try {
    const result = await executeQuery(sql, { fid: factoryId });
    res.json(result.rows || []);
  } catch (err) {
    console.error('[certifications route]', err.message);
    res.json([]);  // graceful empty fallback
  }
});

/**
 * @route   GET /api/factories/:id/equipment-alerts
 * @desc    Calls fn_equipment_expiry_alert, parses CSV result into array
 * @access  Public
 */
router.get('/:id/equipment-alerts', async (req, res, next) => {
  const factoryId = parseInt(req.params.id, 10);
  if (isNaN(factoryId)) return res.status(400).json({ error: 'Invalid factory ID' });

  // Direct DISTINCT query — replicates fn_equipment_expiry_alert logic without the package
  const sql = `
    SELECT DISTINCT equipment_type AS "equipmentType"
    FROM   SAFETY_EQUIPMENT
    WHERE  factory_id  = :fid
      AND  expiry_date IS NOT NULL
      AND  expiry_date BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 30
    ORDER BY equipment_type
  `;
  try {
    const result = await executeQuery(sql, { fid: factoryId });
    const alerts = (result.rows || []).map(r => r.equipmentType);
    res.json({ allOk: alerts.length === 0, alerts });
  } catch (err) {
    console.error('[equipment-alerts route]', err.message);
    res.json({ allOk: true, alerts: [] });  // graceful fallback
  }
});

module.exports = router;
