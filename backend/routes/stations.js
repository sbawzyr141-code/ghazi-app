const express = require("express");
const db = require("../db");
const { requireAuth, requireOwner } = require("../middleware/auth");
const { emitStationUpdate } = require("../socket");

const router = express.Router();

// GET /api/stations — list all, with optional ?available=1 filter
router.get("/", (req, res) => {
  const { available } = req.query;
  let rows;
  if (available === "1") {
    rows = db.prepare("SELECT * FROM stations WHERE is_available = 1 ORDER BY name_ar").all();
  } else {
    rows = db.prepare("SELECT * FROM stations ORDER BY name_ar").all();
  }
  res.json({ stations: rows });
});

// GET /api/stations/:id
router.get("/:id", (req, res) => {
  const station = db.prepare("SELECT * FROM stations WHERE id = ?").get(req.params.id);
  if (!station) return res.status(404).json({ error: "Station not found" });
  res.json({ station });
});

// PATCH /api/stations/:id/toggle — owner flips fuel availability (auto-computed
// queue_count is also reset to 0 when a station goes from unavailable -> available)
router.patch("/:id/toggle", requireAuth, requireOwner, (req, res) => {
  const station = db.prepare("SELECT * FROM stations WHERE id = ?").get(req.params.id);
  if (!station) return res.status(404).json({ error: "Station not found" });
  if (req.user.station_id !== station.id) {
    return res.status(403).json({ error: "You do not own this station" });
  }

  const newAvailability = station.is_available ? 0 : 1;
  db.prepare(
    "UPDATE stations SET is_available = ?, updated_at = datetime('now') WHERE id = ?"
  ).run(newAvailability, station.id);

  const updated = db.prepare("SELECT * FROM stations WHERE id = ?").get(station.id);
  emitStationUpdate(updated);
  res.json({ station: updated });
});

// PATCH /api/stations/:id — owner updates general info (name, address, fuel types)
router.patch("/:id", requireAuth, requireOwner, (req, res) => {
  const station = db.prepare("SELECT * FROM stations WHERE id = ?").get(req.params.id);
  if (!station) return res.status(404).json({ error: "Station not found" });
  if (req.user.station_id !== station.id) {
    return res.status(403).json({ error: "You do not own this station" });
  }

  const fields = ["name", "name_ar", "address", "neighborhood", "fuel_types", "image_url"];
  const updates = {};
  for (const f of fields) {
    if (req.body[f] !== undefined) updates[f] = req.body[f];
  }

  const setClause = Object.keys(updates).map((k) => `${k} = @${k}`).join(", ");
  if (setClause) {
    db.prepare(
      `UPDATE stations SET ${setClause}, updated_at = datetime('now') WHERE id = @id`
    ).run({ ...updates, id: station.id });
  }

  const updated = db.prepare("SELECT * FROM stations WHERE id = ?").get(station.id);
  emitStationUpdate(updated);
  res.json({ station: updated });
});

module.exports = router;
