import express from "express";
import {
  searchSkills,
  addSkill,
  getMySkills
} from "../controllers/skills.controller.js";

import { requireAuth } from "../middlewares/auth.middleware.js";

const router = express.Router();

router.get("/search", requireAuth, searchSkills);

router.post("/add", requireAuth, addSkill);

router.get("/my", requireAuth, getMySkills);

export default router;