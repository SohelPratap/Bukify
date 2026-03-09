import express from 'express';
import { requireAuth } from '../middlewares/auth.middleware.js';
import { requireRole } from '../middlewares/role.middleware.js';
import {
  toggleOnline,
  updateServiceArea,
  getServiceArea,
  searchWorkers,
  getWorkersForMap
} from "../controllers/worker_profile.controller.js";

const router = express.Router();

router.get(
  '/dashboard',
  requireAuth,
  requireRole('worker'),
  (req, res) => {
    res.json({
      message: 'Welcome worker',
      userId: req.user.userId,
    });
  }
);

router.post("/toggle-online", requireAuth, toggleOnline);
router.post("/service-area", requireAuth, updateServiceArea);
router.get("/service-area", requireAuth, getServiceArea);
router.get("/search", requireAuth, searchWorkers);
router.get("/map", requireAuth, getWorkersForMap);

export default router;