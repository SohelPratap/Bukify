import express from 'express';
import { requireAuth, requireRole } from '../middlewares/auth.middleware.js';
import { getCustomerProfile } from '../controllers/customer_profile.controller.js';

const router = express.Router();

router.get(
  '/profile',
  requireAuth,
  requireRole('customer'),
  getCustomerProfile
);

export default router;