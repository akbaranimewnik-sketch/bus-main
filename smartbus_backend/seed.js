require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const UserSchema = new mongoose.Schema({
  fullName: String,
  phoneNumber: String,
  password: String,
  role: String,
  isOnline: Boolean,
  lastLogin: Date
}, { timestamps: true });

const BusSchema = new mongoose.Schema({
  busId: String,
  busCode: String,
  routeName: String,
  driverName: String,
  speed: Number,
  occupancyPercent: Number,
  latitude: Number,
  longitude: Number,
  dLat: Number,
  dLng: Number,
  status: String,
  eta: Number
}, { timestamps: true });

const User = mongoose.model('User', UserSchema);
const Bus = mongoose.model('Bus', BusSchema);

// Standard Non-SRV Direct Connection String
const DIRECT_URI = "mongodb://suxrobnazarov2002_db_user:rM2I9TVLAvAyFHXX@cluster0-shard-00-00.dlnyxrx.mongodb.net:27017,cluster0-shard-00-01.dlnyxrx.mongodb.net:27017,cluster0-shard-00-02.dlnyxrx.mongodb.net:27017/smartbus?ssl=true&authSource=admin&retryWrites=true&w=majority";

async function runSeed() {
  console.log('🔄 MongoDB Atlas-ga ulanmoqda (Direct Mode)...');
  try {
    await mongoose.connect(DIRECT_URI);
    console.log('✅ Connected!');

    // Create Admin User
    const hashed = await bcrypt.hash('123456', 10);
    await User.findOneAndUpdate(
      { phoneNumber: '+998901234567' },
      {
        fullName: 'Guliston Admin',
        phoneNumber: '+998901234567',
        password: hashed,
        role: 'admin',
        isOnline: true,
        lastLogin: new Date()
      },
      { upsert: true, new: true }
    );
    console.log('👤 Admin user yaratildi/yangilandi!');

    // Create Guliston Buses
    const buses = [
      { busId: '1', busCode: 'GUL-001', routeName: '17-avtobus', driverName: 'Aliyev Vali', speed: 34, occupancyPercent: 42, latitude: 40.4910, longitude: 68.7780, dLat: 0.00025, dLng: 0.00035, status: 'ok', eta: 3 },
      { busId: '2', busCode: 'GUL-002', routeName: '5-avtobus', driverName: 'Karimov Jasur', speed: 28, occupancyPercent: 65, latitude: 40.4950, longitude: 68.7830, dLat: -0.0002, dLng: 0.0003, status: 'ok', eta: 5 },
      { busId: '3', busCode: 'GUL-003', routeName: '8-avtobus', driverName: 'Nazarov Olim', speed: 38, occupancyPercent: 80, latitude: 40.4870, longitude: 68.7710, dLat: 0.00035, dLng: -0.00025, status: 'late', eta: 8 },
      { busId: '4', busCode: 'GUL-004', routeName: '22-avtobus', driverName: 'Yusupov Said', speed: 25, occupancyPercent: 55, latitude: 40.4990, longitude: 68.7900, dLat: -0.0003, dLng: -0.0003, status: 'ok', eta: 4 },
      { busId: '5', busCode: 'GUL-005', routeName: '3-avtobus', driverName: 'Toshmatov Anvar', speed: 18, occupancyPercent: 90, latitude: 40.4830, longitude: 68.7640, dLat: 0.0002, dLng: 0.00045, status: 'ok', eta: 12 }
    ];

    for (let b of buses) {
      await Bus.findOneAndUpdate({ busId: b.busId }, b, { upsert: true });
    }
    console.log('🚌 Avtobuslar MongoDB-ga joylandi!');
    console.log('🎉 Tayyor! MongoDB Atlas-dagi Refresh tugmasini bosing!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Xato:', err.message);
    process.exit(1);
  }
}

runSeed();
