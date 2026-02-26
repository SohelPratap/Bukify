import pool from "../config/db.js";

export const updateLocation = async (req, res) => {
  try {

    const userId = req.user.userId;
    const { latitude, longitude, accuracy, heading, speed } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ message: "Latitude & Longitude required" });
    }

    await pool.execute(
      `
      INSERT INTO user_locations
      (user_id, latitude, longitude, accuracy, heading, speed)
      VALUES (?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        latitude = VALUES(latitude),
        longitude = VALUES(longitude),
        accuracy = VALUES(accuracy),
        heading = VALUES(heading),
        speed = VALUES(speed),
        updated_at = CURRENT_TIMESTAMP
      `,
      [userId, latitude, longitude, accuracy, heading, speed]
    );

    res.json({ message: "Location updated" });

  } catch (err) {
    console.error("Location update error:", err);
    res.status(500).json({ error: "Server error" });
  }
};