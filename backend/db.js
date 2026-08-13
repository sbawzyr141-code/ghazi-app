// db.js — SQLite connection + schema bootstrap for Ghazi (غازي)
const path = require("path");
const Database = require("better-sqlite3");

const DB_PATH = path.join(__dirname, "ghazi.db");
const db = new Database(DB_PATH);

db.pragma("journal_mode = WAL");
db.pragma("foreign_keys = ON");

db.exec(`
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'driver', -- 'driver' | 'owner'
  station_id TEXT,                     -- set when role = 'owner'
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS stations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  address TEXT,
  neighborhood TEXT,
  lat REAL,
  lng REAL,
  fuel_types TEXT,           -- comma separated: petrol91,petrol95,diesel
  is_available INTEGER NOT NULL DEFAULT 1, -- 1 = has fuel, 0 = out
  queue_count INTEGER NOT NULL DEFAULT 0,
  next_queue_number INTEGER NOT NULL DEFAULT 1,
  image_url TEXT,
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS bookings (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  station_id TEXT NOT NULL REFERENCES stations(id),
  queue_number INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending | confirmed | completed | cancelled
  fuel_type TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  completed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_station ON bookings(station_id);
`);

module.exports = db;
