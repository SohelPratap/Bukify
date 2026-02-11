import db from '../config/db.js';

// GET WORKER PROFILE
export const getWorkerProfile = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [rows] = await db.query(
      `SELECT
          u.email,
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