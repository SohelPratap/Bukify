import { v4 as uuidv4 } from "uuid";
import pool from "../config/db.js";

/* ======================================================
   CREATE JOB
====================================================== */

export const createJob = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { skill_id, address_id, title, description } = req.body;

    if (!skill_id || !address_id || !title) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    // Get address lat/lng
    const [addrRows] = await pool.execute(
      `SELECT latitude, longitude
       FROM customer_addresses
       WHERE id = ? AND user_id = ?`,
      [address_id, userId]
    );

    if (addrRows.length === 0) {
      return res.status(400).json({ message: "Invalid address" });
    }

    const { latitude, longitude } = addrRows[0];

    const jobId = uuidv4();

    await pool.execute(
      `INSERT INTO jobs
       (id, customer_id, address_id, skill_id, title, description, latitude, longitude)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        jobId,
        userId,
        address_id,
        skill_id,
        title,
        description || null,
        latitude,
        longitude
      ]
    );

    res.json({ message: "Job created successfully" });

  } catch (err) {
    console.error("Create job error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

/* ======================================================
   CUSTOMER HISTORY
====================================================== */

export const getMyActiveJobs = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [rows] = await pool.execute(
      `SELECT j.*, s.name AS skill_name
       FROM jobs j
       JOIN skills s ON j.skill_id = s.id
       WHERE j.customer_id = ?
       AND j.status IN ('open','accepted','in_progress')
       ORDER BY j.created_at DESC`,
      [userId]
    );

    res.json(rows);

  } catch (err) {
    console.error("Active jobs error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

export const getMyPastJobs = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [rows] = await pool.execute(
      `SELECT j.*, s.name AS skill_name
       FROM jobs j
       JOIN skills s ON j.skill_id = s.id
       WHERE j.customer_id = ?
       AND j.status IN ('completed','cancelled')
       ORDER BY j.created_at DESC`,
      [userId]
    );

    res.json(rows);

  } catch (err) {
    console.error("Past jobs error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

/* ======================================================
   CUSTOMER CANCEL JOB
====================================================== */

export const cancelJob = async (req, res) => {
  try {
    const userId = req.user.userId;
    const jobId = req.params.id;

    const [result] = await pool.execute(
      `UPDATE jobs
       SET status = 'cancelled'
       WHERE id = ?
       AND customer_id = ?
       AND status IN ('open','accepted')`,
      [jobId, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(400).json({
        message: "Cannot cancel this job"
      });
    }

    res.json({ message: "Job cancelled successfully" });

  } catch (err) {
    console.error("Cancel job error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

/* ======================================================
   WORKER NEARBY JOBS
   - Skill match
   - Status = open
   - Inside worker radius (Haversine formula)
====================================================== */

export const getNearbyJobs = async (req, res) => {
  try {
    const workerId = req.user.userId;

    const [rows] = await pool.execute(
      `
      SELECT j.*, s.name AS skill_name
      FROM jobs j
      JOIN skills s ON j.skill_id = s.id
      JOIN worker_skills ws
        ON ws.skill_id = j.skill_id
      JOIN worker_service_areas wsa
        ON wsa.worker_id = ws.worker_id
      WHERE ws.worker_id = ?
        AND ws.status = 'approved'
        AND j.status = 'open'
        AND (
          6371 * ACOS(
            COS(RADIANS(wsa.center_lat)) *
            COS(RADIANS(j.latitude)) *
            COS(RADIANS(j.longitude) - RADIANS(wsa.center_lng)) +
            SIN(RADIANS(wsa.center_lat)) *
            SIN(RADIANS(j.latitude))
          )
        ) <= wsa.radius_km
      ORDER BY j.created_at DESC
      `,
      [workerId]
    );

    res.json(rows);

  } catch (err) {
    console.error("Nearby jobs error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

/* ======================================================
   ACCEPT JOB
   - Only if status = open
   - Prevent race condition
====================================================== */

export const acceptJob = async (req, res) => {
  try {
    const workerId = req.user.userId;
    const jobId = req.params.id;

    const [result] = await pool.execute(
      `UPDATE jobs
       SET accepted_by = ?, status = 'accepted'
       WHERE id = ? AND status = 'open'`,
      [workerId, jobId]
    );

    if (result.affectedRows === 0) {
      return res.status(400).json({
        message: "Job already taken or not available"
      });
    }

    res.json({ message: "Job accepted successfully" });

  } catch (err) {
    console.error("Accept job error:", err);
    res.status(500).json({ message: "Server error" });
  }
};
