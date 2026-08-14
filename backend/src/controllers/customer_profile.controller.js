import db from '../config/db.js';

// GET CUSTOMER PROFILE
export const getCustomerProfile = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [rows] = await db.query(
      `SELECT
          u.email,
          c.display_name,
          c.organization,
          c.created_at
       FROM users u
       JOIN customer_profile c ON u.id = c.user_id
       WHERE u.id = ?`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Customer profile not found' });
    }

    res.json(rows[0]);

  } catch (error) {
    console.error("Customer profile error 👉", error);
    res.status(500).json({ message: 'Server error' });
  }
};