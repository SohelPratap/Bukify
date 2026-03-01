import express from "express";
import { requireAuth } from '../middlewares/auth.middleware.js';
import {
  createJob,
  getMyActiveJobs,
  getMyPastJobs,
  cancelJob,
  getNearbyJobs,
  acceptJob
} from "../controllers/jobs.controller.js";

const router = express.Router();

router.post("/", requireAuth, createJob);
router.get("/nearby", requireAuth, getNearbyJobs);
router.post("/:id/accept", requireAuth, acceptJob);
router.get("/my/active", requireAuth, getMyActiveJobs);
router.get("/my/history", requireAuth, getMyPastJobs);
router.put("/:id/cancel", requireAuth, cancelJob);

export default router;