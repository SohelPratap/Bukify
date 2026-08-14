import express from "express";
import { updateLocation } from "../controllers/location.controller.js";
import { requireAuth } from "../middlewares/auth.middleware.js";

const router = express.Router();

router.post("/update", requireAuth, updateLocation);

export default router;