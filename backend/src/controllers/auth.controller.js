import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import db from '../config/db.js';

export const register = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    if (!email || !password || !role) {
      return res.status(400).json({ message: 'Missing fields' });
    }

    // ✅ UPDATED ROLE CHECK
    if (!['worker', 'customer'].includes(role)) {
      return res.status(400).json({ message: 'Invalid role' });
    }

    const [existing] = await db.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (existing.length > 0) {
      return res.status(409).json({ message: 'Email already exists' });
    }

    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 10);

    // Insert into users
    await db.query(
      `INSERT INTO users (id, email, password_hash, role)
       VALUES (?, ?, ?, ?)`,
      [userId, email, passwordHash, role]
    );

    // Insert profile based on role
    if (role === 'worker') {
      await db.query(
        'INSERT INTO worker_profile (user_id) VALUES (?)',
        [userId]
      );
    } else if (role === 'customer') {
      await db.query(
        'INSERT INTO customer_profile (user_id) VALUES (?)',
        [userId]
      );
    }

    const token = jwt.sign(
      { userId, role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'Registered successfully',
      token,
      role
    });

  } catch (err) {
      console.error('ERROR 👉', err);
      return res.status(500).json({
        message: err.sqlMessage || err.message || err
      });
    }
};

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const [rows] = await db.query(
      'SELECT * FROM users WHERE email = ? AND is_active = 1',
      [email]
    );

    if (rows.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = rows[0];

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      role: user.role
    });

  } catch (err) {
      console.error('ERROR 👉', err);
      return res.status(500).json({
        message: err.sqlMessage || err.message || err
      });
    }
};