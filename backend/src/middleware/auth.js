const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'garmentguard_secret_key';

/**
 * Middleware to verify httpOnly cookie or Bearer Authorization token.
 */
function verifyJWT(req, res, next) {
  let token = req.cookies?.token;
  if (!token && req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return res.status(401).json({ error: 'Authentication token required' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired authentication token' });
  }
}

/**
 * Middleware to restrict route access to specific roles.
 * Supports flexible alias mapping (e.g. Buyer_Representative <=> Buyer).
 */
function requireRole(allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const userRole = req.user.role;
    const hasRole = allowedRoles.some(role => {
      const cleanRole = role.toLowerCase().replace(/_/g, '');
      const cleanUserRole = userRole.toLowerCase().replace(/_/g, '');

      return (
        cleanRole === cleanUserRole ||
        (cleanRole === 'buyer' && cleanUserRole === 'buyerrepresentative') ||
        (cleanRole === 'buyerrepresentative' && cleanUserRole === 'buyer') ||
        (cleanRole === 'admin' && cleanUserRole === 'sysadmin')
      );
    });

    if (!hasRole) {
      return res.status(403).json({ error: 'Access denied: insufficient privileges' });
    }
    next();
  };
}

module.exports = {
  verifyJWT,
  requireRole
};
