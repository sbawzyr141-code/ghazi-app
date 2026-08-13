const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET || "ghazi-dev-secret-change-in-production";

function requireAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "Missing auth token" });

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload; // { id, email, role, station_id }
    next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}

function requireOwner(req, res, next) {
  if (!req.user || req.user.role !== "owner") {
    return res.status(403).json({ error: "Owner access required" });
  }
  next();
}

module.exports = { requireAuth, requireOwner, JWT_SECRET };
