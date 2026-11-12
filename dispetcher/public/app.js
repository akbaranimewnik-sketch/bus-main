// ═══════════════════════════════════════════════════════════════════════════
// SMARTBUS DISPETCHER REAL-TIME CONTROLLER (PRO 2026 EDITION)
// ═══════════════════════════════════════════════════════════════════════════

const BACKEND_URL = 'http://localhost:3000';

let socket = null;
let currentSelectedRoute = '17';
let currentSelectedBus = 'SB-017';
let soundEnabled = true;
let isDarkTheme = false;

let leafletMap = null;
let busMapMarkers = {};
let stopMapMarkers = [];

// ─── FLEET DATA (Realistic Tashkent Telematics) ─────────────────────────
let fleetData = [
  {
    busCode: 'SB-017',
    routeCode: '17-062',
    routeNumber: '17',
    routeName: '17 · Chilonzor → Chorsu',
    direction: 'Chilonzor → Chorsu',
    currentStop: 'Bunyodkor',
    nextStop: 'Muqimiy',
    occupancyPercent: 72,
    etaMin: 5,
    speed: 36,
    lat: 41.2842,
    lng: 69.2134,
    status: 'reysda',
    statusLabel: 'Reysda',
    inspection: 'Ko\'rik: 22.10',
    driver: 'Akmal Karimov',
    phone: '+998 90 123 45 67',
    busModel: 'Isuzu CityBus LE-60',
    plateNumber: '01 742 SAA'
  },
  {
    busCode: 'SB-023',
    routeCode: '23-018',
    routeNumber: '23',
    routeName: '23 · Buyuk Ipak yo\'li',
    direction: 'Chilonzor → Buyuk ipak yo\'li',
    currentStop: 'Chilonzor metro',
    nextStop: 'Novza',
    occupancyPercent: 32,
    etaMin: 3,
    speed: 42,
    lat: 41.2783,
    lng: 69.2058,
    status: 'reysda',
    statusLabel: 'Reysda',
    inspection: 'Muammo yo\'q',
    driver: 'Botir Yusupov',
    phone: '+998 93 456 78 90',
    busModel: 'Yutong ZK6128 (Elektrobus)',
    plateNumber: '01 553 SBA'
  },
  {
    busCode: 'SB-080',
    routeCode: '80-031',
    routeNumber: '80',
    routeName: '80 · Toshkent vokzali',
    direction: 'Chilonzor → Toshkent vokzali',
    currentStop: 'Novza',
    nextStop: 'Muqimiy',
    occupancyPercent: 56,
    etaMin: 12,
    speed: 28,
    lat: 41.2917,
    lng: 69.2241,
    status: 'reysda',
    statusLabel: 'Reysda',
    inspection: 'Ko\'rik: 23.10',
    driver: 'Sarvar Olimov',
    phone: '+998 94 888 12 34',
    busModel: 'MAN Lion\'s City CNG',
    plateNumber: '01 912 SCA'
  },
  {
    busCode: 'SB-051',
    routeCode: '51-024',
    routeNumber: '51',
    routeName: '51 · Yunusobod → Chorsu',
    direction: 'Yunusobod → Chorsu',
    currentStop: 'Shahriston',
    nextStop: 'Minor',
    occupancyPercent: 38,
    etaMin: 6,
    speed: 34,
    lat: 41.3520,
    lng: 69.2830,
    status: 'reysda',
    statusLabel: 'Reysda',
    inspection: 'Muammo yo\'q',
    driver: 'Alisher Qodirov',
    phone: '+998 97 711 22 33',
    busModel: 'King Long City',
    plateNumber: '01 321 SDA'
  },
  {
    busCode: 'SB-042',
    routeCode: '--',
    routeNumber: '--',
    routeName: 'Biriktirilmagan',
    direction: 'Biriktirilmagan',
    currentStop: 'Avtosaroy #1',
    nextStop: '--',
    occupancyPercent: 0,
    etaMin: 0,
    speed: 0,
    lat: 41.2650,
    lng: 69.2200,
    status: 'zaxirada',
    statusLabel: 'Zaxirada',
    inspection: 'Tekshiruv kerak',
    driver: 'Navbatchi haydovchi',
    phone: '--',
    busModel: 'Isuzu CityBus',
    plateNumber: '01 114 SEA'
  },
  {
    busCode: 'SB-009',
    routeCode: '--',
    routeNumber: '--',
    routeName: 'Biriktirilmagan',
    direction: 'Biriktirilmagan',
    currentStop: 'Ta\'mirlash sexi',
    nextStop: '--',
    occupancyPercent: 0,
    etaMin: 0,
    speed: 0,
    lat: 41.2610,
    lng: 69.2150,
    status: 'texnik',
    statusLabel: 'Texnik ko\'rik',
    inspection: 'Eshik tekshiruvi',
    driver: '--',
    phone: '--',
    busModel: 'Yutong ZK6128',
    plateNumber: '01 409 SFA'
  },
  {
    busCode: 'SB-021',
    routeCode: '17-063',
    routeNumber: '17',
    routeName: '17 · Chilonzor → Chorsu',
    direction: 'Chilonzor → Chorsu',
    currentStop: 'Chorsu',
    nextStop: 'Bunyodkor',
    occupancyPercent: 61,
    etaMin: 9,
    speed: 38,
    lat: 41.3268,
    lng: 69.2355,
    status: 'reysda',
    statusLabel: 'Reysda',
    inspection: 'Muammo yo\'q',
    driver: 'Javlon Sobirov',
    phone: '+998 99 333 44 55',
    busModel: 'Isuzu CityBus LE-60',
    plateNumber: '01 821 SGA'
  }
];

let routesData = [
  { number: '17', title: 'Chilonzor → Chorsu', services: '12 ta', interval: '8–10 daq', stops: '5 ta · sxema', status: 'faol', statusText: 'Faol', rating: '4.6', demand: '63 kishi' },
  { number: '23', title: 'Chilonzor → Buyuk Ipak yo\'li', services: '10 ta', interval: '6–8 daq', stops: '14 ta', status: 'faol', statusText: 'Faol', rating: '4.8', demand: '45 kishi' },
  { number: '80', title: 'Chilonzor → Toshkent vokzali', services: '9 ta', interval: '10–12 daq', stops: '18 ta', status: 'faol', statusText: 'Faol', rating: '4.4', demand: '52 kishi' },
  { number: '51', title: 'Yunusobod → Chorsu', services: '8 ta', interval: '8–10 daq', stops: '16 ta', status: 'faol', statusText: 'Faol', rating: '4.7', demand: '38 kishi' },
  { number: '67', title: 'Sergeli → Novza', services: '9 ta', interval: '10–15 daq', stops: '20 ta', status: 'faol', statusText: 'Faol', rating: '4.5', demand: '41 kishi' },
  { number: '104', title: 'Yangi Toshkent → Markaz', services: '0 ta', interval: '15 daq · reja', stops: '12 ta · reja', status: 'rejalashtirilgan', statusText: 'Rejalashtirilgan', rating: '--', demand: '20 kishi' }
];

let stopsData = [
  { name: 'Bunyodkor', district: 'Chilonzor tumani', routes: '17, 23, 80', waitTime: '6.5 daq', status: 'Yuqori talab', count: 68, lat: 41.2842, lng: 69.2134 },
  { name: 'Chilonzor metro', district: 'Chilonzor tumani', routes: '17, 23, 51, 80', waitTime: '5.2 daq', status: 'Gavjum', count: 94, lat: 41.2783, lng: 69.2058 },
  { name: 'Muqimiy', district: 'Chilonzor tumani', routes: '17, 80', waitTime: '7.8 daq', status: 'O\'rtacha', count: 42, lat: 41.2975, lng: 69.2312 },
  { name: 'Novza', district: 'Chilonzor tumani', routes: '23, 80, 67', waitTime: '8.1 daq', status: 'O\'rtacha', count: 37, lat: 41.2917, lng: 69.2241 },
  { name: 'Chorsu bozori', district: 'Shayxontohur tumani', routes: '17, 51', waitTime: '4.9 daq', status: 'Yuqori talab', count: 85, lat: 41.3268, lng: 69.2355 }
];

let systemNotifications = [
  { time: '18:25', title: 'Tizim onlayn', desc: 'SmartBus boshqaruv markazi va telemetriya serveri faol.', type: 'info' },
  { time: '18:22', title: 'SB-017 reysda', desc: '17-yo\'nalish bo\'yicha Muqimiy bekatiga yetib keldi.', type: 'bus' }
];

let schedulesData = [
  { id: 'SM-104', driver: 'Akmal Karimov', route: '17 · Chilonzor → Chorsu', busCode: 'SB-017', time: '15:00–19:30', status: 'Jarayonda', statusClass: 'badge-green-clean' },
  { id: 'SM-105', driver: 'Javlon Sobirov', route: '17 · Chilonzor → Chorsu', busCode: 'SB-021', time: '18:10–22:20', status: 'Jarayonda', statusClass: 'badge-green-clean' },
  { id: 'SM-106', driver: 'Botir Yusupov', route: '23 · Buyuk Ipak yo\'li', busCode: 'SB-023', time: '14:00–21:30', status: 'Jarayonda', statusClass: 'badge-green-clean' },
  { id: 'SM-107', driver: 'Sarvar Olimov', route: '80 · Toshkent vokzali', busCode: 'SB-080', time: '06:30–14:30', status: 'Tugallangan', statusClass: 'badge-gray-clean' },
  { id: 'SM-108', driver: 'Alisher Qodirov', route: '51 · Yunusobod → Chorsu', busCode: 'SB-051', time: '07:00–15:30', status: 'Tugallangan', statusClass: 'badge-gray-clean' }
];

let staffData = [
  { id: '1', name: 'Akmal Karimov', role: 'Katta haydovchi', phone: '+998 90 123-45-67', busCode: 'SB-017 (17-yo\'nalish)', rating: '4.9 / 5', status: 'Smenada', statusClass: 'badge-green-clean' },
  { id: '2', name: 'Javlon Sobirov', role: '1-toifali haydovchi', phone: '+998 93 456-78-90', busCode: 'SB-021 (17-yo\'nalish)', rating: '4.8 / 5', status: 'Smenada', statusClass: 'badge-green-clean' },
  { id: '3', name: 'Botir Yusupov', role: 'Haydovchi', phone: '+998 94 987-65-43', busCode: 'SB-023 (23-yo\'nalish)', rating: '4.7 / 5', status: 'Smenada', statusClass: 'badge-green-clean' },
  { id: '4', name: 'Sarvar Olimov', role: 'Haydovchi', phone: '+998 94 888-12-34', busCode: 'SB-080 (80-yo\'nalish)', rating: '4.6 / 5', status: 'Dam olishda', statusClass: 'badge-gray-clean' },
  { id: '5', name: 'Alisher Qodirov', role: '1-toifali haydovchi', phone: '+998 97 711-22-33', busCode: 'SB-051 (51-yo\'nalish)', rating: '4.9 / 5', status: 'Dam olishda', statusClass: 'badge-gray-clean' }
];

let inquiriesData = [
  { id: '1', type: 'Topilma', passenger: 'Dilshod Aliyev', busRoute: 'SB-017 (17-yo\'nalish)', desc: 'Hamyon va talabalik guvohnomasi salonda unutilgan', time: '17:40', status: 'Topildi · Xonada', statusClass: 'badge-green-clean' },
  { id: '2', type: 'Taklif', passenger: 'Madina Rahimova', busRoute: '23-yo\'nalish', desc: 'Kechki oraliqni 8 daqiqaga qisqartirish so\'ralgan', time: '16:15', status: 'Ko\'rib chiqilmoqda', statusClass: 'badge-amber-soft' },
  { id: '3', type: 'Shikoyat', passenger: 'Otabek Jo\'rayev', busRoute: '80-yo\'nalish', desc: 'Konditsioner past darajada ishlagan', time: '14:20', status: 'Hal etildi', statusClass: 'badge-green-clean' }
];

let reportsData = [
  { route: '17-yo\'nalish', trips: '84 ta', avgDelay: '1.8 daq', passengers: '12,450 kishi', revenue: '24,900,000', status: 'A\'lo', statusClass: 'badge-green-clean' },
  { route: '23-yo\'nalish', trips: '72 ta', avgDelay: '2.4 daq', passengers: '9,800 kishi', revenue: '19,600,000', status: 'Yaxshi', statusClass: 'badge-green-clean' },
  { route: '80-yo\'nalish', trips: '68 ta', avgDelay: '3.1 daq', passengers: '8,900 kishi', revenue: '17,800,000', status: 'Qoniqarli', statusClass: 'badge-amber-soft' },
  { route: '51-yo\'nalish', trips: '60 ta', avgDelay: '2.0 daq', passengers: '7,600 kishi', revenue: '15,200,000', status: 'Yaxshi', statusClass: 'badge-green-clean' },
  { route: '67-yo\'nalish', trips: '54 ta', avgDelay: '3.8 daq', passengers: '6,900 kishi', revenue: '13,800,000', status: 'Qoniqarli', statusClass: 'badge-amber-soft' }
];

let systemSettings = {
  orgName: "Toshkent shahar jamoat transporti boshqarmasi",
  stationName: "Markaziy Avtobus Dispecherlik Nazorati #1",
  soundAlerts: true,
  crowdAlerts: true
};

// ─── AUDIO SYNTHESIZER ────────────────────────────────────────────────
function playTone(freq = 600, type = 'sine', duration = 0.15) {
  if (!soundEnabled) return;
  try {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    const ctx = new AudioContext();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, ctx.currentTime);
    gain.gain.setValueAtTime(0.12, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + duration);
  } catch (e) {}
}

function playSuccessChime() {
  playTone(587, 'triangle', 0.1);
  setTimeout(() => playTone(880, 'triangle', 0.15), 100);
}

function playWarningAlarm() {
  playTone(880, 'sawtooth', 0.2);
  setTimeout(() => playTone(660, 'sawtooth', 0.2), 220);
  setTimeout(() => playTone(880, 'sawtooth', 0.3), 440);
}

function toggleSound() {
  soundEnabled = !soundEnabled;
  const icon = document.getElementById('soundIcon');
  if (icon) icon.textContent = soundEnabled ? '🔊' : '🔇';
  showToast(soundEnabled ? '🔊 Bildirishnoma ovozlari yoqildi' : '🔇 Ovoz o\'chirildi');
}

function toggleTheme() {
  isDarkTheme = !isDarkTheme;
  document.body.classList.toggle('dark-theme', isDarkTheme);
  const icon = document.getElementById('themeIcon');
  if (icon) icon.textContent = isDarkTheme ? '☀️' : '🌙';
  showToast(isDarkTheme ? '🌙 Tungi rejim faollashtirildi' : '☀️ Kunduzgi rejim faollashtirildi');
}

function triggerTestSOS() {
  playWarningAlarm();
  const alertData = {
    busCode: 'SB-017',
    routeName: '17 · Chilonzor → Chorsu',
    message: 'TEST SIMULYATSIYASI: Salon xavfsizlik datchigi ishga tushdi!'
  };
  const bus = fleetData.find(b => b.busCode === 'SB-017');
  if (bus) {
    bus.status = 'sos';
    bus.statusLabel = '🚨 SOS!';
  }
  const modalMsg = document.getElementById('sosModalMsg');
  if (modalMsg) modalMsg.textContent = alertData.message;
  const modalBus = document.getElementById('sosModalBusCode');
  if (modalBus) modalBus.textContent = alertData.busCode;
  const modalRoute = document.getElementById('sosModalRoute');
  if (modalRoute) modalRoute.textContent = alertData.routeName;

  openModal('sosAlertModal');
  showToast(`🚨 DIQQAT! SB-017 avtobusidan FAVQULODDA SOS SIGNALI KELDI!`, true);
  renderBusesTable();
  renderOverviewFleet(fleetData);
  updateLeafletMapMarkers();
}

// ─── LEAFLET OPENSTREETMAP GPS INTEGRATION ────────────────────────────
function initLeafletMap() {
  const container = document.getElementById('realLiveMap');
  if (!container || typeof L === 'undefined') return;

  try {
    // Center on Tashkent
    leafletMap = L.map('realLiveMap', {
      zoomControl: true,
      attributionControl: false
    }).setView([41.2995, 69.2401], 12);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19
    }).addTo(leafletMap);

    // Render Stops
    stopsData.forEach(s => {
      if (s.lat && s.lng) {
        const stopIcon = L.divIcon({
          className: 'custom-stop-marker',
          html: `<div style="background:#0F172A; color:#FFF; font-size:10px; font-weight:700; padding:3px 7px; border-radius:6px; border:1px solid #64748B; white-space:nowrap; box-shadow:0 2px 6px rgba(0,0,0,0.3);">📍 ${s.name}</div>`,
          iconSize: [80, 24],
          iconAnchor: [40, 12]
        });
        L.marker([s.lat, s.lng], { icon: stopIcon })
          .addTo(leafletMap)
          .bindPopup(`<b>Bekat: ${s.name}</b><br>Yo'lovchilar: <b>${s.count} kishi</b><br>Yo'nalishlar: ${s.routes}`);
      }
    });

    updateLeafletMapMarkers();

    // Map resize invalidation
    setTimeout(() => {
      leafletMap.invalidateSize();
    }, 300);
  } catch (err) {
    console.warn('Leaflet map initialization note:', err);
  }
}

function updateLeafletMapMarkers() {
  if (!leafletMap || typeof L === 'undefined') return;

  fleetData.forEach(b => {
    if (!b.lat || !b.lng) return;

    const isCrowded = b.occupancyPercent >= 70;
    const isSos = b.status === 'sos';
    const markerClass = isSos ? 'leaflet-bus-icon sos-bus' : (isCrowded ? 'leaflet-bus-icon crowded' : 'leaflet-bus-icon');

    const iconHtml = `
      <div class="${markerClass}">
        🚌 ${b.busCode} · ${b.speed || 30} km/s
      </div>
    `;

    const busIcon = L.divIcon({
      className: 'custom-leaflet-icon-wrap',
      html: iconHtml,
      iconSize: [120, 26],
      iconAnchor: [60, 13]
    });

    if (busMapMarkers[b.busCode]) {
      busMapMarkers[b.busCode].setLatLng([b.lat, b.lng]);
      busMapMarkers[b.busCode].setIcon(busIcon);
    } else {
      const marker = L.marker([b.lat, b.lng], { icon: busIcon })
        .addTo(leafletMap)
        .bindPopup(`
          <div style="font-family:'Plus Jakarta Sans',sans-serif; min-width:180px;">
            <div style="font-weight:800; font-size:14px; color:#2563EB;">${b.busCode} (${b.routeNumber}-yo'nalish)</div>
            <div style="font-size:12px; color:#64748B; margin-top:2px;">Haydovchi: <b>${b.driver}</b></div>
            <div style="font-size:12px; margin-top:4px;">Bandlik: <b>${b.occupancyPercent}%</b> | Tezlik: <b>${b.speed || 30} km/s</b></div>
            <div style="font-size:11.5px; color:#10B981; font-weight:700; margin-top:4px;">Holat: ${b.statusLabel}</div>
            <button onclick="showBusDetails('${b.busCode}')" style="margin-top:8px; width:100%; background:#2563EB; color:#FFF; border:none; padding:5px 10px; border-radius:6px; font-size:11px; font-weight:700; cursor:pointer;">Avtobus tafsilotlari</button>
          </div>
        `);
      busMapMarkers[b.busCode] = marker;
    }
  });
}

function switchMapMode(mode) {
  const realWrapper = document.getElementById('realLiveMapWrapper');
  const schematicWrapper = document.getElementById('schematicMapWrapper');
  const btnReal = document.getElementById('btnToggleRealMap');
  const btnSchematic = document.getElementById('btnToggleSchematicMap');

  if (mode === 'real') {
    if (realWrapper) realWrapper.style.display = 'block';
    if (schematicWrapper) schematicWrapper.style.display = 'none';
    if (btnReal) btnReal.classList.add('active');
    if (btnSchematic) btnSchematic.classList.remove('active');
    if (leafletMap) {
      setTimeout(() => leafletMap.invalidateSize(), 100);
    }
  } else {
    if (realWrapper) realWrapper.style.display = 'none';
    if (schematicWrapper) schematicWrapper.style.display = 'block';
    if (btnReal) btnReal.classList.remove('active');
    if (btnSchematic) btnSchematic.classList.add('active');
  }
}

// ─── LIVE DATE & TIME CLOCK ───────────────────────────────────────────
function updateClock() {
  const elements = document.querySelectorAll('.liveClockSubtitle');
  if (!elements.length) return;

  const now = new Date();
  const months = [
    'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
    'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr'
  ];

  const day = now.getDate();
  const month = months[now.getMonth()];
  const year = now.getFullYear();
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  const seconds = String(now.getSeconds()).padStart(2, '0');

  const text = `Toshkent · ${day}-${month} ${year} · ${hours}:${minutes}:${seconds}`;
  elements.forEach(el => el.textContent = text);
}
setInterval(updateClock, 1000);
updateClock();

// ─── VIEW NAVIGATION ──────────────────────────────────────────────────
function showSection(viewId) {
  document.querySelectorAll('.view-panel').forEach(v => v.classList.remove('active'));

  const target = document.getElementById(`view-${viewId}`);
  if (target) {
    target.classList.add('active');
  } else {
    document.getElementById('view-overview')?.classList.add('active');
  }

  document.querySelectorAll('.sidebar-nav .nav-item').forEach(item => {
    const itemData = item.getAttribute('data-view');
    if (itemData === viewId || 
       (viewId === 'route-details' && itemData === 'routes') || 
       (viewId === 'bus-details' && itemData === 'buses')) {
      item.classList.add('active');
    } else {
      item.classList.remove('active');
    }
  });

  if (viewId === 'overview') {
    renderOverviewFleet(fleetData);
    if (leafletMap) setTimeout(() => leafletMap.invalidateSize(), 150);
  } else if (viewId === 'routes') {
    renderRoutesTable();
  } else if (viewId === 'buses') {
    renderBusesTable();
  } else if (viewId === 'stops') {
    renderStopsTable();
  } else if (viewId === 'schedules') {
    renderSchedulesTable();
  } else if (viewId === 'staff') {
    renderStaffTable();
  } else if (viewId === 'inquiries') {
    renderInquiriesTable();
  } else if (viewId === 'reports') {
    renderReportsTable();
  } else if (viewId === 'route-details') {
    updateRouteDetailsView(currentSelectedRoute);
  } else if (viewId === 'bus-details') {
    updateBusDetailsView(currentSelectedBus);
  }

  document.querySelector('.main-content')?.scrollTo({ top: 0, behavior: 'smooth' });
}

function showRouteDetails(routeNumber) {
  currentSelectedRoute = String(routeNumber);
  updateRouteDetailsView(currentSelectedRoute);
  window.location.hash = 'route-details';
  showSection('route-details');
}

function showBusDetails(busCode) {
  currentSelectedBus = busCode;
  updateBusDetailsView(currentSelectedBus);
  window.location.hash = 'bus-details';
  showSection('bus-details');
}

// ─── DYNAMIC ROUTE DETAILS & LIVE STEPPER ─────────────────────────────
function updateRouteDetailsView(routeNum) {
  const route = routesData.find(r => r.number === String(routeNum)) || routesData[0];
  if (!route) return;

  const titleEl = document.querySelector('#view-route-details .page-title');
  if (titleEl) titleEl.textContent = `${route.number}-yo'nalish rejasi`;

  const breadcrumbEl = document.querySelector('#view-route-details .breadcrumb-text');
  if (breadcrumbEl) {
    breadcrumbEl.innerHTML = `<a href="#" onclick="showSection('routes')">Yo'nalishlar</a> / ${route.number} · ${route.title}`;
  }

  const kpiValues = document.querySelectorAll('#view-route-details .kpi-grid .kpi-number');
  if (kpiValues.length >= 4) {
    kpiValues[0].textContent = route.services || '8 ta';
    kpiValues[1].textContent = route.interval || '8–10 daq';
    kpiValues[2].textContent = route.demand || '55 kishi';
    kpiValues[3].textContent = `${route.rating || '4.6'} / 5`;
  }

  const schemaBadge = document.querySelector('#view-route-details .badge-soft-blue');
  if (schemaBadge) schemaBadge.textContent = `${route.title.split('→')[1]?.trim() || 'Shahar'} tomonga`;

  // Dynamic Metro-style Stepper
  const stepperBox = document.getElementById('routeStepperBox');
  if (stepperBox) {
    const stopsList = route.title.includes('→') ? route.title.split('→').map(s => s.trim()) : ['Boshlanish', 'Markaz', 'Yakun'];
    stepperBox.innerHTML = `
      <div class="stepper-stop">
        <div class="stepper-node">1</div>
        <div class="stepper-stop-name">${stopsList[0]}</div>
        <div class="stepper-stop-time">06:00 · Jo'nash</div>
      </div>
      <div style="flex:1; height:3px; background:#2563EB; margin: 0 8px;"></div>
      <div class="stepper-stop active">
        <div class="stepper-node">2</div>
        <div class="stepper-stop-name">Bunyodkor bekati</div>
        <div class="stepper-stop-time" style="color:#10B981; font-weight:700;">🚌 Avtobus bu yerda</div>
      </div>
      <div style="flex:1; height:3px; background:#CBD5E1; margin: 0 8px;"></div>
      <div class="stepper-stop">
        <div class="stepper-node" style="border-color:#94A3B8; color:#94A3B8;">3</div>
        <div class="stepper-stop-name">Muqimiy</div>
        <div class="stepper-stop-time">ETA: 5 daq</div>
      </div>
      <div style="flex:1; height:3px; background:#CBD5E1; margin: 0 8px;"></div>
      <div class="stepper-stop">
        <div class="stepper-node" style="border-color:#94A3B8; color:#94A3B8;">4</div>
        <div class="stepper-stop-name">${stopsList[1] || stopsList[0]}</div>
        <div class="stepper-stop-time">Yakuniy bekat</div>
      </div>
    `;
  }

  const editRouteInput = document.getElementById('editPlanRouteName');
  if (editRouteInput) editRouteInput.value = `${route.number} · ${route.title}`;

  renderRouteTimetable(route.number);
}

// ─── DYNAMIC BUS DETAILS & TELEMETICS COCKPIT ─────────────────────────
function updateBusDetailsView(busCode) {
  const bus = fleetData.find(b => b.busCode === busCode) || fleetData[0];
  if (!bus) return;

  const titleEl = document.querySelector('#view-bus-details .page-title');
  if (titleEl) titleEl.textContent = `${bus.busCode} · Avtobus tafsilotlari`;

  const breadcrumbEl = document.querySelector('#view-bus-details .breadcrumb-text');
  if (breadcrumbEl) {
    breadcrumbEl.innerHTML = `<a href="#" onclick="showSection('buses')">Avtobuslar</a> / ${bus.routeNumber}-yo'nalish / Kod ${bus.busCode}`;
  }

  const kpiCards = document.querySelectorAll('#view-bus-details .kpi-grid .kpi-card');
  if (kpiCards.length >= 4) {
    kpiCards[0].querySelector('.kpi-number').textContent = bus.currentStop;
    kpiCards[0].querySelector('.kpi-subtext').textContent = bus.routeName;

    kpiCards[1].querySelector('.kpi-number').textContent = `${bus.occupancyPercent}%`;
    kpiCards[1].querySelector('.kpi-subtext').textContent = bus.occupancyPercent > 70 ? 'Gavjum' : (bus.occupancyPercent > 35 ? 'O\'rtacha' : 'Bo\'sh');

    kpiCards[2].querySelector('.kpi-number').textContent = `${bus.speed || 32} km/soat`;
    kpiCards[2].querySelector('.kpi-subtext').textContent = 'Telemetriya aniq';

    kpiCards[3].querySelector('.kpi-number').textContent = bus.driver.split(' ')[0] || bus.driver;
    kpiCards[3].querySelector('.kpi-subtext').textContent = bus.phone || 'Biriktirilgan';
  }

  // Live Telematics Cockpit Values
  const spdEl = document.getElementById('telematicsSpeed');
  if (spdEl) spdEl.textContent = `${bus.speed || 36} km/s`;
  const batEl = document.getElementById('telematicsBattery');
  if (batEl) batEl.textContent = `${95 - Math.round(Math.random() * 25)}%`;

  // Assignment & Technical Modals
  const assignCodeInput = document.getElementById('assignBusCode');
  if (assignCodeInput) assignCodeInput.value = bus.busCode;
  const assignDriverInput = document.getElementById('assignDriverName');
  if (assignDriverInput) assignDriverInput.value = bus.driver;

  renderBusTimetable(bus.busCode);
}

// Sidebar Link Clicks
document.querySelectorAll('.sidebar-nav .nav-item').forEach(item => {
  item.addEventListener('click', (e) => {
    e.preventDefault();
    const view = item.getAttribute('data-view');
    if (view) {
      window.location.hash = view;
      showSection(view);
    }
  });
});

window.addEventListener('hashchange', () => {
  const hash = window.location.hash.replace('#', '') || 'overview';
  showSection(hash);
});

// ─── RENDER OVERVIEW FLEET TABLE ──────────────────────────────────────
function renderOverviewFleet(fleet) {
  const tbody = document.getElementById('overviewFleetTableBody');
  if (!tbody) return;

  const query = (document.getElementById('routeSearchInput')?.value || '').trim().toLowerCase();

  const filtered = fleet.filter(item => {
    if (item.status !== 'reysda') return false;
    if (!query) return true;
    return item.routeNumber.toLowerCase().includes(query) ||
           item.direction.toLowerCase().includes(query) ||
           item.currentStop.toLowerCase().includes(query) ||
           item.busCode.toLowerCase().includes(query);
  });

  tbody.innerHTML = filtered.map(item => {
    let occBadge = '';
    if (item.occupancyPercent >= 70) {
      occBadge = `<span class="status-badge badge-red-soft">● Gavjum · ${item.occupancyPercent}%</span>`;
    } else if (item.occupancyPercent >= 40) {
      occBadge = `<span class="status-badge badge-amber-soft">● O'rtacha · ${item.occupancyPercent}%</span>`;
    } else {
      occBadge = `<span class="status-badge badge-green-clean">● Bo'sh · ${item.occupancyPercent}%</span>`;
    }

    return `
      <tr onclick="showRouteDetails('${item.routeNumber}')" class="clickable-row">
        <td>
          <div style="display:flex; align-items:center; gap:8px;">
            <span class="badge-route-blue">${item.routeNumber}</span>
            <span style="font-size:11.5px; color:#64748B; font-weight:600;">${item.busCode}</span>
          </div>
        </td>
        <td class="font-bold">${item.direction}</td>
        <td>${item.currentStop}</td>
        <td>${occBadge}</td>
        <td><span class="text-blue font-bold">${item.etaMin || 5} daq</span></td>
        <td><span class="status-badge badge-green-clean"><span class="pulse-dot-green"></span> Reysda</span></td>
      </tr>
    `;
  }).join('');

  const onRouteCount = fleet.filter(b => b.status === 'reysda').length;
  const crowdedCount = fleet.filter(b => b.status === 'reysda' && b.occupancyPercent >= 70).length;
  const kpiNumbers = document.querySelectorAll('#view-overview .kpi-number');
  if (kpiNumbers.length >= 2) {
    kpiNumbers[0].textContent = onRouteCount;
    kpiNumbers[1].textContent = crowdedCount;
  }
}

// ─── RENDER ROUTES TABLE ──────────────────────────────────────────────
function renderRoutesTable() {
  const tbody = document.getElementById('routesTableBody');
  if (!tbody) return;

  const query = (document.getElementById('routesSearchInput')?.value || '').trim().toLowerCase();
  const statusFilter = document.getElementById('routesStatusFilter')?.value;
  const lineFilter = document.getElementById('routesLinesFilter')?.value;

  const filtered = routesData.filter(r => {
    if (statusFilter && r.status !== statusFilter) return false;
    if (lineFilter && r.number !== lineFilter) return false;
    if (query) {
      return r.number.toLowerCase().includes(query) ||
             r.title.toLowerCase().includes(query);
    }
    return true;
  });

  tbody.innerHTML = filtered.map(r => {
    const isFaol = r.status === 'faol';
    const badgeClass = isFaol ? 'badge-green-clean' : 'badge-gray-clean';
    return `
      <tr onclick="showRouteDetails('${r.number}')" class="clickable-row">
        <td><span class="badge-route-blue">${r.number}</span></td>
        <td class="font-bold">${r.title}</td>
        <td>${r.services}</td>
        <td>${r.interval}</td>
        <td>${r.stops}</td>
        <td><span class="status-badge ${badgeClass}">${r.statusText}</span></td>
      </tr>
    `;
  }).join('');
}

document.getElementById('routesSearchInput')?.addEventListener('input', renderRoutesTable);
document.getElementById('routesStatusFilter')?.addEventListener('change', renderRoutesTable);
document.getElementById('routesLinesFilter')?.addEventListener('change', renderRoutesTable);

// ─── RENDER BUSES / AVTOPARK TABLE ────────────────────────────────────
function renderBusesTable() {
  const tbody = document.getElementById('busesTableBody');
  if (!tbody) return;

  const query = (document.getElementById('busesSearchInput')?.value || '').trim().toLowerCase();
  const statusFilter = document.getElementById('busesStatusFilter')?.value;
  const routeFilter = document.getElementById('busesRouteFilter')?.value;

  const filtered = fleetData.filter(b => {
    if (statusFilter && b.status !== statusFilter) return false;
    if (routeFilter && b.routeNumber !== routeFilter) return false;
    if (query) {
      return b.busCode.toLowerCase().includes(query) ||
             b.routeCode.toLowerCase().includes(query) ||
             b.routeName.toLowerCase().includes(query) ||
             b.driver.toLowerCase().includes(query);
    }
    return true;
  });

  tbody.innerHTML = filtered.map(b => {
    let occCol = '';
    if (b.occupancyPercent >= 70) {
      occCol = `<span class="text-red-bold">Gavjum · ${b.occupancyPercent}%</span>`;
    } else if (b.occupancyPercent >= 40) {
      occCol = `<span class="text-amber-bold">O'rtacha · ${b.occupancyPercent}%</span>`;
    } else if (b.occupancyPercent > 0) {
      occCol = `<span class="text-green-bold">Bo'sh · ${b.occupancyPercent}%</span>`;
    } else {
      occCol = `<span style="color:#94A3B8;">-- · bo'sh</span>`;
    }

    const isReysda = b.status === 'reysda';
    const isSos = b.status === 'sos';
    let badgeClass = 'badge-gray-clean';
    let statusText = b.statusLabel;

    if (isSos) {
      badgeClass = 'badge-red-soft';
      statusText = '🚨 SOS!';
    } else if (isReysda) {
      badgeClass = 'badge-green-clean';
    }

    return `
      <tr onclick="showBusDetails('${b.busCode}')" class="clickable-row">
        <td><span class="font-bold text-blue">${b.busCode} / ${b.routeCode}</span></td>
        <td>${b.routeName}</td>
        <td><span class="status-badge ${badgeClass}">${statusText}</span></td>
        <td>${occCol}</td>
        <td>${b.speed ? b.speed + ' km/s' : '0 km/s'}</td>
        <td>${b.inspection}</td>
      </tr>
    `;
  }).join('');
}

document.getElementById('busesSearchInput')?.addEventListener('input', renderBusesTable);
document.getElementById('busesStatusFilter')?.addEventListener('change', renderBusesTable);
document.getElementById('busesRouteFilter')?.addEventListener('change', renderBusesTable);
document.getElementById('routeSearchInput')?.addEventListener('input', () => renderOverviewFleet(fleetData));

// ─── RENDER STOPS TABLE ───────────────────────────────────────────────
function renderStopsTable() {
  const tbody = document.getElementById('stopsTableBody');
  if (!tbody) return;

  tbody.innerHTML = stopsData.map(s => {
    const isHigh = s.status === 'Yuqori talab' || s.status === 'Gavjum';
    const badgeClass = isHigh ? 'badge-red-soft' : 'badge-green-clean';
    return `
      <tr>
        <td class="font-bold">${s.name}</td>
        <td>${s.district}</td>
        <td>${s.routes}</td>
        <td><span class="font-bold text-blue">${s.waitTime}</span></td>
        <td><span class="status-badge ${badgeClass}">${s.status}</span></td>
        <td><strong>${s.count} kishi</strong></td>
      </tr>
    `;
  }).join('');
}

// ─── RENDER SCHEDULES / SHIFTS TABLE ──────────────────────────────────
function renderSchedulesTable() {
  const tbody = document.getElementById('schedulesTableBody');
  if (!tbody) return;

  tbody.innerHTML = schedulesData.map(s => `
    <tr>
      <td><span class="badge-route-blue">${s.id}</span></td>
      <td class="font-bold">${s.driver}</td>
      <td>${s.route}</td>
      <td><span class="font-bold text-blue">${s.busCode}</span></td>
      <td>${s.time}</td>
      <td>
        <div style="display:flex; align-items:center; gap:8px;">
          <span class="status-badge ${s.statusClass || 'badge-green-clean'}">${s.status}</span>
          <button class="icon-button" onclick="deleteShift('${s.id}')" title="O'chirish" style="width:24px; height:24px; padding:0; border:none; background:transparent; cursor:pointer; color:#94A3B8; font-size:16px;">&times;</button>
        </div>
      </td>
    </tr>
  `).join('');
}

function deleteShift(id) {
  if (!confirm(`Smena ${id} ni ro'yxatdan o'chirmoqchimisiz?`)) return;
  schedulesData = schedulesData.filter(s => s.id !== id);
  renderSchedulesTable();
  fetch(`${BACKEND_URL}/api/shifts/${id}`, { method: 'DELETE' }).catch(() => {});
  showToast(`🗑️ Smena ${id} o'chirildi!`);
}

// ─── RENDER STAFF / DRIVERS TABLE ─────────────────────────────────────
function renderStaffTable() {
  const tbody = document.getElementById('staffTableBody');
  if (!tbody) return;

  tbody.innerHTML = staffData.map(st => `
    <tr>
      <td class="font-bold text-blue">${st.name}</td>
      <td>${st.role}</td>
      <td>${st.phone}</td>
      <td>${st.busCode}</td>
      <td><span class="text-green-bold">${st.rating}</span></td>
      <td>
        <div style="display:flex; align-items:center; gap:8px;">
          <span class="status-badge ${st.statusClass || 'badge-green-clean'}">${st.status}</span>
          <button class="icon-button" onclick="deleteStaff('${st.id}')" title="O'chirish" style="width:24px; height:24px; padding:0; border:none; background:transparent; cursor:pointer; color:#94A3B8; font-size:16px;">&times;</button>
        </div>
      </td>
    </tr>
  `).join('');
}

function deleteStaff(id) {
  if (!confirm(`Xodimni ro'yxatdan o'chirmoqchimisiz?`)) return;
  const staff = staffData.find(s => s.id === id);
  staffData = staffData.filter(s => s.id !== id);
  renderStaffTable();
  fetch(`${BACKEND_URL}/api/drivers/${id}`, { method: 'DELETE' }).catch(() => {});
  showToast(`🗑️ ${staff?.name || 'Xodim'} o'chirildi!`);
}

// ─── RENDER INQUIRIES & LOST ITEMS TABLE ──────────────────────────────
function renderInquiriesTable() {
  const tbody = document.getElementById('inquiriesTableBody');
  if (!tbody) return;

  tbody.innerHTML = inquiriesData.map(iq => {
    let typeBadge = 'badge-route-blue';
    if (iq.type.includes('Shikoyat')) typeBadge = 'badge-red-soft';
    if (iq.type.includes('Taklif')) typeBadge = 'badge-soft-yellow';

    return `
      <tr>
        <td><span class="${typeBadge}">${iq.type}</span></td>
        <td class="font-bold">${iq.passenger}</td>
        <td>${iq.busRoute}</td>
        <td>${iq.desc}</td>
        <td>${iq.time}</td>
        <td>
          <div style="display:flex; align-items:center; gap:8px;">
            <span class="status-badge ${iq.statusClass || 'badge-green-clean'}">${iq.status}</span>
            ${iq.status.includes('Ko\'rib') ? `<button class="primary-blue-btn" onclick="resolveInquiry('${iq.id}')" style="padding:4px 8px; font-size:11px; border-radius:6px;">Hal etish</button>` : ''}
            <button class="icon-button" onclick="deleteInquiry('${iq.id}')" title="O'chirish" style="width:24px; height:24px; padding:0; border:none; background:transparent; cursor:pointer; color:#94A3B8; font-size:16px;">&times;</button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

function resolveInquiry(id) {
  const item = inquiriesData.find(i => i.id === id);
  if (item) {
    item.status = 'Hal etildi';
    item.statusClass = 'badge-green-clean';
    renderInquiriesTable();
    fetch(`${BACKEND_URL}/api/inquiries/${id}/status`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: 'Hal etildi' })
    }).catch(() => {});
    showToast(`✅ Murojaat (#${id}) hal etildi deb belgilandi!`);
  }
}

function deleteInquiry(id) {
  if (!confirm(`Murojaatni o'chirmoqchimisiz?`)) return;
  inquiriesData = inquiriesData.filter(i => i.id !== id);
  renderInquiriesTable();
  fetch(`${BACKEND_URL}/api/inquiries/${id}`, { method: 'DELETE' }).catch(() => {});
  showToast(`🗑️ Murojaat o'chirildi!`);
}

// ─── RENDER REPORTS & EFFICIENCY TABLE ────────────────────────────────
function renderReportsTable() {
  const tbody = document.getElementById('reportsTableBody');
  if (!tbody) return;

  tbody.innerHTML = reportsData.map(rp => `
    <tr>
      <td class="font-bold text-blue">${rp.route}</td>
      <td>${rp.trips}</td>
      <td>${rp.avgDelay}</td>
      <td>${rp.passengers}</td>
      <td><strong>${rp.revenue}</strong> so'm</td>
      <td><span class="status-badge ${rp.statusClass || 'badge-green-clean'}">${rp.status}</span></td>
    </tr>
  `).join('');
}

// ─── DYNAMIC TIMETABLE RENDERERS ──────────────────────────────────────
function renderRouteTimetable(routeNum) {
  const tbody = document.getElementById('routeTimetableBody');
  if (!tbody) return;

  const route = routesData.find(r => r.number === String(routeNum)) || routesData[0];
  const steps = [
    { stop: 'Chilonzor', time: '18:00', stage: 'Jo\'nash bekati' },
    { stop: 'Bunyodkor', time: '18:25', stage: 'Joriy bekat' },
    { stop: 'Muqimiy', time: '18:30', stage: 'Keyingi bekat' },
    { stop: 'Chilonzor metro', time: '18:33', stage: 'Oraliq bekat' },
    { stop: 'Novza', time: '18:42', stage: 'Oraliq bekat' },
    { stop: 'Chorsu', time: '19:10', stage: 'Yakuniy bekat' }
  ];

  tbody.innerHTML = steps.map(s => `
    <tr>
      <td class="font-bold text-blue">${s.stop}</td>
      <td>${s.time}</td>
      <td><span class="status-badge badge-green-clean">${s.stage}</span></td>
    </tr>
  `).join('');
}

function renderBusTimetable(busCode) {
  const tbody = document.getElementById('busTimetableBody');
  if (!tbody) return;

  const bus = fleetData.find(b => b.busCode === busCode) || fleetData[0];
  const steps = [
    { stage: `${bus.currentStop} · O'tgan bekat`, time: '18:15', status: 'O\'tildi' },
    { stage: `${bus.nextStop} · Hozirgi oraliq`, time: '18:25', status: 'Harakatda' },
    { stage: 'Muqimiy · Keyingi', time: '18:32', status: `${bus.etaMin || 5} daqiqada` },
    { stage: 'Chorsu · Yakun', time: '19:05', status: 'Rejalashtirilgan' }
  ];

  tbody.innerHTML = steps.map(s => `
    <tr>
      <td class="font-bold text-blue">${s.stage}</td>
      <td>${s.time}</td>
      <td><span class="status-badge badge-green-clean">${s.status}</span></td>
    </tr>
  `).join('');
}

// ─── PLAN FORM HANDLER ────────────────────────────────────────────────
function savePlanForm(event) {
  if (event) event.preventDefault();
  playSuccessChime();
  showToast(`✅ Xizmat rejasi loyihasi muvaffaqiyatli saqlandi!`);
}

// ─── SETTINGS HANDLER ─────────────────────────────────────────────────
function saveSettings() {
  const orgName = document.getElementById('settingOrgName')?.value || systemSettings.orgName;
  const stationName = document.getElementById('settingStationName')?.value || systemSettings.stationName;
  const sosAlert = document.getElementById('settingSosAlert')?.checked ?? true;
  const crowdAlert = document.getElementById('settingCrowdAlert')?.checked ?? true;

  systemSettings = { orgName, stationName, soundAlerts: sosAlert, crowdAlerts: crowdAlert };
  fetch(`${BACKEND_URL}/api/settings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(systemSettings)
  }).catch(() => {});

  playSuccessChime();
  showToast('⚙️ Tizim sozlamalari muvaffaqiyatli saqlandi!');
}

// ─── MODAL CONTROLS ───────────────────────────────────────────────────
function openModal(modalId) {
  const modal = document.getElementById(modalId);
  if (!modal) {
    showToast(`⚠️ Oyna (${modalId}) tayyorlanmoqda...`);
    return;
  }
  modal.classList.add('active');
  playTone(520, 'sine', 0.08);
}

function closeModal(modalId) {
  document.getElementById(modalId)?.classList.remove('active');
}

function showToast(message, isAlert = false) {
  const toast = document.getElementById('toastNotification');
  if (!toast) return;

  toast.innerHTML = message;
  toast.className = isAlert ? 'toast-box toast-alert' : 'toast-box';
  toast.style.display = 'block';

  if (isAlert) {
    playWarningAlarm();
  } else {
    playSuccessChime();
  }

  addSystemNotification(message, isAlert ? 'alert' : 'info');

  setTimeout(() => {
    toast.style.display = 'none';
  }, 4000);
}

function addSystemNotification(msg, type = 'info') {
  const now = new Date();
  const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  systemNotifications.unshift({
    time: timeStr,
    title: type === 'alert' ? 'Favqulodda xabar' : 'Tizim xabari',
    desc: msg.replace(/<[^>]*>?/gm, ''),
    type
  });
  renderNotificationsDropdown();
}

function toggleNotificationMenu() {
  const dropdown = document.getElementById('notificationDropdownMenu');
  if (!dropdown) return;
  dropdown.classList.toggle('active');
}

function renderNotificationsDropdown() {
  const container = document.getElementById('notificationListContainer');
  const dot = document.querySelector('.notif-dot');
  if (dot) dot.style.display = systemNotifications.length ? 'block' : 'none';
  if (!container) return;

  container.innerHTML = systemNotifications.slice(0, 6).map(n => `
    <div class="notif-item ${n.type === 'alert' ? 'notif-alert' : ''}">
      <div class="notif-item-header">
        <span class="notif-item-title">${n.title}</span>
        <span class="notif-item-time">${n.time}</span>
      </div>
      <p class="notif-item-desc">${n.desc}</p>
    </div>
  `).join('');
}

// ─── FORM HANDLERS ────────────────────────────────────────────────────
function handleCreateRouteSubmit(e) {
  e.preventDefault();
  const num = document.getElementById('newRouteNumber')?.value.trim();
  const start = document.getElementById('newRouteStart')?.value.trim();
  const end = document.getElementById('newRouteEnd')?.value.trim();
  const interval = document.getElementById('newRouteInterval')?.value.trim();

  if (!num || !start || !end) return;

  routesData.push({
    number: num,
    title: `${start} → ${end}`,
    services: '1 ta',
    interval: `${interval} daq`,
    stops: '8 ta · sxema',
    status: 'faol',
    statusText: 'Faol',
    rating: '5.0',
    demand: '30 kishi'
  });

  closeModal('createRouteModal');
  renderRoutesTable();
  showToast(`✅ <strong>${num}-yo'nalish</strong> muvaffaqiyatli qo'shildi!`);

  if (socket) {
    socket.emit('route_created', { number: num, start, end, interval });
  }
}

function handleAddBusSubmit(e) {
  e.preventDefault();
  const code = document.getElementById('newBusCode')?.value.trim();
  const route = document.getElementById('newBusRoute')?.value;
  const status = document.getElementById('newBusStatus')?.value;

  if (!code) return;

  fleetData.push({
    busCode: code,
    routeCode: `${route}-099`,
    routeNumber: route,
    routeName: `${route} · Yo'nalish`,
    direction: 'Markaz → Shahar',
    currentStop: 'Depo',
    nextStop: 'Reys kutmoqda',
    occupancyPercent: 10,
    etaMin: 15,
    speed: 0,
    lat: 41.2750 + (Math.random() * 0.04),
    lng: 69.2100 + (Math.random() * 0.04),
    status: status,
    statusLabel: status === 'reysda' ? 'Reysda' : (status === 'zaxirada' ? 'Zaxirada' : 'Texnik ko\'rik'),
    inspection: 'Soz holatda',
    driver: 'Navbatchi haydovchi',
    phone: '+998 90 000 00 00',
    busModel: 'Isuzu CityBus',
    plateNumber: '01 999 ZZZ'
  });

  closeModal('addBusModal');
  renderBusesTable();
  renderOverviewFleet(fleetData);
  updateLeafletMapMarkers();
  showToast(`✅ <strong>${code}</strong> avtobusi tizimga kiritildi!`);

  if (socket) {
    socket.emit('bus_added', { busCode: code, routeNumber: route, status });
  }
}

function handleEditPlanSubmit(e) {
  e.preventDefault();
  const count = document.getElementById('editPlanBusesCount')?.value;
  const interval = document.getElementById('editPlanInterval')?.value;
  const status = document.getElementById('editPlanStatus')?.value;

  const route = routesData.find(r => r.number === currentSelectedRoute);
  if (route) {
    route.services = `${count} ta`;
    route.interval = `${interval} daq`;
    route.status = status;
    route.statusText = status === 'faol' ? 'Faol' : 'Kuzatuvda';
  }

  closeModal('editPlanModal');
  updateRouteDetailsView(currentSelectedRoute);
  renderRoutesTable();
  showToast(`✅ <strong>${currentSelectedRoute}-yo'nalish</strong> xizmat rejasi saqlandi!`);
}

function handleAssignmentSubmit(e) {
  e.preventDefault();
  const busCode = document.getElementById('assignBusCode')?.value;
  const routeNum = document.getElementById('assignRouteSelect')?.value;
  const driver = document.getElementById('assignDriverName')?.value;
  const status = document.getElementById('assignStatusSelect')?.value;

  const bus = fleetData.find(b => b.busCode === busCode);
  if (bus) {
    bus.routeNumber = routeNum;
    bus.driver = driver;
    bus.status = status;
    bus.statusLabel = status === 'reysda' ? 'Reysda' : (status === 'zaxirada' ? 'Zaxirada' : 'Texnik ko\'rik');
  }

  closeModal('viewAssignmentModal');
  updateBusDetailsView(busCode);
  renderBusesTable();
  renderOverviewFleet(fleetData);
  updateLeafletMapMarkers();
  showToast(`✅ <strong>${busCode}</strong> yangilangan haydovchi (${driver}) bilan biriktirildi!`);
}

function handleAddStopSubmit(e) {
  e.preventDefault();
  const name = document.getElementById('newStopName')?.value.trim();
  const district = document.getElementById('newStopDistrict')?.value;
  const routes = document.getElementById('newStopRoutes')?.value.trim();
  const demand = document.getElementById('newStopDemand')?.value;

  if (!name) return;

  stopsData.unshift({
    name,
    district,
    routes,
    waitTime: '5.5 daq',
    status: demand === 'yuqori' ? 'Yuqori talab' : 'O\'rtacha',
    count: demand === 'yuqori' ? 75 : 30,
    lat: 41.2950 + (Math.random() * 0.03),
    lng: 69.2300 + (Math.random() * 0.03)
  });

  closeModal('addStopModal');
  renderStopsTable();
  showToast(`✅ <strong>${name}</strong> bekati muvaffaqiyatli qo'shildi!`);
}

function handleAddDriverSubmit(e) {
  e.preventDefault();
  const name = document.getElementById('newDriverName')?.value.trim();
  const phone = document.getElementById('newDriverPhone')?.value.trim();
  const bus = document.getElementById('newDriverBus')?.value.trim();

  if (!name) return;

  const newDriver = {
    id: 'driver_' + Date.now(),
    name,
    role: 'Haydovchi',
    phone: phone || '+998 90 000 00 00',
    busCode: bus || 'SB-017',
    rating: '5.0 / 5',
    status: 'Smenada',
    statusClass: 'badge-green-clean'
  };

  staffData.unshift(newDriver);
  closeModal('addDriverModal');
  renderStaffTable();
  showToast(`✅ Haydovchi <strong>${name}</strong> tizimga qo'shildi!`);

  fetch(`${BACKEND_URL}/api/drivers`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fullName: name, phoneNumber: phone, busCode: bus })
  }).catch(() => {});
}

function handleAddShiftSubmit(e) {
  e.preventDefault();
  const driver = document.getElementById('newShiftDriver')?.value.trim();
  const bus = document.getElementById('newShiftBus')?.value;
  const time = document.getElementById('newShiftType')?.value || '14:00–22:00';

  if (!driver) return;

  const newShift = {
    id: 'SM-' + Math.floor(100 + Math.random() * 900),
    driver,
    route: `${bus?.split(' ')[1] || '17-yo\'nalish'}`,
    busCode: bus || 'SB-017',
    time,
    status: 'Jarayonda',
    statusClass: 'badge-green-clean'
  };

  schedulesData.unshift(newShift);
  closeModal('addShiftModal');
  renderSchedulesTable();
  showToast(`✅ <strong>${driver}</strong> (${bus}) uchun yangi smena tasdiqlandi!`);

  fetch(`${BACKEND_URL}/api/shifts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(newShift)
  }).catch(() => {});
}

function handleAddInquirySubmit(e) {
  e.preventDefault();
  const type = document.getElementById('newInquiryType')?.value;
  const title = document.getElementById('newInquiryTitle')?.value.trim();
  const passenger = document.getElementById('newInquiryPassenger')?.value.trim();
  const route = document.getElementById('newInquiryRoute')?.value.trim();

  if (!title) return;

  const newInq = {
    id: 'inq_' + Date.now(),
    type: type || 'Topilma',
    passenger: passenger || 'Yo\'lovchi',
    busRoute: route || '17-yo\'nalish',
    desc: title,
    time: new Date().toLocaleTimeString().slice(0, 5),
    status: 'Ko\'rib chiqilmoqda',
    statusClass: 'badge-amber-soft'
  };

  inquiriesData.unshift(newInq);
  closeModal('addInquiryModal');
  renderInquiriesTable();
  showToast(`✅ Murojaat kiritildi: <strong>${title}</strong> (${type})`);

  fetch(`${BACKEND_URL}/api/inquiries`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(newInq)
  }).catch(() => {});
}

function handleResolveSos() {
  closeModal('sosAlertModal');
  const bus = fleetData.find(b => b.status === 'sos');
  if (bus) {
    bus.status = 'reysda';
    bus.statusLabel = 'Reysda';
    if (socket) {
      socket.emit('resolve_sos', { busCode: bus.busCode });
    }
  }
  renderBusesTable();
  renderOverviewFleet(fleetData);
  updateLeafletMapMarkers();
  showToast(`✅ SOS signali bekor qilindi, avtobus xavfsiz holatga qaytarildi.`);
}

function handleSendEmergencyTeam() {
  closeModal('sosAlertModal');
  showToast(`🚑 Tezkor brigada yo'naltirildi! Aloqa kanali ochiq.`);
}

// ─── EXPORT FUNCTIONS ─────────────────────────────────────────────────
function exportReportPDF() {
  showToast('📄 Operatsion hisobot chop etishga tayyorlanmoqda...');
  setTimeout(() => {
    window.print();
  }, 600);
}

function exportReportCSV() {
  const headers = ['Avtobus', 'Yo\'nalish', 'Haydovchi', 'Bandlik', 'Holat', 'Tezlik'];
  const rows = fleetData.map(b => [
    b.busCode,
    b.routeName,
    b.driver,
    `${b.occupancyPercent}%`,
    b.statusLabel,
    `${b.speed || 0} km/s`
  ]);

  let csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map(e => e.join(','))].join('\n');
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement('a');
  link.setAttribute('href', encodedUri);
  link.setAttribute('download', 'SmartBus_Operatsion_Hisobot.csv');
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);

  showToast('📊 CSV Hisoboti muvaffaqiyatli yuklab olindi!');
}

document.querySelectorAll('.modal-overlay').forEach(overlay => {
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) {
      overlay.classList.remove('active');
    }
  });
});

// ─── REAL-TIME SOCKET.IO & BACKEND INTEGRATION ─────────────────────────
function updateConnectionStatus(isConnected) {
  const pill = document.getElementById('connectionStatusPill');
  const text = document.getElementById('connectionStatusText');
  if (!pill || !text) return;

  if (isConnected) {
    pill.className = 'connection-status-pill online';
    text.textContent = 'Jonli: Backend ulangan';
  } else {
    pill.className = 'connection-status-pill offline';
    text.textContent = 'Oflayn rejim';
  }
}

async function fetchInitialBackendData() {
  try {
    const res = await fetch(`${BACKEND_URL}/api/buses`);
    if (res.ok) {
      const data = await res.json();
      if (data && data.success && Array.isArray(data.data) && data.data.length > 0) {
        data.data.forEach(bb => {
          const existing = fleetData.find(f => f.busCode === bb.busCode);
          if (existing) {
            existing.speed = bb.speed;
            existing.occupancyPercent = bb.occupancyPercent;
            existing.driver = bb.driverName || existing.driver;
            if (bb.latitude && bb.longitude) {
              existing.lat = bb.latitude;
              existing.lng = bb.longitude;
            }
          } else {
            fleetData.unshift({
              busCode: bb.busCode,
              routeCode: `${bb.routeName?.replace(/[^0-9]/g, '') || '01'}-001`,
              routeNumber: bb.routeName?.replace(/[^0-9]/g, '') || '1',
              routeName: bb.routeName || 'Yo\'nalish',
              direction: 'Markaz → Manzil',
              currentStop: 'Yo\'lda',
              nextStop: 'Navbatdagi bekat',
              occupancyPercent: bb.occupancyPercent || 40,
              etaMin: bb.eta || 4,
              speed: bb.speed || 30,
              lat: bb.latitude || (41.28 + Math.random() * 0.04),
              lng: bb.longitude || (69.21 + Math.random() * 0.04),
              status: bb.status === 'late' ? 'reysda' : 'reysda',
              statusLabel: bb.status === 'late' ? 'Kechikishda' : 'Reysda',
              inspection: 'Soz holatda',
              driver: bb.driverName || 'Haydovchi',
              phone: '+998 90 000 00 00',
              busModel: 'Isuzu CityBus',
              plateNumber: `01 ${bb.busCode} AA`
            });
          }
        });
        renderOverviewFleet(fleetData);
        renderBusesTable();
        updateLeafletMapMarkers();
      }
    }

    // Fetch Routes
    fetch(`${BACKEND_URL}/api/routes`).then(r => r.json()).then(d => {
      if (d && d.success && Array.isArray(d.data) && d.data.length) {
        routesData = d.data;
        renderRoutesTable();
      }
    }).catch(() => {});

    // Fetch Stops
    fetch(`${BACKEND_URL}/api/stops`).then(r => r.json()).then(d => {
      if (d && d.success && Array.isArray(d.data) && d.data.length) {
        stopsData = d.data;
        renderStopsTable();
      }
    }).catch(() => {});

    // Fetch Shifts
    fetch(`${BACKEND_URL}/api/shifts`).then(r => r.json()).then(d => {
      if (d && d.success && Array.isArray(d.data) && d.data.length) {
        schedulesData = d.data;
        renderSchedulesTable();
      }
    }).catch(() => {});

    // Fetch Drivers
    fetch(`${BACKEND_URL}/api/drivers`).then(r => r.json()).then(d => {
      if (d && d.success && Array.isArray(d.data) && d.data.length) {
        staffData = d.data.map(dr => ({
          id: dr.id || dr._id,
          name: dr.fullName,
          role: 'Haydovchi',
          phone: dr.phoneNumber || '+998 90 123 45 67',
          busCode: dr.busCode || 'SB-017',
          rating: '4.8 / 5',
          status: 'Smenada',
          statusClass: 'badge-green-clean'
        }));
        renderStaffTable();
      }
    }).catch(() => {});

    // Fetch Inquiries
    fetch(`${BACKEND_URL}/api/inquiries`).then(r => r.json()).then(d => {
      if (d && d.success && Array.isArray(d.data) && d.data.length) {
        inquiriesData = d.data;
        renderInquiriesTable();
      }
    }).catch(() => {});
  } catch (e) {
    console.log('Backend initial fetch fallback to local store');
  }
}

function initSocket() {
  try {
    if (typeof io !== 'undefined') {
      socket = io(BACKEND_URL, {
        reconnection: true,
        reconnectionDelay: 2000
      });

      socket.on('connect', () => {
        console.log('✅ Dispetcher Web backend Socket.IO ga ulandi! ID:', socket.id);
        updateConnectionStatus(true);
        showToast('🟢 Backend serverga real-time ulanish o\'rnatildi!');
      });

      socket.on('disconnect', () => {
        console.log('❌ Backend uzildi, qayta ulanish kutilmoqda...');
        updateConnectionStatus(false);
      });

      socket.on('all_buses_update', (busesList) => {
        if (!Array.isArray(busesList)) return;
        busesList.forEach(b => {
          const item = fleetData.find(f => f.busCode === b.busCode);
          if (item) {
            item.speed = b.speed;
            item.occupancyPercent = b.occupancyPercent;
            if (b.latitude && b.longitude) {
              item.lat = b.latitude;
              item.lng = b.longitude;
            }
            if (b.status === 'sos') item.status = 'sos';
          }
        });
        renderOverviewFleet(fleetData);
        renderBusesTable();
        updateLeafletMapMarkers();
      });

      socket.on('bus_location_updated', (busesList) => {
        if (Array.isArray(busesList) && busesList[0]) {
          const b = busesList[0];
          const item = fleetData.find(f => f.busCode === b.busCode);
          if (item) {
            item.speed = b.speed;
            item.occupancyPercent = b.occupancyPercent;
            if (b.latitude && b.longitude) {
              item.lat = b.latitude;
              item.lng = b.longitude;
            }
            renderOverviewFleet(fleetData);
            updateLeafletMapMarkers();
          }
        }
      });

      socket.on('route_added', (newRoute) => {
        if (!routesData.some(r => r.number === newRoute.number)) {
          routesData.unshift(newRoute);
          renderRoutesTable();
          showToast(`🗺️ Yangi yo'nalish qo'shildi: <strong>${newRoute.number || newRoute.routeNumber}</strong>`);
        }
      });

      socket.on('route_deleted', ({ id }) => {
        routesData = routesData.filter(r => r.id !== id && r.number !== id);
        renderRoutesTable();
      });

      socket.on('bus_added', (newBus) => {
        if (!fleetData.some(b => b.busCode === newBus.busCode)) {
          fleetData.unshift(newBus);
          renderBusesTable();
          renderOverviewFleet(fleetData);
          updateLeafletMapMarkers();
        }
      });

      socket.on('bus_deleted', ({ busCode }) => {
        fleetData = fleetData.filter(b => b.busCode !== busCode);
        renderBusesTable();
        renderOverviewFleet(fleetData);
        updateLeafletMapMarkers();
      });

      socket.on('shift_added', (newShift) => {
        if (!schedulesData.some(s => s.id === newShift.id)) {
          schedulesData.unshift(newShift);
          renderSchedulesTable();
        }
      });

      socket.on('shift_deleted', ({ id }) => {
        schedulesData = schedulesData.filter(s => s.id !== id);
        renderSchedulesTable();
      });

      socket.on('driver_added', (d) => {
        if (!staffData.some(st => st.id === d.id)) {
          staffData.unshift({
            id: d.id,
            name: d.fullName,
            role: 'Haydovchi',
            phone: d.phoneNumber || '+998 90 123 45 67',
            busCode: d.busCode || 'SB-017',
            rating: '5.0 / 5',
            status: 'Smenada',
            statusClass: 'badge-green-clean'
          });
          renderStaffTable();
        }
      });

      socket.on('driver_deleted', ({ id }) => {
        staffData = staffData.filter(st => st.id !== id);
        renderStaffTable();
      });

      socket.on('inquiry_added', (iq) => {
        if (!inquiriesData.some(i => i.id === iq.id)) {
          inquiriesData.unshift(iq);
          renderInquiriesTable();
        }
      });

      socket.on('inquiry_updated', (iq) => {
        const item = inquiriesData.find(i => i.id === iq.id);
        if (item) {
          Object.assign(item, iq);
          renderInquiriesTable();
        }
      });

      socket.on('inquiry_deleted', ({ id }) => {
        inquiriesData = inquiriesData.filter(i => i.id !== id);
        renderInquiriesTable();
      });

      socket.on('sos_alert_triggered', (data) => {
        const busCode = data.busCode || 'SB-017';
        const item = fleetData.find(b => b.busCode === busCode);
        if (item) {
          item.status = 'sos';
          item.statusLabel = '🚨 SOS!';
        }

        const modalMsg = document.getElementById('sosModalMsg');
        if (modalMsg) modalMsg.textContent = data.message || 'Favqulodda vaziyat signali yuborildi!';
        const modalBus = document.getElementById('sosModalBusCode');
        if (modalBus) modalBus.textContent = busCode;
        const modalRoute = document.getElementById('sosModalRoute');
        if (modalRoute) modalRoute.textContent = data.routeName || '17-yo\'nalish';

        openModal('sosAlertModal');
        showToast(`🚨 DIQQAT! ${busCode}dan FAVQULODDA SOS SIGNAL KELDI!`, true);
        renderBusesTable();
        renderOverviewFleet(fleetData);
        updateLeafletMapMarkers();
      });

      socket.on('sos_alert_resolved', (data) => {
        const item = fleetData.find(b => b.busCode === data.busCode);
        if (item) {
          item.status = 'reysda';
          item.statusLabel = 'Reysda';
        }
        closeModal('sosAlertModal');
        showToast(`✅ ${data.busCode} SOS xavfi bekor qilindi.`);
        renderBusesTable();
        updateLeafletMapMarkers();
      });

      socket.on('delay_alert_triggered', (data) => {
        showToast(`⚠️ Tirbandlik ogohlantirishi: ${data.busCode || 'Avtobus'} kechikmoqda.`, false);
      });

      socket.on('lost_item_reported', (item) => {
        showToast(`🎒 Yangi topilma: "${item.title || 'Buyum'}" ro'yxatga olindi.`);
      });
    }
  } catch (err) {
    console.warn('Socket connection fallback:', err);
    updateConnectionStatus(false);
  }
}

// ─── INITIALIZATION ───────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  const initialHash = window.location.hash.replace('#', '') || 'overview';
  showSection(initialHash);

  renderOverviewFleet(fleetData);
  renderRoutesTable();
  renderBusesTable();
  renderStopsTable();
  renderSchedulesTable();
  renderStaffTable();
  renderInquiriesTable();
  renderReportsTable();
  renderNotificationsDropdown();

  initLeafletMap();

  document.querySelectorAll('.notification-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      toggleNotificationMenu();
    });
  });

  document.querySelectorAll('.district-dropdown').forEach(dd => {
    dd.addEventListener('click', () => {
      const districts = ['Barcha tumanlar', 'Chilonzor tumani', 'Shayxontohur tumani', 'Yunusobod tumani', 'Mirzo Ulug\'bek tumani'];
      const cur = dd.querySelector('span')?.textContent || '';
      const nextIdx = (districts.indexOf(cur) + 1) % districts.length;
      const selected = districts[nextIdx];
      document.querySelectorAll('.district-dropdown span').forEach(s => s.textContent = selected);
      showToast(`📍 Filtrlash: ${selected}`);
    });
  });

  document.addEventListener('click', (e) => {
    const dropdown = document.getElementById('notificationDropdownMenu');
    if (dropdown && !dropdown.contains(e.target)) {
      dropdown.classList.remove('active');
    }
  });

  fetchInitialBackendData();
  initSocket();
});
