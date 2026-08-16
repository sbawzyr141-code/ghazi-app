const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { v4: uuid } = require("uuid");
const db = require("../db");
const { JWT_SECRET } = require("../middleware/auth");

const router = express.Router();

function signToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, role: user.role, station_id: user.station_id },
    JWT_SECRET,
    { expiresIn: "30d" }
  );
}

function sanitize(user) {
  const { password_hash, ...rest } = user;
  return rest;
}

// POST /api/auth/register
router.post("/register", (req, res) => {
  const { name, email, phone, password, role } = req.body;
  // optional station fields for station_owner
  const { station_name, station_license } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ error: "name, email, and password are required" });
  }

  const existing = db.prepare("SELECT id FROM users WHERE email = ?").get(email);
  if (existing) return res.status(409).json({ error: "Email already registered" });

  const userId = uuid();
  const user = {
    id: userId,
    name,
    email,
    phone: phone || null,
    password_hash: bcrypt.hashSync(password, 10),
    role: role === "station_owner" ? "station_owner" : "driver",
    station_id: null,
  };

  // If registering a station owner, create the station record and link it
  if (user.role === 'station_owner') {
    if (!station_name || !station_license) {
      return res.status(400).json({ error: 'station_name and station_license are required for station_owner' });
    }
    const stationId = uuid();
    db.prepare(
      `INSERT INTO stations (id, name, name_ar, address, station_license, updated_at)
       VALUES (?, ?, ?, ?, ?, datetime('now'))`
    ).run(stationId, station_name, station_name, null, station_license);

    user.station_id = stationId;
  }

  db.prepare(
    `INSERT INTO users (id, name, email, phone, password_hash, role, station_id)
     VALUES (@id, @name, @email, @phone, @password_hash, @role, @station_id)`
  ).run(user);

  const token = signToken(user);
  res.status(201).json({ token, user: sanitize(user) });
});

// POST /api/auth/login
router.post("/login", (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: "email and password are required" });
  }

  const user = db.prepare("SELECT * FROM users WHERE email = ?").get(email);
  if (!user || !bcrypt.compareSync(password, user.password_hash)) {
    return res.status(401).json({ error: "Invalid email or password" });
  }

  const token = signToken(user);
  res.json({ token, user: sanitize(user) });
});

// GET /api/auth/me
const { requireAuth } = require("../middleware/auth");
router.get("/me", requireAuth, (req, res) => {
  const user = db.prepare("SELECT * FROM users WHERE id = ?").get(req.user.id);
  if (!user) return res.status(404).json({ error: "User not found" });
  res.json({ user: sanitize(user) });
});

module.exports = router;

// Public helper: GET /api/auth/user?email=... or ?phone=...
router.get('/user', (req, res) => {
  const { email, phone } = req.query;
  if (!email && !phone) return res.status(400).json({ error: 'email or phone is required' });
  let user;
  if (email) {
    user = db.prepare('SELECT id, name, email, phone, role, station_id, created_at FROM users WHERE email = ?').get(email);
  } else {
    user = db.prepare('SELECT id, name, email, phone, role, station_id, created_at FROM users WHERE phone = ?').get(phone);
  }
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json({ user });
});
