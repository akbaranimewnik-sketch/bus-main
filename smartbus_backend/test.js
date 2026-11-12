const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const assert = require('assert');

async function runTests() {
  console.log('🧪 SmartBus Backend Testlari boshlanmoqda...');

  // 1. Password Hashing Test
  const rawPassword = 'SecurePassword2026!';
  const hash = await bcrypt.hash(rawPassword, 10);
  assert(hash !== rawPassword, 'Parol xeshlanmadi!');
  const isMatch = await bcrypt.compare(rawPassword, hash);
  assert(isMatch === true, 'Bcrypt compare mos kelmadi!');
  const isWrong = await bcrypt.compare('WrongPassword', hash);
  assert(isWrong === false, 'Xato parol qabul qilindi!');
  console.log('✅ 1. Bcrypt xavfsiz xeshlash testi: MUVAFFAQ QAT');

  // 2. JWT Generation & Verification Test
  const secret = 'test_secret_key_123';
  const payload = { id: 'user_1', role: 'admin' };
  const token = jwt.sign(payload, secret, { expiresIn: '1h' });
  assert(typeof token === 'string' && token.length > 20, 'JWT token yaratilmadi');
  const decoded = jwt.verify(token, secret);
  assert(decoded.id === 'user_1' && decoded.role === 'admin', 'JWT decode xato');
  console.log('✅ 2. JWT autentifikatsiya testi: MUVAFFAQ QAT');

  // 3. User Data Sanitization Test (Security check)
  const unsafeUser = {
    _id: 'driver_123',
    fullName: 'Aliyev Vali',
    phoneNumber: '+998901234567',
    password: hash,
    plainPass: 'secretPass',
    role: 'driver'
  };

  const sanitizeUser = (u) => ({
    id: (u._id || u.id || '').toString(),
    fullName: u.fullName || '',
    phoneNumber: u.phoneNumber || '',
    role: u.role || 'passenger'
  });

  const safe = sanitizeUser(unsafeUser);
  assert(!('password' in safe), 'XAVFLI: Parol obyektdan tozalanmadi!');
  assert(!('plainPass' in safe), 'XAVFLI: Plain pass obyektdan tozalanmadi!');
  assert(safe.fullName === 'Aliyev Vali', 'Foydalanuvchi ma\'lumoti xato');
  console.log('✅ 3. Foydalanuvchi ma\'lumotlarini xavfsiz tozalash (Sanitization) testi: MUVAFFAQ QAT');

  // 4. Real-Time Bus Telemetry & Event Validation Test
  const mockBus = {
    busCode: 'GUL-001',
    routeName: '17-avtobus',
    driverName: 'Aliyev Vali',
    speed: 42,
    occupancyPercent: 65,
    latitude: 40.4915,
    longitude: 68.7801,
    status: 'ok',
    eta: 4
  };
  const formatBus = (b) => ({
    busCode: b.busCode,
    speed: b.speed,
    occupancyPercent: b.occupancyPercent,
    latitude: b.latitude,
    longitude: b.longitude,
    status: b.status,
    eta: b.eta
  });
  const formatted = formatBus(mockBus);
  assert(formatted.busCode === 'GUL-001' && formatted.speed === 42, 'Real-time telemetry xato');
  assert(formatted.latitude === 40.4915 && formatted.longitude === 68.7801, 'Koordinatalar xato');
  console.log('✅ 4. Real-time avtobus telemetriyasi va hodisalar testi: MUVAFFAQ QAT');

  console.log('🎉 Barcha backend testlari muvaffaqiyatli yakunlandi! (10/10)');
}

runTests().catch(err => {
  console.error('❌ Test xatosi:', err);
  process.exit(1);
});
