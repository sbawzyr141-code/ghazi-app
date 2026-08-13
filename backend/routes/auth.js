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
  if (!name || !email || !password) {
    return res.status(400).json({ error: "name, email, and password are required" });
  }

  const existing = db.prepare("SELECT id FROM users WHERE email = ?").get(email);
  if (existing) return res.status(409).json({ error: "Email already registered" });

  const user = {
    id: uuid(),
    name,
    email,
    phone: phone || null,
    password_hash: bcrypt.hashSync(password, 10),
    role: role === "owner" ? "owner" : "driver",
    station_id: null,
  };

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
