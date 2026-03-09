import express from "express";
import { requireAuth } from '../middlewares/auth.middleware.js';
import {
  createJob,
  getMyActiveJobs,
  getMyPastJobs,
  cancelJob,
  getNearbyJobs,
  startJob,
  completeJob,
  getWorkerActiveJobs,
  getWorkerCompletedJobs,
  searchJobs,
  getJobsForMap
} from "../controllers/jobs.controller.js";

const router = express.Router();

router.post("/", requireAuth, createJob);
router.get("/nearby", requireAuth, getNearbyJobs);
router.put("/:id/start", requireAuth, startJob);
router.get("/my/active", requireAuth, getMyActiveJobs);
router.get("/my/history", requireAuth, getMyPastJobs);
router.put("/:id/cancel", requireAuth, cancelJob);
router.put("/:id/complete", requireAuth, completeJob);
router.get("/worker/active", requireAuth, getWorkerActiveJobs);
router.get("/worker/completed", requireAuth, getWorkerCompletedJobs);
router.get("/search", requireAuth, searchJobs);
router.get("/map", requireAuth, getJobsForMap);

export default router;