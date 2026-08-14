import crypto from "crypto";
import pool from "../config/db.js";

export const addAddress = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { label, address, latitude, longitude, is_default } = req.body;

    if (latitude == null || longitude == null) {
      return res.status(400).json({ message: "Location required" });
    }

    if (is_default) {
      await pool.execute(
        `UPDATE customer_addresses
         SET is_default = 0
         WHERE user_id = ?`,
        [userId]
      );
    }

    const id = crypto.randomUUID();

    await pool.execute(
      `INSERT INTO customer_addresses
       (id, user_id, label, address, latitude, longitude, is_default)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [id, userId, label, address, latitude, longitude, is_default ? 1 : 0]
    );

    res.json({ message: "Address added" });

  } catch (err) {
    console.error("Add address error:", err);
    res.status(500).json({ message: "Server error" });
  }
};




export const getAddresses = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [rows] = await pool.execute(
      `SELECT * FROM customer_addresses
        WHERE user_id = ? AND is_deleted = 0
        ORDER BY is_default DESC, created_at DESC`,
      [userId]
    );

    res.json(rows);

  } catch (err) {
    console.error("Get address error:", err);
    res.status(500).json({ message: "Server error" });
  }
};



export const deleteAddress = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;

    await pool.execute(
      `UPDATE customer_addresses
       SET is_deleted = 1
       WHERE id = ? AND user_id = ?`,
      [id, userId]
    );

    res.json({ message: "Address deleted" });
  } catch (err) {
    console.error("Delete address error:", err);
    res.status(500).json({ message: "Server error" });
  }
};



export const setDefaultAddress = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;

    await pool.execute(
      `UPDATE customer_addresses
       SET is_default = 0
       WHERE user_id = ?`,
      [userId]
    );

    await pool.execute(
      `UPDATE customer_addresses
       SET is_default = 1
       WHERE id = ? AND user_id = ?`,
      [id, userId]
    );

    res.json({ message: "Default updated" });

  } catch (err) {
    console.error("Set default error:", err);
    res.status(500).json({ message: "Server error" });
  }
};


export const searchAddresses = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { q } = req.query;

    if (!q || q.trim() === "") {
      return res.json([]);
    }

    const [rows] = await pool.execute(
      `SELECT id, label, address, latitude, longitude, is_default
       FROM customer_addresses
       WHERE user_id = ? AND is_deleted = 0
       AND (label LIKE ? OR address LIKE ?)
       ORDER BY is_default DESC, created_at DESC
       LIMIT 10`,
      [userId, `%${q}%`, `%${q}%`]
    );

    res.json(rows);

  } catch (err) {
    console.error("Search address error:", err);
    res.status(500).json({ message: "Server error" });
  }
};