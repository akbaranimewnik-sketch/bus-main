import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api_service.dart';
import '../../core/socket_service.dart';
import '../../core/storage_service.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/occupancy_badge.dart';
import '../../widgets/auth_dialogs.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _tab = 0; // 0: Dashboard/Fleet, 1: Drivers, 2: AI & Analytics
  final _searchCtrl = TextEditingController();
  Map<String, dynamic>? _sosAlert;

  static final _mockBuses = [
    {'id': '1', 'busCode': 'GUL-001', 'routeName': '17-avtobus', 'driverName': 'Aliyev Vali', 'speed': 45, 'occupancyPercent': 75, 'status': 'ok', 'latitude': 40.489, 'longitude': 68.776},
    {'id': '2', 'busCode': 'GUL-002', 'routeName': '5-avtobus', 'driverName': 'Karimov Jasur', 'speed': 0, 'occupancyPercent': 20, 'status': 'ok', 'latitude': 40.498, 'longitude': 68.790},
    {'id': '3', 'busCode': 'GUL-003', 'routeName': '8-avtobus', 'driverName': 'Nazarov Olim', 'speed': 28, 'occupancyPercent': 95, 'status': 'late', 'latitude': 40.482, 'longitude': 68.762},
    {'id': '4', 'busCode': 'GUL-004', 'routeName': '22-avtobus', 'driverName': 'Yusupov Said', 'speed': 12, 'occupancyPercent': 60, 'status': 'ok', 'latitude': 40.494, 'longitude': 68.770},
    {'id': '5', 'busCode': 'GUL-005', 'routeName': '3-avtobus', 'driverName': 'Toshmatov Anvar', 'speed': 38, 'occupancyPercent': 45, 'status': 'ok', 'latitude': 40.501, 'longitude': 68.780},
  ];

  @override
  void initState() {
    super.initState();
    // No automatic SOS on enter - only shows when driver triggers SOS
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _switchRole(String role) async {
    if (role == 'DRIVER') {
      showDriverLoginModal(context, ref);
      return;
    }
    await ref.read(storageServiceProvider).setUserRole(role);
    if (!mounted) return;
    context.go('/passenger');
  }

  Future<void> _logout() async {
    await ref.read(storageServiceProvider).clearAll();
    if (mounted) context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final liveBuses = ref.watch(liveBusesProvider);
    final sosState = ref.watch(sosAlertProvider);
    final buses = liveBuses.isNotEmpty ? liveBuses : _mockBuses;

    // SOS only shows when actively triggered by a driver
    final activeSosBus = _sosAlert ?? sosState;
    final isSocketLive = ref.watch(socketConnectedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSocketLive ? const Color(0xFF4ADE80) : Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Dispetcher Markazi'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              accountName: Text(storage.userName.isNotEmpty ? storage.userName : 'Dispetcher', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              accountEmail: const Text('Admin Panel v2.0'),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.dashboard_rounded, color: AppColors.primary, size: 36)),
            ),
            ListTile(
              leading: const Icon(Icons.directions_bus_rounded, color: AppColors.primary),
              title: const Text('Boshqaruv Paneli (Flot)'),
              selected: _tab == 0,
              onTap: () { setState(() => _tab = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.badge_rounded, color: AppColors.primary),
              title: const Text('Haydovchilar'),
              selected: _tab == 1,
              onTap: () { setState(() => _tab = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
              title: const Text("Yo'qolgan & Topilgan Buyumlar"),
              selected: _tab == 2,
              onTap: () { setState(() => _tab = 2); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              title: const Text("Tahlil & AI Tavsiyalar"),
              selected: _tab == 3,
              onTap: () { setState(() => _tab = 3); Navigator.pop(context); },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text('ROLNI ALMASHTIRISH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: AppColors.primary),
              title: const Text("Yo'lovchi rejimiga o'tish"),
              onTap: () => _switchRole('PASSENGER'),
            ),
            ListTile(
              leading: const Icon(Icons.drive_eta_rounded, color: AppColors.primary),
              title: const Text("Haydovchi rejimiga o'tish"),
              onTap: () {
                Navigator.pop(context);
                showDriverLoginModal(context, ref);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Chiqish', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_bus_outlined), selectedIcon: Icon(Icons.directions_bus_rounded, color: Colors.white), label: 'Flot'),
          NavigationDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge_rounded, color: Colors.white), label: 'Haydovchilar'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded, color: Colors.white), label: 'Buyumlar'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded, color: Colors.white), label: 'AI & Tahlil'),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: const Color(0xFFEFF6FF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'NAMOYISH REJIMI · Namunaviy ma\'lumotlar',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _tab == 0
                    ? _FleetTab(buses: buses)
                    : (_tab == 1
                        ? const _DriversTab()
                        : (_tab == 2 ? const _LostFoundTab() : const _AnalyticsTab())),

                // SOS Alert Pop-up Modal
                if (activeSosBus != null)
                  Positioned.fill(
                    child: Material(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 40),
                              ),
                              const SizedBox(height: 12),
                              const Text('🚨 SOS SIGNAL!', style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.error)),
                              const SizedBox(height: 4),
                              const Text('Favqulodda yordam talab qilinmoqda', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  children: [
                                    Text('Avtobus: ${activeSosBus['busCode']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                    Text('Haydovchi: ${activeSosBus['driverName'] ?? 'Aliyev Vali'}', style: const TextStyle(color: AppColors.textSecondary)),
                                    Text('Tezlik: ${activeSosBus['speed']} km/s', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        ref.read(sosAlertProvider.notifier).state = null;
                                        setState(() => _sosAlert = null);
                                      },
                                      child: const Text('Yopish'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final code = activeSosBus['busCode']?.toString() ?? 'GUL-001';
                                        ref.read(socketServiceProvider).resolveSos(code);
                                        ref.read(liveBusesProvider.notifier).resolveSos(code);
                                        ref.read(sosAlertProvider.notifier).state = null;
                                        setState(() => _sosAlert = null);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                      child: const Text('Hal qilindi'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetTab extends StatelessWidget {
  final List buses;
  const _FleetTab({required this.buses});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 4 KPI Stat Cards Grid (Matching Screenshots 1 & 3)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: const [
            _StatCard(title: "Faol yo'nalishlar", value: '5', subtext: 'Namunaviy', icon: Icons.alt_route_rounded, color: Color(0xFF2563EB)),
            _StatCard(title: 'Xizmatdagi avtobuslar', value: '48 / 56', subtext: 'Liniyada', icon: Icons.directions_bus_rounded, color: Color(0xFF2563EB)),
            _StatCard(title: 'Rejalashtirilgan', value: '1', subtext: 'Kutilmoqda', icon: Icons.pending_actions_rounded, color: Color(0xFFD97706)),
            _StatCard(title: '17-yo\'nalish bahosi', value: '4.6 / 5', subtext: 'Namuna', icon: Icons.star_rounded, color: Color(0xFF16A34A)),
          ],
        ),

        const SizedBox(height: 16),

        // Live Map Preview
        const Text('FLOT XARITASI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 180,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(AppConstants.gulistonLat, AppConstants.gulistonLng),
                initialZoom: 13,
              ),
              children: [
                TileLayer(urlTemplate: AppConstants.osmTileUrl),
                MarkerLayer(
                  markers: buses.map((b) {
                    final lat = (b['latitude'] ?? AppConstants.gulistonLat).toDouble();
                    final lng = (b['longitude'] ?? AppConstants.gulistonLng).toDouble();
                    final isSos = b['status'] == 'sos';
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 40, height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSos ? AppColors.error : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text('AVTOBUSLAR RO\'YXATI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
        const SizedBox(height: 8),

        ...buses.map((b) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: b['status'] == 'sos' ? AppColors.error : AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(b['busCode']?.toString().replaceAll('GUL-00', '') ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b['busCode'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text("${b['routeName']} · ${b['driverName'] ?? 'Haydovchi'}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              OccupancyBadge(pct: (b['occupancyPercent'] ?? 50).toDouble()),
            ],
          ),
        )),
      ],
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF01307A)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text("AI Qaror Qo'llab-quvvatlash ✨", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
              SizedBox(height: 12),
              _AiRecCard(title: "Zaxira avtobus chiqaring", desc: "17-yo'nalish: Markaziy Bozor bekatida 40+ yo'lovchi kutmoqda.", color: AppColors.error),
              SizedBox(height: 8),
              _AiRecCard(title: "Kechikish xavfi", desc: "GUL-003 avtobusi 8 daqiqa kechikmoqda.", color: AppColors.warning),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text('SOATBAY YO\'LOVCHILAR DINAMIKASI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
        const SizedBox(height: 10),

        // Passenger Hourly Chart using fl_chart
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 6000,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      const hours = ['07:00', '09:00', '12:00', '16:00', '18:00'];
                      final idx = v.toInt();
                      if (idx >= 0 && idx < hours.length) {
                        return Text(hours[idx], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 2800, color: AppColors.primary, width: 20, borderRadius: BorderRadius.circular(6))]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 3800, color: AppColors.primary, width: 20, borderRadius: BorderRadius.circular(6))]),
                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 3200, color: AppColors.primary, width: 20, borderRadius: BorderRadius.circular(6))]),
                BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 5200, color: AppColors.accent, width: 20, borderRadius: BorderRadius.circular(6))]),
                BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 6000, color: AppColors.error, width: 20, borderRadius: BorderRadius.circular(6))]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final String? subtext;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, this.subtext, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, maxLines: 1, style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w900, color: color)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(title, maxLines: 1, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AiRecCard extends StatelessWidget {
  final String title, desc;
  final Color color;
  const _AiRecCard({required this.title, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
    child: Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
              Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DriversTab extends ConsumerStatefulWidget {
  const _DriversTab();

  @override
  ConsumerState<_DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends ConsumerState<_DriversTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddDriverDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+998 ');
    final busCtrl = TextEditingController(text: 'GUL-001 (17-avtobus)');
    final loginCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool generated = false;
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yangi Haydovchi Qo\'shish',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Ma\'lumotlarni kiriting va login/parol yarating',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (errorMsg != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(errorMsg!, style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),

                  const Text('Haydovchi ismi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Masalan: Aliyev Vali',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Telefon raqami', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+998 90 123 45 67',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Biriktiriladigan avtobus', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: busCtrl.text,
                    items: const [
                      DropdownMenuItem(value: 'GUL-001 (17-avtobus)', child: Text('GUL-001 (17-avtobus)')),
                      DropdownMenuItem(value: 'GUL-002 (5-avtobus)', child: Text('GUL-002 (5-avtobus)')),
                      DropdownMenuItem(value: 'GUL-003 (8-avtobus)', child: Text('GUL-003 (8-avtobus)')),
                      DropdownMenuItem(value: 'GUL-004 (22-avtobus)', child: Text('GUL-004 (22-avtobus)')),
                      DropdownMenuItem(value: 'GUL-005 (3-avtobus)', child: Text('GUL-005 (3-avtobus)')),
                    ],
                    onChanged: (val) {
                      if (val != null) busCtrl.text = val;
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.directions_bus_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Generate Login & Password Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final drivers = ref.read(driversProvider);
                        final nextNum = drivers.length + 1;
                        setState(() {
                          loginCtrl.text = 'haydovchi$nextNum';
                          passCtrl.text = 'pass$nextNum';
                          generated = true;
                          errorMsg = null;
                        });
                      },
                      icon: const Icon(Icons.badge_rounded, color: Color(0xFF0D9488), size: 20),
                      label: const Text(
                        '🆔 Navbatdagi login va parol yaratish',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0D9488), fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFCCFBF1),
                        side: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  if (generated) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Yaratilgan Kirish Ma\'lumotlari:',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Login (Tartib raqami bo\'yicha):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  Text(
                                    loginCtrl.text,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                                tooltip: "Logindan nusxa olish",
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: loginCtrl.text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Login nusxalandi!"), duration: Duration(seconds: 1)),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Parol (pass + son):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  Text(
                                    passCtrl.text,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                                tooltip: "Paroldan nusxa olish",
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: passCtrl.text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Parol nusxalandi!"), duration: Duration(seconds: 1)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();
                              final login = loginCtrl.text.trim();
                              final pass = passCtrl.text.trim();

                              if (name.isEmpty) {
                                setState(() => errorMsg = "Haydovchi ismini kiriting");
                                return;
                              }
                              if (login.isEmpty || pass.isEmpty) {
                                setState(() => errorMsg = "Oldin 'Login va parol yaratish' tugmasini bosing");
                                return;
                              }

                              setState(() => saving = true);
                              try {
                                final parts = busCtrl.text.split(' ');
                                final busCode = parts.isNotEmpty ? parts[0] : 'GUL-001';
                                final routeName = busCtrl.text;

                                final driverData = {
                                  'id': 'driver_${DateTime.now().millisecondsSinceEpoch}',
                                  'fullName': name,
                                  'phoneNumber': phone,
                                  'username': login,
                                  'busCode': busCode,
                                  'routeName': routeName,
                                  'isOnline': true,
                                };

                                ref.read(driversProvider.notifier).addDriver(driverData);

                                try {
                                  await ref.read(apiServiceProvider).addDriver(
                                    fullName: name,
                                    phoneNumber: phone,
                                    username: login,
                                    password: pass,
                                    busCode: busCode,
                                    routeName: routeName,
                                  );
                                } catch (_) {}

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Haydovchi qo'shildi! Login: $login | Parol: $pass"),
                                      backgroundColor: const Color(0xFF059669),
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => errorMsg = "Xatolik yuz berdi: $e");
                              } finally {
                                setState(() => saving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(driversProvider);
    final query = _searchCtrl.text.toLowerCase().trim();

    final filtered = drivers.where((d) {
      if (query.isEmpty) return true;
      final name = (d['fullName'] ?? '').toString().toLowerCase();
      final user = (d['username'] ?? '').toString().toLowerCase();
      final phone = (d['phoneNumber'] ?? '').toString().toLowerCase();
      return name.contains(query) || user.contains(query) || phone.contains(query);
    }).toList();

    final onlineCount = drivers.where((d) => d['isOnline'] == true).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top Header card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haydovchilar Boshqaruvi',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Real-time haydovchilar hisobi va hisob ma\'lumotlari',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDriverDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Haydovchi qo\'shish', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _DriverStatBadge(title: 'Jami haydovchilar', value: '${drivers.length} nafar', icon: Icons.people_alt_rounded, color: const Color(0xFF38BDF8)),
                  const SizedBox(width: 10),
                  _DriverStatBadge(title: 'Faol / Onlayn', value: '$onlineCount nafar', icon: Icons.check_circle_rounded, color: const Color(0xFF4ADE80)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Search Bar
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Haydovchi ismi, logini yoki telefon raqami...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('HAYDOVCHILAR RO\'YXATI (${filtered.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
            Text('Real-time sinxronizatsiya faol', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
          ],
        ),

        const SizedBox(height: 10),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('Haydovchilar topilmadi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                const Text('Yangi haydovchi qo\'shish uchun yuqoridagi tugmani bosing', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          )
        else
          ...filtered.map((driver) {
            final id = driver['id']?.toString() ?? driver['_id']?.toString() ?? '';
            final username = driver['username']?.toString() ?? 'haydovchi1';
            final busCode = driver['busCode']?.toString() ?? 'GUL-001';
            final routeName = driver['routeName']?.toString() ?? '17-avtobus';
            final isOnline = driver['isOnline'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: const Icon(Icons.drive_eta_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver['fullName'] ?? 'Noma\'lum Haydovchi',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              driver['phoneNumber']?.isNotEmpty == true ? driver['phoneNumber'] : 'Telefon kiritilmagan',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          busCode,
                          style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        tooltip: "O'chirish",
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Haydovchini o\'chirish'),
                              content: Text("${driver['fullName']} haydovchisini ro'yxatdan o'chirishni tasdiqlaysizmi?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Bekor qilish')),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(driversProvider.notifier).removeDriver(id);
                                    ref.read(apiServiceProvider).deleteDriver(id);
                                    Navigator.pop(dCtx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Haydovchi o'chirildi")),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                  child: const Text('O\'chirish'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Credentials Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        // Login
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.badge_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Login', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    SelectableText(
                                      username,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                                tooltip: "Logindan nusxa olish",
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: username));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("$username nusxalandi!"), duration: const Duration(seconds: 1)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        Container(width: 1, height: 30, color: const Color(0xFFCBD5E1), margin: const EdgeInsets.symmetric(horizontal: 10)),

                        // Route & Status (Secure)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(isOnline ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                  size: 16, color: isOnline ? const Color(0xFF0D9488) : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(routeName, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    Text(
                                      isOnline ? 'Faol / Liniyada' : 'Kutilmoqda',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: isOnline ? const Color(0xFF0F766E) : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _DriverStatBadge extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _DriverStatBadge({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14)),
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LostFoundTab extends ConsumerStatefulWidget {
  const _LostFoundTab();

  @override
  ConsumerState<_LostFoundTab> createState() => _LostFoundTabState();
}

class _LostFoundTabState extends ConsumerState<_LostFoundTab> {
  String _filter = 'all'; // 'all', 'lost', 'found'
  final _searchCtrl = TextEditingController();

  void _showAddFoundItemDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+998 67 225-01-23');
    final nameCtrl = TextEditingController(text: 'Dispetcherlik');
    String selectedRoute = '17-avtobus';

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Yangi Topilma Qo\'shish', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, fontSize: 18)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Topilgan buyum nomi *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'Masalan: Moviy sumka, Kalitlar...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Qaysi avtobusda topilgan?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: ['17-avtobus', '5-avtobus', '8-avtobus', '22-avtobus'].map((r) {
                    final sel = selectedRoute == r;
                    return ChoiceChip(
                      label: Text(r, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.black87)),
                      selected: sel,
                      onSelected: (_) => setModalState(() => selectedRoute = r),
                      selectedColor: const Color(0xFF10B981),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Tavsif', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Holati, saqlanayotgan joy...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Bekor qilish')),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final item = {
                  'id': 'lost_${DateTime.now().millisecondsSinceEpoch}',
                  'title': title,
                  'description': descCtrl.text.trim(),
                  'busRoute': selectedRoute,
                  'passengerName': nameCtrl.text.trim(),
                  'passengerPhone': phoneCtrl.text.trim(),
                  'status': 'topildi',
                  'createdAt': DateTime.now().toIso8601String(),
                  'foundAt': DateTime.now().toIso8601String(),
                };

                ref.read(lostItemsProvider.notifier).addReport(item);
                ref.read(apiServiceProvider).reportLostItem(
                  title: title,
                  description: descCtrl.text.trim(),
                  busRoute: selectedRoute,
                  passengerName: item['passengerName'] as String,
                  passengerPhone: item['passengerPhone'] as String,
                );

                Navigator.pop(dCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Yangi topilma ro'yxatga qo'shildi"), backgroundColor: Color(0xFF10B981)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Qo\'shish'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(lostItemsProvider);
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = allItems.where((item) {
      if (_filter == 'lost' && item['status'] != 'yoqolgan') return false;
      if (_filter == 'found' && item['status'] != 'topildi') return false;
      if (query.isNotEmpty) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final route = (item['busRoute'] ?? '').toString().toLowerCase();
        final name = (item['passengerName'] ?? '').toString().toLowerCase();
        final phone = (item['passengerPhone'] ?? '').toString().toLowerCase();
        return title.contains(query) || route.contains(query) || name.contains(query) || phone.contains(query);
      }
      return true;
    }).toList();

    final lostCount = allItems.where((i) => i['status'] == 'yoqolgan').length;
    final foundCount = allItems.where((i) => i['status'] == 'topildi').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Topilmalar & Yo\'qolgan Buyumlar',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Yo\'lovchilar buyumlari hisobi va real-time SMS bildirishnoma',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFoundItemDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Topilma qo\'shish', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _DriverStatBadge(
                    title: 'Jami buyumlar',
                    value: '${allItems.length} ta',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 8),
                  _DriverStatBadge(
                    title: 'Qidirilmoqda',
                    value: '$lostCount ta',
                    icon: Icons.search_rounded,
                    color: const Color(0xFFF87171),
                  ),
                  const SizedBox(width: 8),
                  _DriverStatBadge(
                    title: 'Topildi (SMS bordi)',
                    value: '$foundCount ta',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF4ADE80),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Search Bar
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buyum, avtobus yoki telefon raqam bo\'yicha qidirish...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),

        const SizedBox(height: 12),

        // Filter Pills
        Row(
          children: [
            _filterChip('all', 'Barchasi (${allItems.length})'),
            const SizedBox(width: 8),
            _filterChip('lost', '🔴 Qidirilmoqda ($lostCount)'),
            const SizedBox(width: 8),
            _filterChip('found', '🟢 Topildi ($foundCount)'),
          ],
        ),

        const SizedBox(height: 16),

        // Items List
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary),
                SizedBox(height: 12),
                Text('Ushbu filtr bo\'yicha hech qanday buyum topilmadi', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        else
          ...filtered.map((item) {
            final isLost = item['status'] == 'yoqolgan';
            final title = item['title'] ?? "Noma'lum buyum";
            final route = item['busRoute'] ?? '17-avtobus';
            final passenger = item['passengerName'] ?? "Yo'lovchi";
            final phone = item['passengerPhone'] ?? '+998 ...';
            final desc = item['description'] ?? '';
            final id = item['id']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLost ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0),
                  width: 1.5,
                ),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isLost ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isLost ? Icons.search_rounded : Icons.check_circle_rounded,
                          color: isLost ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Outfit'),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.directions_bus_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(route, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isLost ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isLost ? '🔴 QIDIRILMOQDA' : '🟢 TOPILDI',
                          style: TextStyle(
                            color: isLost ? const Color(0xFFB91C1C) : const Color(0xFF047857),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        tooltip: "O'chirish",
                        onPressed: () {
                          ref.read(lostItemsProvider.notifier).removeItem(id);
                          ref.read(apiServiceProvider).deleteLostItem(id);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Info row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 15, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text("Yo'lovchi: $passenger", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            const Icon(Icons.phone_rounded, size: 15, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ],
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text("Tavsif: $desc", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action Button: Topildi deb belgilash
                  if (isLost)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Mark as found & send SMS to passenger real-time
                          ref.read(lostItemsProvider.notifier).markFound(id);
                          ref.read(apiServiceProvider).markLostItemFound(id);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("✅ '$title' topildi deb belgilandi va yo'lovchiga ovozli SMS yuborildi!"),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text(
                          "TOPILDI DEB BELGILASH (YO'LOVCHIGA SMS BORADI)",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mark_email_read_rounded, color: Color(0xFF047857), size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Yo'lovchiga topilgani haqida SMS xabarnoma yuborilgan",
                            style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _filterChip(String key, String label) {
    final sel = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _filter = key),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: sel ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}


