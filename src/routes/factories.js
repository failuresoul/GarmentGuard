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

module.exports = router;
