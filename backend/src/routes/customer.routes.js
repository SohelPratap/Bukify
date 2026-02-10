import express from 'express';
import { requireAuth } from '../middlewares/auth.middleware.js';
import { requireRole } from '../middlewares/role.middleware.js';

const router = express.Router();

router.get(
  '/dashboard',
  requireAuth,
  requireRole('customer'),
  (req, res) => {
    res.json({
      message: 'Welcome customer',
      userId: req.user.userId,
    });
  }
);

export default router;