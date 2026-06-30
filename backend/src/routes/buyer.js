const { Router } = require('express');
const { executeQuery } = require('../db/execute');
const { verifyJWT, requireRole } = require('../middleware/auth');

const router = Router();

// Protect all buyer endpoints
router.use(verifyJWT);
router.use(requireRole(['Buyer', 'Buyer_Representative', 'Admin', 'Compliance_Officer']));

/**
 * @route   GET /api/buyer/factories/:buyerId
 * @desc    Get factories linked to a specific buyer with compliance details (Backend 5)
 * @access  Private (Buyer or Admin/Compliance Officer)
 */
router.get('/factories/:buyerId', async (req, res, next) => {
  const buyerId = parseInt(req.params.buyerId, 10);
  if (isNaN(buyerId)) {
    return res.status(400).json({ error: 'Invalid buyer ID' });
  }

  const sql = `
    SELECT 
      bf.buyer_id AS "buyerId",
      f.factory_id AS "factoryId",
      f.factory_name AS "factoryName",
      f.registration_no AS "registrationNo",
      f.address AS "address",
      f.district AS "district",
      f.compliance_status AS "complianceStatus",
      f.compliance_score AS "complianceScore",
      f.latest_audit_score AS "latestAuditScore",
      f.active_certs_count AS "activeCertsCount",
      bf.contract_status AS "contractStatus",
      TO_CHAR(bf.since_date, 'YYYY-MM-DD') AS "sinceDate"
    FROM BUYER_FACTORY bf
    JOIN vw_factory_compliance f ON bf.factory_id = f.factory_id
    WHERE bf.buyer_id = :buyerId
    ORDER BY f.factory_name
  `;
  try {
    const result = await executeQuery(sql, { buyerId });
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

/**
 * @route   GET /api/buyer/factory/:factoryId/certifications
 * @desc    Get read-only certifications list for a factory (Backend 6)
 * @access  Private (Buyer or Admin/Compliance Officer)
 */
router.get('/factory/:factoryId/certifications', async (req, res, next) => {
  const factoryId = parseInt(req.params.factoryId, 10);
  if (isNaN(factoryId)) {
    return res.status(400).json({ error: 'Invalid factory ID' });
  }

  const sql = `
    SELECT 
      cert_id AS "certId",
      cert_name AS "certName",
      issuing_body AS "issuingBody",
      TO_CHAR(issue_date, 'YYYY-MM-DD') AS "issueDate",
      TO_CHAR(expiry_date, 'YYYY-MM-DD') AS "expiryDate",
      status AS "status"
    FROM CERTIFICATION
    WHERE factory_id = :factoryId
    ORDER BY expiry_date DESC
  `;
  try {
    const result = await executeQuery(sql, { factoryId });
    res.json(result.rows || []);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
