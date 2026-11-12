require('dotenv').config();
const dns = require('dns');
try { dns.setServers(['8.8.8.8', '1.1.1.1']); } catch (e) {}

const express = require('express');
const http = require('http');
const cors = require('cors');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');

// Disable buffering so failed DB queries fail-fast instead of hanging requests
mongoose.set('bufferCommands', false);

const User = require('./models/User');
const Bus = require('./models/Bus');
const SosAlert = require('./models/SosAlert');
const Route = require('./models/Route');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

const JWT_SECRET = process.env.JWT_SECRET || 'smartbus_secret_key_2026';

// ─── Initial Seed Data ───────────────────────────────────────────────────────
const initialBuses = [
  {
    busId: '101',
    busCode: 'GUL-101',
    routeName: '1-avtobus',
    driverName: 'Sardor Rahimov',
    speed: 11,
    occupancyPercent: 42,
    latitude: 40.475401,
    longitude: 68.780794,
    dLat: 0.00015,
    dLng: 0.00025,
    status: 'ok',
    eta: 2
  },
  {
    busId: '102',
    busCode: 'GUL-102',
    routeName: '2-avtobus',
    driverName: 'Jasur Karimov',
    speed: 11,
    occupancyPercent: 35,
    latitude: 40.495556,
    longitude: 68.765923,
    dLat: 0.00012,
    dLng: 0.00022,
    status: 'ok',
    eta: 2
  },
  {
    busId: '1',
    busCode: 'GUL-001',
    routeName: '17-avtobus',
    driverName: 'Aliyev Vali',
    speed: 34,
    occupancyPercent: 42,
    latitude: 40.4910,
    longitude: 68.7780,
    dLat: 0.00025,
    dLng: 0.00035,
    status: 'ok',
    eta: 3
  },
  {
    busId: '2',
    busCode: 'GUL-002',
    routeName: '5-avtobus',
    driverName: 'Karimov Jasur',
    speed: 28,
    occupancyPercent: 65,
    latitude: 40.4950,
    longitude: 68.7830,
    dLat: -0.0002,
    dLng: 0.0003,
    status: 'ok',
    eta: 5
  },
  {
    busId: '3',
    busCode: 'GUL-003',
    routeName: '8-avtobus',
    driverName: 'Nazarov Olim',
    speed: 38,
    occupancyPercent: 80,
    latitude: 40.4870,
    longitude: 68.7710,
    dLat: 0.00035,
    dLng: -0.00025,
    status: 'late',
    eta: 8
  },
  {
    busId: '4',
    busCode: 'GUL-004',
    routeName: '22-avtobus',
    driverName: 'Yusupov Said',
    speed: 25,
    occupancyPercent: 55,
    latitude: 40.4990,
    longitude: 68.7900,
    dLat: -0.0003,
    dLng: -0.0003,
    status: 'ok',
    eta: 4
  },
  {
    busId: '5',
    busCode: 'GUL-005',
    routeName: '3-avtobus',
    driverName: 'Toshmatov Anvar',
    speed: 18,
    occupancyPercent: 90,
    latitude: 40.4830,
    longitude: 68.7640,
    dLat: 0.0002,
    dLng: 0.00045,
    status: 'ok',
    eta: 12
  }
];

const initialRoutes = [
  { id: '1', routeNumber: '1', name: 'Yangi Bozor — Ko\'rkam Diyor — GulDU', startStopName: 'Yangi bozor1', endStopName: 'GulDU', distanceKm: 8.9, estimatedDurationMin: 24, activeBuses: 1 },
  { id: '2', routeNumber: '2', name: 'TYB — 2-Mavze — Nurafshon bekati', startStopName: 'TYB', endStopName: 'Nurafshon bekati', distanceKm: 7.7, estimatedDurationMin: 22, activeBuses: 1 },
  { id: '3', routeNumber: '17', name: 'Vokzal — Yangi Bozor — GulDU', startStopName: 'Vokzal', endStopName: 'GulDU', distanceKm: 8.2, estimatedDurationMin: 22, activeBuses: 4 },
  { id: '4', routeNumber: '5', name: 'Markaz — Shifoxona — Mikrorayon', startStopName: 'Markaz', endStopName: '3-Mikrorayon', distanceKm: 6.8, estimatedDurationMin: 18, activeBuses: 2 },
  { id: '5', routeNumber: '8', name: 'Aeroport — Markaz — Vokzal', startStopName: 'Aeroport', endStopName: 'Vokzal', distanceKm: 12.5, estimatedDurationMin: 35, activeBuses: 3 },
  { id: '6', routeNumber: '22', name: 'Dehqon Bozori — TTZ — Universitet', startStopName: 'Dehqon Bozori', endStopName: 'Universitet', distanceKm: 9.1, estimatedDurationMin: 25, activeBuses: 2 }
];

// ─── In-Memory Fallback State (MongoDB ulanmasa ham server to'liq ishlaydi) ──
let memBuses = JSON.parse(JSON.stringify(initialBuses));
let memRoutes = [
  { id: '1', number: '17', title: 'Chilonzor → Chorsu', services: '12 ta', interval: '8–10 daq', stops: '5 ta · sxema', status: 'faol', statusText: 'Faol', rating: '4.6', demand: '63 kishi' },
  { id: '2', number: '23', title: 'Chilonzor → Buyuk Ipak yo\'li', services: '10 ta', interval: '6–8 daq', stops: '14 ta', status: 'faol', statusText: 'Faol', rating: '4.8', demand: '45 kishi' },
  { id: '3', number: '80', title: 'Chilonzor → Toshkent vokzali', services: '9 ta', interval: '10–12 daq', stops: '18 ta', status: 'faol', statusText: 'Faol', rating: '4.4', demand: '52 kishi' },
  { id: '4', number: '51', title: 'Yunusobod → Chorsu', services: '8 ta', interval: '8–10 daq', stops: '16 ta', status: 'faol', statusText: 'Faol', rating: '4.7', demand: '38 kishi' },
  { id: '5', number: '67', title: 'Sergeli → Novza', services: '9 ta', interval: '10–15 daq', stops: '20 ta', status: 'faol', statusText: 'Faol', rating: '4.5', demand: '41 kishi' },
  { id: '6', number: '104', title: 'Yangi Toshkent → Markaz', services: '0 ta', interval: '15 daq · reja', stops: '12 ta · reja', status: 'rejalashtirilgan', statusText: 'Rejalashtirilgan', rating: '--', demand: '20 kishi' }
];
let memStops = [
  { id: '1', name: 'Bunyodkor', district: 'Chilonzor tumani', routes: '17, 23, 80', waitTime: '6.5 daq', status: 'Yuqori talab', count: 68, lat: 41.2842, lng: 69.2134 },
  { id: '2', name: 'Chilonzor metro', district: 'Chilonzor tumani', routes: '17, 23, 51, 80', waitTime: '5.2 daq', status: 'Gavjum', count: 94, lat: 41.2783, lng: 69.2058 },
  { id: '3', name: 'Muqimiy', district: 'Chilonzor tumani', routes: '17, 80', waitTime: '7.8 daq', status: 'O\'rtacha', count: 42, lat: 41.2975, lng: 69.2312 },
  { id: '4', name: 'Novza', district: 'Chilonzor tumani', routes: '23, 80, 67', waitTime: '8.1 daq', status: 'O\'rtacha', count: 37, lat: 41.2917, lng: 69.2241 },
  { id: '5', name: 'Chorsu bozori', district: 'Shayxontohur tumani', routes: '17, 51', waitTime: '4.9 daq', status: 'Yuqori talab', count: 85, lat: 41.3268, lng: 69.2355 }
];
let memShifts = [
  { id: 'SM-104', driver: 'Akmal Karimov', route: '17 · Chilonzor → Chorsu', busCode: 'SB-017', time: '15:00–19:30', status: 'Jarayonda', statusClass: 'badge-green-clean' },
  { id: 'SM-105', driver: 'Javlon Sobirov', route: '17 · Chilonzor → Chorsu', busCode: 'SB-021', time: '18:10–22:20', status: 'Jarayonda', statusClass: 'badge-green-clean' },
  { id: 'SM-106', driver: 'Botir Yusupov', route: '23 · Buyuk Ipak yo\'li', busCode: 'SB-023', time: '14:00–21:30', status: 'Jarayonda', statusClass: 'badge-green-clean' },
  { id: 'SM-107', driver: 'Sarvar Olimov', route: '80 · Toshkent vokzali', busCode: 'SB-080', time: '06:30–14:30', status: 'Tugallangan', statusClass: 'badge-blue-soft' }
];
let memInquiries = [
  { id: '1', type: 'Topilma', typeClass: 'badge-route-blue', passenger: 'Dilshod Aliyev', busRoute: 'SB-017 (17-yo\'nalish)', desc: 'Hamyon va talabalik guvohnomasi salonda unutilgan', time: '17:40', status: 'Topildi · Xonada', statusClass: 'badge-green-clean' },
  { id: '2', type: 'Taklif', typeClass: 'badge-soft-yellow', passenger: 'Madina Rahimova', busRoute: '23-yo\'nalish', desc: 'Kechki oraliqni 8 daqiqaga qisqartirish so\'ralgan', time: '16:15', status: 'Ko\'rib chiqilmoqda', statusClass: 'badge-amber-soft' },
  { id: '3', type: 'Shikoyat', typeClass: 'badge-red-soft', passenger: 'Otabek Jo\'rayev', busRoute: '80-yo\'nalish', desc: 'Konditsioner past darajada ishlagan', time: '14:20', status: 'Hal qilindi', statusClass: 'badge-green-clean' }
];
let memSettings = {
  orgName: "Toshkent shahar jamoat transporti boshqarmasi",
  stationName: "Markaziy Avtobus Dispetcherlik Nazorati #1",
  refreshInterval: 3,
  soundAlerts: true,
  theme: "light",
  autoDispatch: false
};
let memUsers = [];
let memAlerts = [];
let currentDelayAlert = null;
let memLostItems = [
  {
    id: 'lost_1',
    title: 'Qora charm hamyon',
    description: 'Ichida talabalik guvohnomasi va Humo transport kartasi bor',
    busRoute: '17-avtobus',
    passengerName: 'Dilshod Raximov',
    passengerPhone: '+998 90 123 45 67',
    status: 'yoqolgan',
    createdAt: new Date(Date.now() - 3600000 * 2).toISOString(),
    foundAt: null
  },
  {
    id: 'lost_2',
    title: "Ko'k soyabon",
    description: "Orqa o'rindiqda qolib ketgan, yog'och sopli",
    busRoute: '8-avtobus',
    passengerName: 'Nodira Salimova',
    passengerPhone: '+998 91 987 65 43',
    status: 'topildi',
    createdAt: new Date(Date.now() - 3600000 * 5).toISOString(),
    foundAt: new Date(Date.now() - 3600000).toISOString()
  }
];

(async () => {
  const adminHash = await bcrypt.hash('admin123', 10);
  const driverHash = await bcrypt.hash('pass1', 10);
  memUsers.push(
    {
      _id: 'admin_root',
      fullName: 'Dispetcher Admin',
      username: 'admin',
      phoneNumber: 'admin',
      password: adminHash,
      role: 'admin',
      isOnline: true,
      lastLogin: new Date()
    },
    {
      _id: 'driver_root',
      fullName: 'Aliyev Vali (Haydovchi)',
      username: 'haydovchi1',
      phoneNumber: '+998901112233',
      password: driverHash,
      busCode: 'GUL-001',
      routeName: '17-avtobus',
      role: 'driver',
      isOnline: true,
      lastLogin: new Date()
    }
  );
})();

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function sanitizeUser(u) {
  if (!u) return null;
  return {
    id: (u._id || u.id || '').toString(),
    _id: (u._id || u.id || '').toString(),
    fullName: u.fullName || '',
    phoneNumber: u.phoneNumber || '',
    username: u.username || '',
    busCode: u.busCode || '',
    routeName: u.routeName || '',
    role: u.role || 'passenger',
    isOnline: !!u.isOnline,
    lastLogin: u.lastLogin || null,
    createdAt: u.createdAt || null
  };
}

// ─── Auth Middleware ──────────────────────────────────────────────────────────
function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'Autentifikatsiya talab qilinadi' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ success: false, message: 'Yaroqsiz yoki eskirgan token' });
  }
}

async function seedDatabase() {
  try {
    const busCount = await Bus.countDocuments();
    if (busCount === 0) {
      console.log('🌱 Guliston avtobuslari MongoDB-ga saqlanmoqda...');
      await Bus.insertMany(initialBuses);
      console.log('✅ Avtobuslar muvaffaqiyatli yuklandi!');
    }

    const adminUser = await User.findOne({ username: 'admin' });
    if (!adminUser) {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      await User.create({
        fullName: 'Dispetcher Admin',
        phoneNumber: 'admin',
        username: 'admin',
        password: hashedPassword,
        role: 'admin'
      });
      console.log('👤 Boshlang\'ich Admin yaratildi! Login: admin');
    }
  } catch (err) {
    console.error('⚠️ Seed xatosi:', err.message);
  }
}

// ─── MongoDB Ulanishi ────────────────────────────────────────────────────────
const mongoUri = process.env.MONGO_URI;

const connectDB = async () => {
  if (!mongoUri) {
    console.log('ℹ️ MONGO_URI aniqlanmadi. Server In-Memory rejimida xavfsiz ishlamoqda.');
    return;
  }
  try {
    await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 4000 });
    console.log('✅ MongoDB-ga muvaffaqiyatli ulandi!');
    await seedDatabase();
    setupChangeStreams();
  } catch (err) {
    console.log('ℹ️ MongoDB ulanmadi (' + err.message + '). Server In-Memory rejimida to\'liq ishlamoqda.');
    setTimeout(connectDB, 30000);
  }
};
connectDB();

function setupChangeStreams() {
  try {
    const busStream = Bus.watch([], { fullDocument: 'updateLookup' });
    busStream.on('change', async () => {
      try {
        const allBuses = await Bus.find();
        const formatted = formatBuses(allBuses);
        io.emit('bus_location_updated', formatted);
        io.emit('all_buses_update', formatted);
      } catch (e) {}
    });
  } catch (e) {
    console.log('⚠️ Change stream faollashtirilmadi, interval rejim ishlamoqda');
  }
}

function formatBuses(buses) {
  return buses.map((b) => ({
    id: b.busId || b.id || b._id,
    busCode: b.busCode,
    routeName: b.routeName,
    driverName: b.driverName,
    speed: b.speed,
    occupancyPercent: b.occupancyPercent,
    latitude: b.latitude,
    longitude: b.longitude,
    dLat: b.dLat,
    dLng: b.dLng,
    status: b.status,
    eta: b.eta
  }));
}

// ─── REST API Endpoints ──────────────────────────────────────────────────────

// Root endpoint (Browser status check)
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="uz">
    <head>
      <meta charset="UTF-8">
      <title>SmartBus Backend Server</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; padding: 40px 20px; text-align: center; }
        .card { max-width: 600px; margin: 0 auto; background: #1e293b; border-radius: 16px; padding: 32px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }
        .badge { display: inline-block; background: #10b981; color: white; padding: 6px 14px; border-radius: 20px; font-size: 14px; font-weight: 600; margin-bottom: 16px; }
        h1 { margin: 0 0 10px; font-size: 26px; }
        p { color: #94a3b8; font-size: 15px; line-height: 1.6; }
        .links { margin-top: 24px; display: flex; flex-direction: column; gap: 10px; }
        .btn { display: block; padding: 12px 18px; background: #3b82f6; color: white; text-decoration: none; border-radius: 8px; font-weight: 600; transition: 0.2s; }
        .btn:hover { background: #2563eb; }
        .btn-sub { background: #334155; }
        .btn-sub:hover { background: #475569; }
      </style>
    </head>
    <body>
      <div class="card">
        <span class="badge">● Server Faol (Online)</span>
        <h1>SmartBus Real-Time API Server</h1>
        <p>Backend va Socket.IO serveri 3000-portda muvaffaqiyatli ishlamoqda. Guliston avtobuslari GPS signallari tarqatilmoqda.</p>
        <div class="links">
          <a class="btn" href="http://localhost:3001" target="_blank">🎛️ Dispetcher Web Paneliga o'tish (3001)</a>
          <a class="btn btn-sub" href="/api/health" target="_blank">🩺 Server Salomatligi (/api/health)</a>
          <a class="btn btn-sub" href="/api/buses" target="_blank">🚌 Jonli Avtobuslar Ro'yxati (/api/buses)</a>
          <a class="btn btn-sub" href="/api/routes" target="_blank">🗺️ Marshrutlar (/api/routes)</a>
        </div>
      </div>
    </body>
    </html>
  `);
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    mode: isDbConnected() ? 'MongoDB Atlas' : 'In-Memory (Local Active)',
    message: 'SmartBus Real-Time Server active'
  });
});

// 1. Register API
app.post('/api/auth/register', async (req, res) => {
  try {
    const { fullName, phoneNumber, password, role } = req.body;

    if (!phoneNumber || !password || !fullName) {
      return res.status(400).json({ success: false, message: 'Barcha maydonlarni to\'ldiring' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const assignedRole = role || 'passenger';

    let user;
    if (isDbConnected()) {
      try {
        const existingUser = await User.findOne({ phoneNumber });
        if (existingUser) {
          return res.status(400).json({ success: false, message: 'Ushbu telefon raqam allaqachon ro\'yxatdan o\'tgan' });
        }
        user = await User.create({
          fullName,
          phoneNumber,
          password: hashedPassword,
          role: assignedRole,
          isOnline: true,
          lastLogin: new Date()
        });
      } catch (e) {
        // Fallback to in-memory
      }
    }

    if (!user) {
      const existingMem = memUsers.find(u => u.phoneNumber === phoneNumber);
      if (existingMem) {
        return res.status(400).json({ success: false, message: 'Ushbu telefon raqam allaqachon ro\'yxatdan o\'tgan' });
      }
      user = {
        _id: 'user_' + Date.now(),
        fullName,
        phoneNumber,
        password: hashedPassword,
        role: assignedRole,
        isOnline: true,
        lastLogin: new Date()
      };
      memUsers.push(user);
    }

    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '30d' });

    io.emit('user_registered', {
      id: user._id,
      fullName: user.fullName,
      phoneNumber: user.phoneNumber,
      role: user.role,
      timestamp: new Date()
    });

    res.status(201).json({
      success: true,
      message: 'Muvaffaqiyatli ro\'yxatdan o\'tdingiz',
      token,
      data: {
        id: user._id,
        fullName: user.fullName,
        phoneNumber: user.phoneNumber,
        role: user.role
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// 2. Login API
app.post('/api/auth/login', async (req, res) => {
  try {
    const { phoneNumber, username, password } = req.body;
    const loginKey = (username || phoneNumber || '').trim();

    if (!loginKey || !password) {
      return res.status(400).json({ success: false, message: 'Login va parolni kiriting' });
    }

    // Direct check for admin: login: admin, password: admin123
    if ((loginKey.toLowerCase() === 'admin' || loginKey === '+998901234567') && password === 'admin123') {
      const token = jwt.sign({ id: 'admin_root', role: 'admin' }, JWT_SECRET, { expiresIn: '30d' });
      io.emit('user_logged_in', {
        id: 'admin_root',
        fullName: 'Dispetcher Admin',
        username: 'admin',
        phoneNumber: 'admin',
        role: 'admin',
        lastLogin: new Date()
      });
      return res.json({
        success: true,
        token,
        data: {
          id: 'admin_root',
          fullName: 'Dispetcher Admin',
          username: 'admin',
          phoneNumber: 'admin',
          role: 'admin'
        }
      });
    }

    let user = null;
    if (isDbConnected()) {
      try {
        user = await User.findOne({
          $or: [
            { username: loginKey },
            { phoneNumber: loginKey }
          ]
        });
      } catch (e) {}
    }

    if (!user) {
      user = memUsers.find(u => (u.username && u.username.toLowerCase() === loginKey.toLowerCase()) || u.phoneNumber === loginKey);
    }

    if (!user) {
      return res.status(404).json({ success: false, message: 'Foydalanuvchi topilmadi' });
    }

    let isMatch = false;
    if (user.password) {
      try {
        isMatch = await bcrypt.compare(password, user.password);
      } catch (_) {}
    }

    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Parol noto\'g\'ri' });
    }

    user.isOnline = true;
    user.lastLogin = new Date();
    if (user.save) {
      try { await user.save(); } catch (e) {}
    }

    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '30d' });

    const safeUser = sanitizeUser(user);

    io.emit('user_logged_in', safeUser);

    res.json({
      success: true,
      token,
      data: safeUser
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// 2.1 Drivers Management APIs
app.get('/api/drivers', async (req, res) => {
  try {
    let drivers = [];
    if (isDbConnected()) {
      try {
        drivers = await User.find({ role: 'driver' }).select('-password -__v');
      } catch (e) {}
    }
    if (!drivers || drivers.length === 0) {
      drivers = memUsers.filter(u => u.role === 'driver');
    }
    const safeDrivers = drivers.map(sanitizeUser);
    res.json({ success: true, data: safeDrivers });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/drivers', async (req, res) => {
  try {
    const { fullName, phoneNumber, username, password, busCode, routeName } = req.body;
    if (!fullName || !username || !password) {
      return res.status(400).json({ success: false, message: "Ism, login va parol talab qilinadi" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const driverObj = {
      _id: 'driver_' + Date.now(),
      fullName,
      phoneNumber: phoneNumber || '',
      username,
      password: hashedPassword,
      busCode: busCode || 'GUL-001',
      routeName: routeName || "17-avtobus",
      role: 'driver',
      isOnline: true,
      createdAt: new Date()
    };

    if (isDbConnected()) {
      try {
        const created = await User.create({
          fullName,
          phoneNumber: phoneNumber || username,
          username,
          password: hashedPassword,
          busCode: driverObj.busCode,
          routeName: driverObj.routeName,
          role: 'driver',
          isOnline: true
        });
        driverObj._id = created._id.toString();
      } catch (e) {}
    }

    // Save in memUsers as well
    const existingIdx = memUsers.findIndex(u => u.username === username);
    if (existingIdx >= 0) {
      memUsers[existingIdx] = driverObj;
    } else {
      memUsers.push(driverObj);
    }

    const safeDriver = sanitizeUser(driverObj);
    io.emit('driver_added', safeDriver);
    res.status(201).json({ success: true, message: "Haydovchi muvaffaqiyatli qo'shildi", data: safeDriver });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.delete('/api/drivers/:id', async (req, res) => {
  try {
    const id = req.params.id;
    if (isDbConnected()) {
      try { await User.findByIdAndDelete(id); } catch (e) {}
    }
    memUsers = memUsers.filter(u => u._id !== id && u.username !== id);
    io.emit('driver_deleted', { id });
    res.json({ success: true, message: "Haydovchi o'chirildi" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2.2 Delay Alerts APIs
app.get('/api/delay-alert', (req, res) => {
  res.json({ success: true, alert: currentDelayAlert });
});

app.post('/api/delay-alert', (req, res) => {
  try {
    const { routeName, busCode, message, delayMinutes } = req.body;
    const alert = {
      id: 'delay_' + Date.now(),
      routeName: routeName || '8-avtobus',
      busCode: busCode || 'GUL-003',
      delayMinutes: delayMinutes || '5-10',
      message: message || "Mustaqillik ko'chasidagi ta'mirlash tufayli 8-avtobus 5-10 minutga kechikishi mumkin.",
      timestamp: new Date().toISOString()
    };
    currentDelayAlert = alert;
    io.emit('delay_alert_triggered', alert);
    res.json({ success: true, alert });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.post('/api/delay-alert/resolve', (req, res) => {
  currentDelayAlert = null;
  io.emit('delay_alert_resolved', {});
  res.json({ success: true, message: 'Kechikish ogohlantirishi olib tashlandi' });
});

// 2.3 Lost & Found Items APIs
app.get('/api/lost-items', (req, res) => {
  res.json({ success: true, items: memLostItems });
});

app.post('/api/lost-items', (req, res) => {
  try {
    const { title, description, busRoute, passengerName, passengerPhone } = req.body;
    if (!title) {
      return res.status(400).json({ success: false, message: 'Buyum nomini kiriting' });
    }
    const item = {
      id: 'lost_' + Date.now(),
      title,
      description: description || '',
      busRoute: busRoute || '17-avtobus',
      passengerName: passengerName || 'Yo\'lovchi',
      passengerPhone: passengerPhone || '+998 90 000 00 00',
      status: 'yoqolgan',
      createdAt: new Date().toISOString(),
      foundAt: null
    };
    memLostItems.unshift(item);
    io.emit('lost_item_reported', item);
    io.emit('all_lost_items_update', memLostItems);
    res.json({ success: true, item });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.post('/api/lost-items/:id/found', (req, res) => {
  try {
    const { id } = req.params;
    const item = memLostItems.find(i => i.id === id);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Buyum topilmadi' });
    }
    item.status = 'topildi';
    item.foundAt = new Date().toISOString();

    const smsData = {
      id: item.id,
      title: item.title,
      busRoute: item.busRoute,
      passengerName: item.passengerName,
      passengerPhone: item.passengerPhone,
      message: `Hurmatli yo'lovchi, siz qidirgan "${item.title}" (${item.busRoute}) topildi! Guliston Markaziy Dispetcherlik xizmatidan (+998 67 225-01-23) olib ketishingiz mumkin.`,
      timestamp: item.foundAt
    };

    io.emit('lost_item_found', smsData);
    io.emit('all_lost_items_update', memLostItems);
    res.json({ success: true, item, smsData });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.delete('/api/lost-items/:id', (req, res) => {
  try {
    const { id } = req.params;
    memLostItems = memLostItems.filter(i => i.id !== id);
    io.emit('all_lost_items_update', memLostItems);
    res.json({ success: true, message: 'Buyum o\'chirildi' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// 3. Buses Endpoints (CRUD)
app.get('/api/buses', async (req, res) => {
  try {
    if (isDbConnected()) {
      try {
        const buses = await Bus.find();
        return res.json({ success: true, data: formatBuses(buses) });
      } catch (e) {}
    }
    res.json({ success: true, data: formatBuses(memBuses) });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/buses', (req, res) => {
  try {
    const { busCode, routeNumber, routeName, driver, plateNumber, busModel } = req.body;
    const code = busCode || 'SB-' + Math.floor(100 + Math.random() * 900);
    const newBus = {
      busId: 'bus_' + Date.now(),
      busCode: code,
      routeCode: (routeNumber || '17') + '-001',
      routeNumber: routeNumber || '17',
      routeName: routeName || `${routeNumber || '17'} · Chilonzor → Chorsu`,
      direction: routeName || "Chilonzor → Chorsu",
      currentStop: 'Chilonzor metro',
      nextStop: 'Bunyodkor',
      occupancyPercent: Math.floor(20 + Math.random() * 40),
      etaMin: 5,
      speed: 34,
      driverName: driver || 'Navbatchi haydovchi',
      driver: driver || 'Navbatchi haydovchi',
      plateNumber: plateNumber || '01 999 ZAA',
      busModel: busModel || 'Isuzu CityBus LE-60',
      latitude: 41.2800 + (Math.random() * 0.03),
      longitude: 69.2100 + (Math.random() * 0.03),
      dLat: 0.0002,
      dLng: 0.0002,
      status: 'reysda',
      statusLabel: 'Reysda',
      inspection: 'Ko\'rik: yangi',
      eta: 4
    };
    memBuses.unshift(newBus);
    const formatted = formatBuses(memBuses);
    io.emit('bus_location_updated', formatted);
    io.emit('all_buses_update', formatted);
    io.emit('bus_added', newBus);
    res.status(201).json({ success: true, data: newBus });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.put('/api/buses/:busCode', (req, res) => {
  try {
    const { busCode } = req.params;
    const bus = memBuses.find(b => b.busCode === busCode);
    if (!bus) return res.status(404).json({ success: false, message: 'Avtobus topilmadi' });
    Object.assign(bus, req.body);
    const formatted = formatBuses(memBuses);
    io.emit('bus_location_updated', formatted);
    io.emit('all_buses_update', formatted);
    res.json({ success: true, data: bus });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete('/api/buses/:busCode', (req, res) => {
  try {
    const { busCode } = req.params;
    memBuses = memBuses.filter(b => b.busCode !== busCode && b.busId !== busCode);
    const formatted = formatBuses(memBuses);
    io.emit('bus_location_updated', formatted);
    io.emit('all_buses_update', formatted);
    io.emit('bus_deleted', { busCode });
    res.json({ success: true, message: "Avtobus o'chirildi" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 4. Routes Endpoints (CRUD)
app.get('/api/routes', (req, res) => {
  res.json({ success: true, data: memRoutes });
});

app.post('/api/routes', (req, res) => {
  try {
    const { number, title, interval, stops, status } = req.body;
    const num = String(number || '99');
    const newRoute = {
      id: 'route_' + Date.now(),
      routeNumber: num,
      number: num,
      name: title || `${num}-yo'nalish`,
      title: title || `${num}-yo'nalish`,
      interval: interval || '8–10 daq',
      stops: stops || '12 ta bekat',
      status: status || 'faol',
      statusText: status === 'faol' ? 'Faol' : 'Rejalashtirilgan',
      rating: '4.8',
      demand: '55 kishi',
      activeBuses: 2,
      services: '2 ta'
    };
    memRoutes.unshift(newRoute);
    io.emit('route_added', newRoute);
    res.status(201).json({ success: true, data: newRoute });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete('/api/routes/:id', (req, res) => {
  try {
    const { id } = req.params;
    memRoutes = memRoutes.filter(r => r.id !== id && r.number !== id && r.routeNumber !== id);
    io.emit('route_deleted', { id });
    res.json({ success: true, message: "Yo'nalish o'chirildi" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 5. Stops Endpoints (CRUD)
app.get('/api/stops', (req, res) => {
  res.json({ success: true, data: memStops });
});

app.post('/api/stops', (req, res) => {
  try {
    const { name, district, routes, lat, lng } = req.body;
    const newStop = {
      id: 'stop_' + Date.now(),
      name: name || 'Yangi bekat',
      district: district || 'Chilonzor tumani',
      routes: routes || '17, 23',
      waitTime: '5.2 daq',
      status: 'O\'rtacha',
      count: Math.floor(25 + Math.random() * 45),
      lat: lat ? parseFloat(lat) : 41.2850,
      lng: lng ? parseFloat(lng) : 69.2150
    };
    memStops.unshift(newStop);
    io.emit('stop_added', newStop);
    res.status(201).json({ success: true, data: newStop });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete('/api/stops/:id', (req, res) => {
  try {
    const { id } = req.params;
    memStops = memStops.filter(s => s.id !== id && s.name !== id);
    io.emit('stop_deleted', { id });
    res.json({ success: true, message: "Bekat o'chirildi" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 5.1 Shifts Endpoints (CRUD)
app.get('/api/shifts', (req, res) => {
  res.json({ success: true, data: memShifts });
});

app.post('/api/shifts', (req, res) => {
  try {
    const { driver, route, busCode, time, status } = req.body;
    const newShift = {
      id: 'SM-' + Math.floor(100 + Math.random() * 900),
      driver: driver || 'Akmal Karimov',
      route: route || '17 · Chilonzor → Chorsu',
      busCode: busCode || 'SB-017',
      time: time || '14:00–21:30',
      status: status || 'Jarayonda',
      statusClass: 'badge-green-clean'
    };
    memShifts.unshift(newShift);
    io.emit('shift_added', newShift);
    res.status(201).json({ success: true, data: newShift });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete('/api/shifts/:id', (req, res) => {
  try {
    const { id } = req.params;
    memShifts = memShifts.filter(s => s.id !== id);
    io.emit('shift_deleted', { id });
    res.json({ success: true, message: "Smena o'chirildi" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 5.2 Inquiries Endpoints (CRUD)
app.get('/api/inquiries', (req, res) => {
  res.json({ success: true, data: memInquiries });
});

app.post('/api/inquiries', (req, res) => {
  try {
    const { type, passenger, busRoute, desc, status } = req.body;
    const inqType = type || 'Topilma';
    const newInq = {
      id: 'inq_' + Date.now(),
      type: inqType,
      typeClass: inqType === 'Topilma' ? 'badge-route-blue' : (inqType === 'Shikoyat' ? 'badge-red-soft' : 'badge-soft-yellow'),
      passenger: passenger || 'Yo\'lovchi',
      busRoute: busRoute || '17-yo\'nalish',
      desc: desc || 'Murojaat tafsilotlari',
      time: new Date().toLocaleTimeString().slice(0, 5),
      status: status || 'Ko\'rib chiqilmoqda',
      statusClass: 'badge-amber-soft'
    };
    memInquiries.unshift(newInq);
    io.emit('inquiry_added', newInq);
    res.status(201).json({ success: true, data: newInq });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.put('/api/inquiries/:id/status', (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const inq = memInquiries.find(i => i.id === id);
    if (!inq) return res.status(404).json({ success: false, message: "Murojaat topilmadi" });
    inq.status = status || 'Hal etildi';
    inq.statusClass = 'badge-green-clean';
    io.emit('inquiry_updated', inq);
    res.json({ success: true, data: inq });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete('/api/inquiries/:id', (req, res) => {
  try {
    const { id } = req.params;
    memInquiries = memInquiries.filter(i => i.id !== id);
    io.emit('inquiry_deleted', { id });
    res.json({ success: true, message: "Murojaat o'chirildi" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 5.3 System Settings Endpoints
app.get('/api/settings', (req, res) => {
  res.json({ success: true, data: memSettings });
});

app.post('/api/settings', (req, res) => {
  try {
    memSettings = { ...memSettings, ...req.body };
    io.emit('settings_updated', memSettings);
    res.json({ success: true, data: memSettings });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 6. SOS Alert Endpoint
app.post('/api/sos', async (req, res) => {
  try {
    const { busId, latitude, longitude, description } = req.body;
    const alert = {
      busCode: busId || 'GUL-SOS',
      latitude: latitude || 40.4910,
      longitude: longitude || 68.7780,
      message: description || 'FAVQULOTDA HOLAT!',
      timestamp: new Date()
    };
    memAlerts.push(alert);
    io.emit('sos_alert_triggered', alert);
    res.json({ success: true, message: 'SOS signali qabul qilindi' });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// 7. Active Users Endpoint
app.get('/api/users', async (req, res) => {
  try {
    if (isDbConnected()) {
      try {
        const users = await User.find().select('-password');
        return res.json({ success: true, data: users });
      } catch (e) {}
    }
    const safeUsers = memUsers.map(u => ({
      _id: u._id,
      fullName: u.fullName,
      phoneNumber: u.phoneNumber,
      role: u.role,
      isOnline: u.isOnline,
      lastLogin: u.lastLogin
    }));
    res.json({ success: true, data: safeUsers });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── Socket.io Real-Time Handler ─────────────────────────────────────────────
io.on('connection', async (socket) => {
  console.log(`📱 Klient ulandi: ${socket.id}`);

  // Send current buses immediately
  let currentBuses = memBuses;
  if (isDbConnected()) {
    try {
      const dbBuses = await Bus.find();
      if (dbBuses.length > 0) currentBuses = dbBuses;
    } catch (e) {}
  }
  socket.emit('bus_location_updated', formatBuses(currentBuses));
  socket.emit('all_buses_update', formatBuses(currentBuses));
  socket.emit('all_lost_items_update', memLostItems);
  if (currentDelayAlert) {
    socket.emit('delay_alert_triggered', currentDelayAlert);
  }

  socket.on('join_role', (role) => {
    console.log(`👤 Role: ${role}`);
  });

  // Driver sends bus location update
  socket.on('update_bus_location', async (data) => {
    try {
      const bus = memBuses.find(b => b.busCode === data.busCode);
      if (bus) {
        bus.latitude = data.latitude;
        bus.longitude = data.longitude;
        bus.speed = data.speed || 30;
        if (data.occupancyPercent !== undefined) bus.occupancyPercent = data.occupancyPercent;
        if (data.status) bus.status = data.status;
      }
      if (isDbConnected()) {
        try {
          await Bus.findOneAndUpdate(
            { busCode: data.busCode },
            {
              latitude: data.latitude,
              longitude: data.longitude,
              speed: data.speed || 30,
              occupancyPercent: data.occupancyPercent || 45,
              status: data.status || 'ok',
              updatedAt: new Date()
            }
          );
        } catch (e) {}
      }
      const formatted = formatBuses(memBuses);
      io.emit('bus_location_updated', formatted);
      io.emit('all_buses_update', formatted);
    } catch (e) {}
  });

  // Chat message between Driver and Dispatcher
  socket.on('chat:message', (data) => {
    const msg = {
      id: 'msg_' + Date.now(),
      from: data.from || 'driver',
      senderName: data.senderName || 'Haydovchi',
      busCode: data.busCode || 'GUL-001',
      text: data.text || '',
      time: data.time || new Date().toLocaleTimeString().slice(0, 5),
      timestamp: new Date().toISOString()
    };
    io.emit('chat:message', msg);
  });

  // Delay Alert Triggered
  socket.on('report_delay', (data) => {
    const alert = {
      id: 'delay_' + Date.now(),
      routeName: data.routeName || '8-avtobus',
      busCode: data.busCode || 'GUL-003',
      delayMinutes: data.delayMinutes || '5-10',
      message: data.message || "Mustaqillik ko'chasidagi ta'mirlash tufayli 8-avtobus 5-10 minutga kechikishi mumkin.",
      timestamp: new Date().toISOString()
    };
    currentDelayAlert = alert;
    io.emit('delay_alert_triggered', alert);
  });

  socket.on('resolve_delay', () => {
    currentDelayAlert = null;
    io.emit('delay_alert_resolved', {});
  });

  // Lost & Found item events
  socket.on('report_lost_item', (data) => {
    const item = {
      id: 'lost_' + Date.now(),
      title: data.title || 'Noma\'lum buyum',
      description: data.description || '',
      busRoute: data.busRoute || '17-avtobus',
      passengerName: data.passengerName || 'Yo\'lovchi',
      passengerPhone: data.passengerPhone || '+998 90 000 00 00',
      status: 'yoqolgan',
      createdAt: new Date().toISOString(),
      foundAt: null
    };
    memLostItems.unshift(item);
    io.emit('lost_item_reported', item);
    io.emit('all_lost_items_update', memLostItems);
  });

  socket.on('mark_lost_item_found', (data) => {
    const item = memLostItems.find(i => i.id === data.id);
    if (item) {
      item.status = 'topildi';
      item.foundAt = new Date().toISOString();

      const smsData = {
        id: item.id,
        title: item.title,
        busRoute: item.busRoute,
        passengerName: item.passengerName,
        passengerPhone: item.passengerPhone,
        message: `Hurmatli yo'lovchi, siz qidirgan "${item.title}" (${item.busRoute}) topildi! Guliston Markaziy Dispetcherlik xizmatidan (+998 67 225-01-23) olib ketishingiz mumkin.`,
        timestamp: item.foundAt
      };

      io.emit('lost_item_found', smsData);
      io.emit('all_lost_items_update', memLostItems);
    }
  });

  // SOS Alert Triggered
  socket.on('trigger_sos', async (data) => {
    try {
      const bus = memBuses.find(b => b.busCode === data.busCode);
      if (bus) bus.status = 'sos';

      const alert = {
        busCode: data.busCode || 'GUL-001',
        routeName: data.routeName || '17-avtobus',
        driverName: data.driverName || 'Aliyev Vali',
        speed: data.speed || 45,
        latitude: data.latitude || 40.489,
        longitude: data.longitude || 68.776,
        message: data.message || 'FAVQULOTDA HOLAT!',
        timestamp: new Date().toISOString()
      };
      memAlerts.push(alert);
      io.emit('sos_alert_triggered', alert);
      const formatted = formatBuses(memBuses);
      io.emit('bus_location_updated', formatted);
      io.emit('all_buses_update', formatted);
    } catch (e) {}
  });

  // SOS Alert Resolved
  socket.on('resolve_sos', async (data) => {
    try {
      const bus = memBuses.find(b => b.busCode === data.busCode);
      if (bus) bus.status = 'ok';
      io.emit('sos_alert_resolved', { busCode: data.busCode });
      const formatted = formatBuses(memBuses);
      io.emit('bus_location_updated', formatted);
      io.emit('all_buses_update', formatted);
    } catch (e) {}
  });

  socket.on('disconnect', () => {
    console.log(`❌ Klient uzildi: ${socket.id}`);
  });
});

// ─── Continuous Motion Simulation (Guliston buses) ───────────────────────────
setInterval(async () => {
  try {
    for (let bus of memBuses) {
      if (bus.status === 'stopped') continue;

      let lat = bus.latitude + bus.dLat;
      let lng = bus.longitude + bus.dLng;
      let dLat = bus.dLat;
      let dLng = bus.dLng;

      if (lat > 40.5080 || lat < 40.4750) dLat = -dLat;
      if (lng > 68.7980 || lng < 68.7550) dLng = -dLng;

      let speed = bus.status === 'stopped' ? 0 : (bus.speed || 30);

      bus.latitude = parseFloat(lat.toFixed(6));
      bus.longitude = parseFloat(lng.toFixed(6));
      bus.dLat = dLat;
      bus.dLng = dLng;
      bus.speed = speed;

      if (isDbConnected()) {
        try {
          await Bus.findOneAndUpdate(
            { busCode: bus.busCode },
            { latitude: bus.latitude, longitude: bus.longitude, speed, dLat, dLng }
          );
        } catch (e) {}
      }
    }

    const updatedList = formatBuses(memBuses);
    io.emit('bus_location_updated', updatedList);
    io.emit('all_buses_update', updatedList);
  } catch (e) {}
}, 3000);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 SmartBus Backend Server ${PORT}-portda ishga tushdi!`);
});
