const { Router } = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { executeQuery } = require('../db/execute');

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'garmentguard_secret_key';

/**
 * @route   POST /api/auth/login
 * @desc    Validate credentials against USER_ table and issue httpOnly cookie JWT
 * @access  Public
 */
router.post('/login', async (req, res, next) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  try {
    const sql = `
      SELECT 
        user_id AS "userId", 
        username AS "username", 
        password_hash AS "passwordHash", 
        role AS "role", 
        factory_id AS "factoryId", 
        worker_id AS "workerId",
        buyer_id AS "buyerId",
        full_name AS "fullName"
      FROM USER_
      WHERE username = :username
    `;
    const result = await executeQuery(sql, { username });
    if (!result.rows || result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    // Sign JWT token
    const token = jwt.sign(
      { 
        userId: user.userId, 
        role: user.role, 
        factoryId: user.factoryId,
        workerId: user.workerId,
        buyerId: user.buyerId,
        fullName: user.fullName
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Set JWT in httpOnly cookie
    res.cookie('token', token, {
      httpOnly: true,
      secure: false, // Set to true if running over HTTPS in production
      sameSite: 'lax',
      maxAge: 24 * 60 * 60 * 1000 // 24 hours
    });

    res.json({
      message: 'Login successful',
      user: {
        userId: user.userId,
        username: user.username,
        role: user.role,
        factoryId: user.factoryId,
        workerId: user.workerId,
        fullName: user.fullName
      }
    });

  } catch (err) {
    next(err);
  }
});

/**
 * @route   GET /api/auth/me
 * @desc    Check current session status using cookie JWT
 * @access  Public
 */
router.get('/me', (req, res) => {
  const token = req.cookies?.token;
  if (!token) {
    return res.status(401).json({ error: 'Not authenticated' });
  }
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    res.json({ user: decoded });
  } catch (err) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

/**
 * @route   POST /api/auth/logout
 * @desc    Clear session cookie
 * @access  Public
 */
router.post('/logout', (req, res) => {
  res.clearCookie('token');
  res.json({ message: 'Logged out successfully' });
});

module.exports = router;
