import jwt from 'jsonwebtoken';

export const requireAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // decoded = { userId, role, iat, exp }
    req.user = decoded;

    next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
};


// 🔐 Role-based guard
export const requireRole = (role) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (req.user.role !== role) {
      return res.status(403).json({ message: 'Forbidden: Access denied' });
    }

    next();
  };
};