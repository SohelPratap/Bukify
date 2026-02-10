const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');

async function registerUser({ email, password, role }) {
  const [existing] = await db.query(
    'SELECT id FROM users WHERE email = ?',
    [email]
  );

  if (existing.length > 0) {
    throw new Error('Email already registered');
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const userId = uuidv4();

  await db.query(
    'INSERT INTO users (id, email, password_hash, role) VALUES (?, ?, ?, ?)',
    [userId, email, passwordHash, role]
  );

  if (role === 'worker') {
    await db.query(
      'INSERT INTO worker_profile (user_id) VALUES (?)',
      [userId]
    );
  } else {
    await db.query(
      'INSERT INTO requester_profile (user_id) VALUES (?)',
      [userId]
    );
  }

  return { userId, email, role };
}

async function loginUser({ email, password }) {
  const [rows] = await db.query(
    'SELECT * FROM users WHERE email = ?',
    [email]
  );

  if (rows.length === 0) {
    throw new Error('Invalid credentials');
  }

  const user = rows[0];
  const isMatch = await bcrypt.compare(password, user.password_hash);

  if (!isMatch) {
    throw new Error('Invalid credentials');
  }

  return {
    id: user.id,
    email: user.email,
    role: user.role,
  };
}

module.exports = { registerUser, loginUser };