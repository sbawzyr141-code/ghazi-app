const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

const { initSocket } = require("./socket");
const authRoutes = require("./routes/auth");
const stationRoutes = require("./routes/stations");
const bookingRoutes = require("./routes/bookings");
const adminRoutes = require("./routes/admin");

const app = express();
app.use(cors());
app.use(express.json());

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", service: "ghazi-backend", time: new Date().toISOString() });
});

app.use("/api/auth", authRoutes);
app.use("/api/stations", stationRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/admin", adminRoutes);

app.use((req, res) => res.status(404).json({ error: "Not found" }));
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "Internal server error" });
});

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*", methods: ["GET", "POST", "PATCH"] },
});
initSocket(io);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚗⛽  Ghazi backend running on http://localhost:${PORT}`);
  console.log(`     Socket.io ready for room-based station updates`);
});
