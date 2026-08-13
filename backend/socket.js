// socket.js — Socket.io room-based real-time layer
// Rooms are named `station:{id}`. Clients join a station's room to receive
// live updates whenever that station's availability or queue changes.

let ioInstance = null;

function initSocket(io) {
  ioInstance = io;

  io.on("connection", (socket) => {
    socket.on("join_station", (stationId) => {
      if (!stationId) return;
      socket.join(`station:${stationId}`);
    });

    socket.on("leave_station", (stationId) => {
      if (!stationId) return;
      socket.leave(`station:${stationId}`);
    });

    socket.on("disconnect", () => {
      // no-op, socket.io cleans up room membership automatically
    });
  });
}

// Broadcast a station's current state to everyone in its room.
function emitStationUpdate(station) {
  if (!ioInstance) return;
  ioInstance.to(`station:${station.id}`).emit("station_update", station);
  // also emit on a global channel so list screens can update badges live
  ioInstance.emit("station_update_global", station);
}

// Broadcast when a new booking is created/updated for a station's queue.
function emitQueueUpdate(stationId, payload) {
  if (!ioInstance) return;
  ioInstance.to(`station:${stationId}`).emit("queue_update", payload);
}

module.exports = { initSocket, emitStationUpdate, emitQueueUpdate };
