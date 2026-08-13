const express = require("express");
const { v4: uuid } = require("uuid");
const db = require("../db");
const { requireAuth, requireOwner } = require("../middleware/auth");
const { emitStationUpdate, emitQueueUpdate } = require("../socket");

const router = express.Router();

// POST /api/bookings — driver books a queue slot at a station
router.post("/", requireAuth, (req, res) => {
  const { station_id, fuel_type } = req.body;
  if (!station_id) return res.status(400).json({ error: "station_id is required" });

  const station = db.prepare("SELECT * FROM stations WHERE id = ?").get(station_id);
  if (!station) return res.status(404).json({ error: "Station not found" });
  if (!station.is_available) {
    return res.status(400).json({ error: "This station currently has no fuel available" });
  }

  const booking = {
    id: uuid(),
    user_id: req.user.id,
    station_id,
    queue_number: station.next_queue_number,
    status: "confirmed",
    fuel_type: fuel_type || null,
  };

  const tx = db.transaction(() => {
    db.prepare(
      `INSERT INTO bookings (id, user_id, station_id, queue_number, status, fuel_type)
       VALUES (@id, @user_id, @station_id, @queue_number, @status, @fuel_type)`
    ).run(booking);

    db.prepare(
      `UPDATE stations
       SET queue_count = queue_count + 1,
           next_queue_number = next_queue_number + 1,
           updated_at = datetime('now')
       WHERE id = ?`
    ).run(station_id);
  });
  tx();

  const updatedStation = db.prepare("SELECT * FROM stations WHERE id = ?").get(station_id);
  emitStationUpdate(updatedStation);
  emitQueueUpdate(station_id, { type: "new_booking", booking });

  res.status(201).json({ booking, station: updatedStation });
});

// GET /api/bookings/user/:userId — driver's bookings (own only)
router.get("/user/:userId", requireAuth, (req, res) => {
  if (req.user.id !== req.params.userId) {
    return res.status(403).json({ error: "Cannot view another user's bookings" });
  }
  const rows = db
    .prepare(
      `SELECT b.*, s.name_ar as station_name_ar, s.name as station_name, s.address
       FROM bookings b JOIN stations s ON s.id = b.station_id
       WHERE b.user_id = ? ORDER BY b.created_at DESC`
    )
    .all(req.params.userId);
  res.json({ bookings: rows });
});

// GET /api/bookings/station/:stationId — owner's live queue for their station
router.get("/station/:stationId", requireAuth, requireOwner, (req, res) => {
  if (req.user.station_id !== req.params.stationId) {
    return res.status(403).json({ error: "You do not own this station" });
  }
  const rows = db
    .prepare(
      `SELECT b.*, u.name as driver_name, u.phone as driver_phone
       FROM bookings b JOIN users u ON u.id = b.user_id
       WHERE b.station_id = ? AND b.status IN ('pending','confirmed')
       ORDER BY b.queue_number ASC`
    )
    .all(req.params.stationId);
  res.json({ bookings: rows });
});

// PATCH /api/bookings/:id/complete — owner marks a booking as fulfilled (QR scan)
router.patch("/:id/complete", requireAuth, requireOwner, (req, res) => {
  const booking = db.prepare("SELECT * FROM bookings WHERE id = ?").get(req.params.id);
  if (!booking) return res.status(404).json({ error: "Booking not found" });
  if (req.user.station_id !== booking.station_id) {
    return res.status(403).json({ error: "You do not own this station" });
  }
  if (booking.status === "completed") {
    return res.status(400).json({ error: "Booking already completed" });
  }

  const tx = db.transaction(() => {
    db.prepare(
      "UPDATE bookings SET status = 'completed', completed_at = datetime('now') WHERE id = ?"
    ).run(booking.id);
    db.prepare(
      `UPDATE stations SET queue_count = MAX(queue_count - 1, 0), updated_at = datetime('now')
       WHERE id = ?`
    ).run(booking.station_id);
  });
  tx();

  const updatedBooking = db.prepare("SELECT * FROM bookings WHERE id = ?").get(booking.id);
  const updatedStation = db.prepare("SELECT * FROM stations WHERE id = ?").get(booking.station_id);

  emitStationUpdate(updatedStation);
  emitQueueUpdate(booking.station_id, { type: "booking_completed", booking: updatedBooking });

  res.json({ booking: updatedBooking, station: updatedStation });
});

// PATCH /api/bookings/:id/cancel — driver cancels their own booking
router.patch("/:id/cancel", requireAuth, (req, res) => {
  const booking = db.prepare("SELECT * FROM bookings WHERE id = ?").get(req.params.id);
  if (!booking) return res.status(404).json({ error: "Booking not found" });
  if (booking.user_id !== req.user.id) {
    return res.status(403).json({ error: "Cannot cancel another user's booking" });
  }

  const tx = db.transaction(() => {
    db.prepare("UPDATE bookings SET status = 'cancelled' WHERE id = ?").run(booking.id);
    db.prepare(
      `UPDATE stations SET queue_count = MAX(queue_count - 1, 0), updated_at = datetime('now')
       WHERE id = ?`
    ).run(booking.station_id);
  });
  tx();

  const updatedStation = db.prepare("SELECT * FROM stations WHERE id = ?").get(booking.station_id);
  emitStationUpdate(updatedStation);
  emitQueueUpdate(booking.station_id, { type: "booking_cancelled", booking_id: booking.id });

  res.json({ ok: true });
});

module.exports = router;
