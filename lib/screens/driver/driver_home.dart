import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/api_service.dart';
import '../../core/socket_service.dart';
import '../../core/storage_service.dart';

class DriverHome extends ConsumerStatefulWidget {
  const DriverHome({super.key});

  @override
  ConsumerState<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends ConsumerState<DriverHome> with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  Timer? _telemetryTimer;
  late AnimationController _animController;

  int _stopIdx = 1;
  bool _sosTriggered = false;
  final bool _tripActive = true;
  bool _trafficSent = false;
  final int _fuelLevel = 72;
  String _announceText = '';
  String _copilotAdvice = "Salom! Men sizning 15 yillik tajribaga ega AI-shturmaningizman. Harakat barqaror.";

  double _currentLat = 40.4955;
  double _currentLng = 68.7850;
  int _currentSpeed = 38;

  final _msgCtrl = TextEditingController();
  bool _showChat = false;

  static const _stops = [
    {'name': 'Chilonzor buyum bozori', 'eta': '8 daq', 'ai': 18, 'occ': 30, 'lat': 40.4915, 'lng': 68.7801},
    {'name': 'Bunyodkor bekati', 'eta': '2 daq', 'ai': 22, 'occ': 72, 'lat': 40.4955, 'lng': 68.7850},
    {'name': 'Muqimiy bekati', 'eta': '5 daq', 'ai': 14, 'occ': 68, 'lat': 40.4940, 'lng': 68.7820},
    {'name': 'Chilonzor metro', 'eta': '8 daq', 'ai': 35, 'occ': 60, 'lat': 40.4975, 'lng': 68.7880},
    {'name': 'Novza bekati', 'eta': '12 daq', 'ai': 16, 'occ': 45, 'lat': 40.4990, 'lng': 68.7905},
    {'name': 'Chorsu bozori', 'eta': '24 daq', 'ai': 50, 'occ': 40, 'lat': 40.4880, 'lng': 68.7750},
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    _startTelemetryStream();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  void _initTts() async {
    await _tts.setLanguage("uz-UZ");
    await _tts.setSpeechRate(0.9);
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _tts.stop();
    _msgCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _startTelemetryStream() {
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_tripActive) return;
      final target = _stops[_stopIdx];
      final targetLat = (target['lat'] as num).toDouble();
      final targetLng = (target['lng'] as num).toDouble();

      _currentLat += (targetLat - _currentLat) * 0.15;
      _currentLng += (targetLng - _currentLng) * 0.15;

      _currentSpeed = _tripActive ? 32 : 0;

      ref.read(socketServiceProvider).updateBusLocation(
        busCode: 'GUL-001',
        latitude: double.parse(_currentLat.toStringAsFixed(6)),
        longitude: double.parse(_currentLng.toStringAsFixed(6)),
        speed: _currentSpeed,
        occupancyPercent: (target['occ'] as num).toInt(),
        status: _sosTriggered ? 'sos' : 'ok',
      );
    });
  }

  Future<void> _speak(String text) async {
    setState(() => _announceText = text);
    await _tts.speak(text);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _announceText = '');
    });
  }

  Future<void> _handleSOS() async {
    setState(() => _sosTriggered = true);
    await _speak("Favqulodda SOS signali dispetcherlik markaziga yuborildi!");
    final sosPayload = {
      'busCode': 'GUL-001',
      'routeName': '17-avtobus',
      'driverName': 'Aliyev Vali',
      'speed': 45,
      'status': 'sos',
    };
    ref.read(liveBusesProvider.notifier).triggerSos('GUL-001');
    ref.read(sosAlertProvider.notifier).state = sosPayload;
    ref.read(socketServiceProvider).triggerSos(sosPayload);
    try {
      await ref.read(apiServiceProvider).triggerSOS(busId: 'GUL-001', description: 'Favqulodda SOS signal!');
    } catch (_) {}
  }

  void _handleAnnounce() {
    final current = _stops[_stopIdx];
    _speak("Keyingi bekat: ${current['name']}. Kelish vaqti taxminan ${current['eta']}.");
  }

  void _handleNextStop() {
    if (_stopIdx < _stops.length - 1) {
      setState(() {
        _stopIdx++;
        final next = _stops[_stopIdx];
        _currentLat = (next['lat'] as num).toDouble();
        _currentLng = (next['lng'] as num).toDouble();
      });
      final next = _stops[_stopIdx];
      _speak("Keyingi bekat: ${next['name']}. Kutilayotgan yo'lovchilar soni: ${next['ai']} kishi.");
      ref.read(socketServiceProvider).updateBusLocation(
        busCode: 'GUL-001',
        latitude: _currentLat,
        longitude: _currentLng,
        speed: _currentSpeed,
        occupancyPercent: (next['occ'] as num).toInt(),
        status: _sosTriggered ? 'sos' : 'ok',
      );
    } else {
      _speak("Yo'nalishdagi oxirgi bekatga yetib kelindi.");
    }
  }

  void _handleCopilotVoiceAdvice() {
    final current = _stops[_stopIdx];
    final tips = [
      "Hamkasb, 15 yillik tajribaga tayanib: ${current['name']} bekatiga yaqinlashganda oraliq masofani saqlang!",
      "AI-Shturman: Jadval bo'yicha harakatlanyapmiz. Keyingi bekat — ${current['name']}.",
      "Salon to'laligi me'yorda. Yo'lovchilar xavfsizligi uchun ravon to'xtang.",
      "Maslahat: Gazni bir maromda ushlang, hozirgi yoqilg'i zahirasi: $_fuelLevel%."
    ];
    final chosen = (tips..shuffle()).first;
    setState(() => _copilotAdvice = chosen);
    _speak(chosen);
  }

  void _handleTrafficReport() {
    setState(() => _trafficSent = true);
    ref.read(dispatcherChatProvider.notifier).sendMessage(
      text: "Chilonzor ko'chasida tirbandlik, tezlikni pasaytiryapman.",
      from: 'driver',
      senderName: 'Aliyev Vali (GUL-001)',
      busCode: 'GUL-001',
    );
    ref.read(socketServiceProvider).reportDelay({
      'busCode': 'GUL-001',
      'routeName': '17-avtobus',
      'delayMinutes': '5-10',
      'message': "Chilonzor ko'chasida tirbandlik tufayli 17-avtobus 5-10 daqiqaga kechikishi mumkin.",
    });
    _speak("Tirbandlik xabari dispetcher va yo'lovchilarga yuborildi.");
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _trafficSent = false);
    });
  }

  void _sendMsg() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(dispatcherChatProvider.notifier).sendMessage(
      text: text,
      from: 'driver',
      senderName: 'Aliyev Vali (GUL-001)',
      busCode: 'GUL-001',
    );
    _msgCtrl.clear();
  }

  void _switchRole(String role) async {
    await ref.read(storageServiceProvider).setUserRole(role);
    if (!mounted) return;
    if (role == 'ADMIN') {
      context.go('/admin');
    } else {
      context.go('/passenger');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(socketConnectedProvider);
    final current = _stops[_stopIdx];
    final occ = (current['occ'] as num).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. Top Notice Bar ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF)),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "NAMOYISH REJIMI · Haydovchi boshqaruv paneli",
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ─── 2. Header: SmartBus Haydovchi + Status & Chat Button ───────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmartBus Haydovchi',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Toshkent · 17-avtobus (GUL-001)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Live badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOnline ? 'Onlayn' : 'Oflayn',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Chat Button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            color: Colors.white,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF1D4ED8), size: 18),
                            onPressed: () => setState(() => _showChat = !_showChat),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role switch button (to Passenger)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            color: Colors.white,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF64748B), size: 20),
                            onPressed: () => _switchRole('PASSENGER'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ─── 3. Schematic Live Map Container ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _DriverSchematicMapPainter(
                          animProgress: _animController.value,
                          currentStopIdx: _stopIdx,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 12,
                              bottom: 10,
                              child: Row(
                                children: [
                                  Container(width: 20, height: 2, color: const Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '100 m · Jonli telemetriya',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ─── 4. Telemetry Card: Speed, Fuel, Occupancy (Image 2 style) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: 17-avtobus
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                '17',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Outfit',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '17-avtobus (GUL-001)',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Chilonzor → Chorsu',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: occ >= 70 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              occ >= 70 ? 'Gavjum · $occ%' : "Me'yorda · $occ%",
                              style: TextStyle(
                                color: occ >= 70 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 3 Stat Boxes: Tezlik, Yoqilg'i, Bandlik
                      Row(
                        children: [
                          _buildStatBox(label: 'Tezlik', value: '$_currentSpeed km/s', color: const Color(0xFF1D4ED8)),
                          const SizedBox(width: 8),
                          _buildStatBox(label: "Yoqilg'i", value: '$_fuelLevel%', color: const Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          _buildStatBox(label: 'Bandlik', value: '$occ%', color: const Color(0xFFD97706)),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 3-Segment Progress Bar (Green, Amber, Red)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(3)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(color: const Color(0xFFEAB308), borderRadius: BorderRadius.circular(3)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(3)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ─── 5. Next Stop Progression Card ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on_outlined, color: Color(0xFF1D4ED8), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'KEYINGI BEKAT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  current['name'].toString(),
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                current['eta'].toString(),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                              Text(
                                '${current['ai']} yo\'lovchi',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // AI-Shturman advice pill
                      GestureDetector(
                        onTap: _handleCopilotVoiceAdvice,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.psychology_rounded, color: Color(0xFF1D4ED8), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _copilotAdvice,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1D4ED8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_announceText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('📢 $_announceText', style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                      ],

                      const SizedBox(height: 16),

                      // Next Stop Confirmation Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleNextStop,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Keyingi bekatga yetib keldik",
                                style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ─── 6. Driver Quick Action Buttons ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleAnnounce,
                        icon: const Icon(Icons.volume_up_rounded, size: 16, color: Color(0xFF1D4ED8)),
                        label: const Text("Ovozli e'lon", style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          backgroundColor: const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleTrafficReport,
                        icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                        label: Text(_trafficSent ? 'Yuborildi' : 'Tirbandlik', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w700, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFDE68A)),
                          backgroundColor: const Color(0xFFFFFBEB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleSOS,
                        icon: const Icon(Icons.sos_rounded, size: 18, color: Colors.white),
                        label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ─── 7. Dispetcher Chat Drawer / Bottom Sheet ────────────────────
              if (_showChat)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Dispetcherlik bilan jonli muloqot',
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _showChat = false),
                              child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msgCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Dispetcherga xabar yozing...',
                                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _sendMsg,
                              icon: const Icon(Icons.send_rounded, color: Color(0xFF1D4ED8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ─── 8. Disclaimer at bottom ───────────────────────────────────
              const Center(
                child: Text(
                  'Telemetriya va yo\'lovchilar soni real vaqtda dispetcher serveriga uzatilmoqda.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Custom schematic painter for Driver View
class _DriverSchematicMapPainter extends CustomPainter {
  final double animProgress;
  final int currentStopIdx;

  _DriverSchematicMapPainter({required this.animProgress, required this.currentStopIdx});

  @override
  void paint(Canvas canvas, Size size) {
    final greyPaint = Paint()..color = const Color(0xFFE2E8F0);
    final greenPaint = Paint()..color = const Color(0xFFDCFCE7);

    // Blocks
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 14, 56, 36), const Radius.circular(10)), greyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(110, 14, 68, 36), const Radius.circular(10)), greyPaint);
    _drawText(canvas, 'Muqimiy', const Offset(144, 24), const Color(0xFF334155), 10, FontWeight.w700);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(200, 14, 88, 36), const Radius.circular(10)), greyPaint);
    _drawText(canvas, 'Chilonzor metro', const Offset(244, 24), const Color(0xFF334155), 10, FontWeight.w700);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(200, 110, 72, 44), const Radius.circular(12)), greenPaint);
    _drawText(canvas, 'Chilonzor', const Offset(236, 126), const Color(0xFF166534), 10, FontWeight.w800);

    // Street text
    _drawText(canvas, "Chilonzor ko'chasi", const Offset(150, 72), const Color(0xFF64748B), 10, FontWeight.w600);

    // Blue Route
    final routePaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(24, 114);
    path.lineTo(92, 114);
    path.lineTo(92, 46);
    path.lineTo(240, 46);

    canvas.drawPath(path, routePaint);

    // Stop nodes
    _drawStopNode(canvas, const Offset(92, 46));
    _drawStopNode(canvas, const Offset(150, 46));
    _drawStopNode(canvas, const Offset(220, 46));

    // Animated Bus badge [🚌 17]
    double t = (animProgress + 0.2) % 1.0;
    Offset busPos;
    if (t < 0.23) {
      double p = t / 0.23;
      busPos = Offset(24 + (92 - 24) * p, 114);
    } else if (t < 0.50) {
      double p = (t - 0.23) / 0.27;
      busPos = Offset(92, 114 - (114 - 46) * p);
    } else {
      double p = (t - 0.50) / 0.50;
      busPos = Offset(92 + (240 - 92) * p, 46);
    }

    // Badge
    const w = 40.0;
    const h = 24.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(busPos.dx, busPos.dy - 14), width: w, height: h),
      const Radius.circular(7),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1D4ED8));

    final tp = TextPainter(
      text: const TextSpan(
        children: [
          TextSpan(text: '🚌 ', style: TextStyle(fontSize: 9)),
          TextSpan(text: '17', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(busPos.dx - tp.width / 2, busPos.dy - 14 - tp.height / 2));
  }

  void _drawStopNode(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 4, Paint()..color = Colors.white);
    canvas.drawCircle(
      pos,
      4,
      Paint()
        ..color = const Color(0xFF1D4ED8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color, double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight, fontFamily: 'Outfit'),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _DriverSchematicMapPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress || oldDelegate.currentStopIdx != currentStopIdx;
  }
}
