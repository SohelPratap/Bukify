import express from 'express';
import { requireAuth, requireRole } from '../middlewares/auth.middleware.js';
import { getWorkerProfile } from '../controllers/worker_profile.controller.js';

const router = express.Router();

router.get(
  '/profile',
  requireAuth,
  requireRole('worker'),
  getWorkerProfile
);

export default router;