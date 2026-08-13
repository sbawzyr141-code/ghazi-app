# غازي (Ghazi) — Gas Station Queue & Booking Platform (Mukalla)

Full-stack implementation:

- **`backend/`** — Node.js + Express + SQLite (`better-sqlite3`) + Socket.io real-time API
- **`mobile/`** — Flutter driver app (Arabic RTL): station list, live availability, booking, digital QR pass
- **`dashboard/`** — Flutter Web owner dashboard: availability toggle, live queue, QR verification simulator

---

## 1. Backend setup

```bash
cd backend
npm install
npm run seed      # creates backend/ghazi.db and loads Mukalla stations + demo accounts
npm start          # runs on http://localhost:3000
```

Demo accounts created by the seed script:

| Role   | Email             | Password   |
|--------|-------------------|------------|
| Owner  | owner@ghazi.ye    | owner123   |
| Driver | driver@ghazi.ye   | driver123  |

Seeded stations: Al-Sitteen (الستين), Mweibakha (وجه الدور/مويبخة), Fuwa (فوة), Al-Mukalla Central (المكلا المركزية), Al-Deis Road (طريق الديس).

Health check: `GET http://localhost:3000/api/health`

### Key REST endpoints
- `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me`
- `GET /api/stations`, `GET /api/stations/:id`, `PATCH /api/stations/:id/toggle` (owner)
- `POST /api/bookings`, `GET /api/bookings/user/:userId`, `GET /api/bookings/station/:stationId` (owner), `PATCH /api/bookings/:id/complete` (owner), `PATCH /api/bookings/:id/cancel`

### Socket.io events
- Client emits `join_station` / `leave_station` with a station id to join room `station:{id}`
- Server emits `station_update` (room-scoped), `station_update_global` (all clients, for list badges), `queue_update` (room-scoped)

---

## 2. Mobile app (driver) setup

```bash
cd mobile
flutter pub get
flutter run -d chrome --dart-define=GHAZI_API_BASE_URL=http://localhost:3000
# or for a real/emulated device:
flutter run --dart-define=GHAZI_API_BASE_URL=http://10.0.2.2:3000   # Android emulator
flutter run --dart-define=GHAZI_API_BASE_URL=http://localhost:3000  # iOS simulator
```

Log in with the demo driver account, browse stations, tap an available station to book a queue slot, and view the generated QR pass + queue number under "حجوزاتي".

---

## 3. Owner dashboard (Flutter Web) setup

```bash
cd dashboard
flutter pub get
flutter run -d chrome --dart-define=GHAZI_API_BASE_URL=http://localhost:3000
```

Log in with the demo owner account to:
- Toggle live fuel availability
- See the real-time queue counter and active bookings list
- Open "محاكي فحص QR" (QR simulator) to sweep-scan and complete a booking by pasting its booking ID

---

## 4. One-shot run order

```bash
# Terminal 1
cd backend && npm install && npm run seed && npm start

# Terminal 2
cd mobile && flutter pub get && flutter run -d chrome --dart-define=GHAZI_API_BASE_URL=http://localhost:3000

# Terminal 3
cd dashboard && flutter pub get && flutter run -d chrome --dart-define=GHAZI_API_BASE_URL=http://localhost:3000
```

---

## Brand

- Primary Deep Navy `#1A365D`
- Accent Orange `#FF6B00`
- Background `#F8FAFC`
- Logo: `mobile/assets/images/logo.png`, `dashboard/assets/images/logo.png`
