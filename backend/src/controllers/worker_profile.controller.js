import db from '../config/db.js';
import pool from "../config/db.js";

// GET WORKER PROFILE
export const getWorkerProfile = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [rows] = await db.query(
      `SELECT
          u.email,
          u.is_online,
          w.full_name,
          w.skills,
          w.experience_years,
          w.is_verified,
          w.rating,
          w.created_at
       FROM users u
       JOIN worker_profile w ON u.id = w.user_id
       WHERE u.id = ?`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Worker profile not found' });
    }

    res.json(rows[0]);

  } catch (error) {
    console.error("Worker profile error 👉", error);
    res.status(500).json({ message: 'Server error' });
  }
};



export const toggleOnline = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { is_online } = req.body;

    await pool.execute(
      `UPDATE users
       SET is_online = ?
       WHERE id = ?`,
      [is_online ? 1 : 0, userId]
    );

    res.json({
      message: "Online status updated",
      is_online: is_online
    });

  } catch (err) {
    console.error("Toggle online error:", err);
    res.status(500).json({ error: "Server error" });
  }
};

export const updateServiceArea = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { latitude, longitude, radius_km } = req.body;

    if (!latitude || !longitude || !radius_km) {
      return res.status(400).json({ message: "Missing data" });
    }

    await pool.execute(
      `INSERT INTO worker_service_areas
       (worker_id, center_lat, center_lng, radius_km)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
       center_lat = VALUES(center_lat),
       center_lng = VALUES(center_lng),
       radius_km = VALUES(radius_km)`,
      [userId, latitude, longitude, radius_km]
    );

    res.json({ message: "Service area updated" });

  } catch (err) {
    console.error("Service area error:", err);
    res.status(500).json({ message: "Server error" });
  }
};

export const getServiceArea = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [rows] = await pool.execute(
      `SELECT center_lat, center_lng, radius_km
       FROM worker_service_areas
       WHERE worker_id = ?`,
      [userId]
    );

    if (rows.length === 0) {
      return res.json(null); // no area set yet
    }

    res.json(rows[0]);

  } catch (err) {
    console.error("Get service area error:", err);
    res.status(500).json({ message: "Server error" });
  }
};