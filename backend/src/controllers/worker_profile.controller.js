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

export const searchWorkers = async (req, res) => {
  try {
    const { skill, lat, lng } = req.query;

    if (!skill || !lat || !lng) {
      return res.status(400).json({ message: "skill, lat, lng required" });
    }

    const [rows] = await pool.execute(
      `
      SELECT
        u.id,
        u.email,
        u.is_online,
        wp.full_name,
        wp.experience_years,
        wp.rating,
        wsa.radius_km,

        GROUP_CONCAT(DISTINCT s.name ORDER BY s.name SEPARATOR ', ') AS skills_list,

        (
          6371 * ACOS(
            LEAST(1, COS(RADIANS(?)) * COS(RADIANS(wsa.center_lat)) *
            COS(RADIANS(wsa.center_lng) - RADIANS(?)) +
            SIN(RADIANS(?)) * SIN(RADIANS(wsa.center_lat)))
          )
        ) AS distance_km

      FROM users u
      JOIN worker_profile wp ON u.id = wp.user_id
      JOIN worker_service_areas wsa ON u.id = wsa.worker_id

      -- get all skills regardless of approval status
      LEFT JOIN worker_skills ws ON u.id = ws.worker_id
      LEFT JOIN skills s ON ws.skill_id = s.id

      WHERE u.role = 'worker'

        -- customer must be inside worker's service area
        AND (
          6371 * ACOS(
            LEAST(1, COS(RADIANS(?)) * COS(RADIANS(wsa.center_lat)) *
            COS(RADIANS(wsa.center_lng) - RADIANS(?)) +
            SIN(RADIANS(?)) * SIN(RADIANS(wsa.center_lat)))
          )
        ) <= wsa.radius_km

        -- skill name match against ANY skill (pending or approved)
        AND u.id IN (
          SELECT ws2.worker_id
          FROM worker_skills ws2
          JOIN skills s2 ON ws2.skill_id = s2.id
          WHERE s2.name LIKE ?
        )

      GROUP BY
        u.id, u.email, u.is_online,
        wp.full_name, wp.experience_years,
        wp.rating, wsa.radius_km

      ORDER BY distance_km ASC
      LIMIT 30
      `,
      [
        parseFloat(lat), parseFloat(lng), parseFloat(lat),  // distance_km select
        parseFloat(lat), parseFloat(lng), parseFloat(lat),  // WHERE distance filter
        `%${skill}%`,                                        // skill name match
      ]
    );

    res.json(rows);

  } catch (err) {
    console.error("Search workers error:", err);
    res.status(500).json({ message: "Server error" });
  }
};



export const getWorkersForMap = async (req, res) => {
  try {
    const { skill, lat, lng } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ message: "lat, lng required" });
    }

    const [rows] = await pool.execute(
      `
      SELECT
        u.id,
        u.email,
        u.is_online,
        wp.full_name,
        wp.rating,
        wp.experience_years,
        ul.latitude,
        ul.longitude,
        wsa.radius_km,

        GROUP_CONCAT(DISTINCT s.name ORDER BY s.name SEPARATOR ', ') AS skills_list,

        ROUND(
          6371 * ACOS(
            LEAST(1.0, GREATEST(-1.0,
              COS(RADIANS(?)) * COS(RADIANS(ul.latitude)) *
              COS(RADIANS(ul.longitude) - RADIANS(?)) +
              SIN(RADIANS(?)) * SIN(RADIANS(ul.latitude))
            ))
          ), 2
        ) AS distance_km

      FROM users u
      JOIN worker_profile wp ON u.id = wp.user_id
      JOIN worker_service_areas wsa ON u.id = wsa.worker_id
      JOIN user_locations ul ON u.id = ul.user_id
      LEFT JOIN worker_skills ws ON u.id = ws.worker_id
      LEFT JOIN skills s ON ws.skill_id = s.id

      WHERE u.role = 'worker'
        ${skill ? "AND u.id IN (SELECT ws2.worker_id FROM worker_skills ws2 JOIN skills s2 ON ws2.skill_id = s2.id WHERE s2.name LIKE ?)" : ""}

      GROUP BY
        u.id, u.email, u.is_online, wp.full_name,
        wp.rating, wp.experience_years,
        ul.latitude, ul.longitude, wsa.radius_km

      ORDER BY distance_km ASC
      LIMIT 50
      `,
      skill
        ? [parseFloat(lat), parseFloat(lng), parseFloat(lat), `%${skill}%`]
        : [parseFloat(lat), parseFloat(lng), parseFloat(lat)]
    );

    res.json(rows);

  } catch (err) {
    console.error("Map workers error:", err);
    res.status(500).json({ message: "Server error" });
  }
};