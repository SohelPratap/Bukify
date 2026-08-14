import express from "express";
import {
  getAllSkills,
  searchSkills,
  addSkill,
  getMySkills,
  removeSkill
} from "../controllers/skills.controller.js";

import { requireAuth } from "../middlewares/auth.middleware.js";

const router = express.Router();

router.get("/", requireAuth, getAllSkills)

router.get("/search", requireAuth, searchSkills);

router.post("/add", requireAuth, addSkill);

router.get("/my", requireAuth, getMySkills);

router.delete("/remove/:skill_id", requireAuth, removeSkill);



export default router;