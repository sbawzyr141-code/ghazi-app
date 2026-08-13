const express = require("express");
const db = require("../db");
const { requireAuth, requireOwner } = require("../middleware/auth");

const router = express.Router();

router.get("/stats", requireAuth, requireOwner, (req, res) => {
  const totalDrivers = db
    .prepare("SELECT COUNT(*) as count FROM users WHERE role = 'driver'")
    .get().count;
  const totalOwners = db
    .prepare("SELECT COUNT(*) as count FROM users WHERE role = 'owner'")
    .get().count;
  const totalStations = db
    .prepare("SELECT COUNT(*) as count FROM stations")
    .get().count;
  const totalBookings = db
    .prepare("SELECT COUNT(*) as count FROM bookings")
    .get().count;
  const activeBookings = db
    .prepare("SELECT COUNT(*) as count FROM bookings WHERE status IN ('confirmed')")
    .get().count;
  const completedBookings = db
    .prepare("SELECT COUNT(*) as count FROM bookings WHERE status = 'completed'")
    .get().count;
  const cancelledBookings = db
    .prepare("SELECT COUNT(*) as count FROM bookings WHERE status = 'cancelled'")
    .get().count;
  const totalQueue = db
    .prepare("SELECT SUM(queue_count) as count FROM stations")
    .get().count;

  res.json({
    stats: {
      totalDrivers,
      totalOwners,
      totalStations,
      totalBookings,
      activeBookings,
      completedBookings,
      cancelledBookings,
      totalQueue,
    },
  });
});

module.exports = router;
