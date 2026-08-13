// seed.js — populate ghazi.db with Mukalla, Yemen gas stations + a demo owner/driver
const { v4: uuid } = require("uuid");
const bcrypt = require("bcryptjs");
const db = require("./db");

const stations = [
  {
    name: "Al-Sitteen Station",
    name_ar: "محطة الستين",
    address: "شارع الستين، المكلا",
    neighborhood: "الستين",
    lat: 14.5289,
    lng: 49.1325,
    fuel_types: "petrol91,petrol95,diesel",
    is_available: 1,
  },
  {
    name: "Mweibakha Station",
    name_ar: "محطة وجه الدور - مويبخة",
    address: "منطقة مويبخة، المكلا",
    neighborhood: "مويبخة",
    lat: 14.5401,
    lng: 49.1211,
    fuel_types: "petrol91,diesel",
    is_available: 1,
  },
  {
    name: "Fuwa Station",
    name_ar: "محطة فوة",
    address: "حي فوة، المكلا",
    neighborhood: "فوة",
    lat: 14.5223,
    lng: 49.1489,
    fuel_types: "petrol91,petrol95,diesel",
    is_available: 0,
  },
  {
    name: "Al-Mukalla Central Station",
    name_ar: "محطة المكلا المركزية",
    address: "وسط المدينة، المكلا",
    neighborhood: "وسط المدينة",
    lat: 14.5346,
    lng: 49.1279,
    fuel_types: "petrol91,petrol95,diesel",
    is_available: 1,
  },
  {
    name: "Al-Deis Road Station",
    name_ar: "محطة طريق الديس",
    address: "طريق الديس، المكلا",
    neighborhood: "الديس",
    lat: 14.5502,
    lng: 49.1602,
    fuel_types: "diesel",
    is_available: 1,
  },
];

const insertStation = db.prepare(`
  INSERT INTO stations (id, name, name_ar, address, neighborhood, lat, lng, fuel_types, is_available, queue_count, next_queue_number, image_url)
  VALUES (@id, @name, @name_ar, @address, @neighborhood, @lat, @lng, @fuel_types, @is_available, 0, 1, @image_url)
`);

const insertUser = db.prepare(`
  INSERT INTO users (id, name, email, phone, password_hash, role, station_id)
  VALUES (@id, @name, @email, @phone, @password_hash, @role, @station_id)
`);

const wipe = db.transaction(() => {
  db.exec("DELETE FROM bookings; DELETE FROM stations; DELETE FROM users;");
});

const seed = db.transaction(() => {
  wipe();

  const stationIds = [];
  for (const s of stations) {
    const id = uuid();
    stationIds.push(id);
    insertStation.run({
      id,
      name: s.name,
      name_ar: s.name_ar,
      address: s.address,
      neighborhood: s.neighborhood,
      lat: s.lat,
      lng: s.lng,
      fuel_types: s.fuel_types,
      is_available: s.is_available,
      image_url: null,
    });
  }

  // Demo owner account -> owns the first station (Al-Sitteen)
  insertUser.run({
    id: uuid(),
    name: "مالك محطة الستين",
    email: "owner@ghazi.ye",
    phone: "777000001",
    password_hash: bcrypt.hashSync("owner123", 10),
    role: "owner",
    station_id: stationIds[0],
  });

  // Demo driver account
  insertUser.run({
    id: uuid(),
    name: "سائق تجريبي",
    email: "driver@ghazi.ye",
    phone: "777000002",
    password_hash: bcrypt.hashSync("driver123", 10),
    role: "driver",
    station_id: null,
  });

  return stationIds;
});

const ids = seed();

console.log("✅ Seed complete.");
console.log(`   Stations inserted: ${stations.length}`);
console.log("   Demo owner login  -> email: owner@ghazi.ye  password: owner123");
console.log("   Demo driver login -> email: driver@ghazi.ye password: driver123");
console.log(`   Owner's station id: ${ids[0]}`);
