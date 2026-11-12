import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_service.dart';
import '../../../core/socket_service.dart';
import '../../../core/storage_service.dart';
import '../../../core/guliston_route_data.dart';
import '../../../widgets/guliston_route_map_widget.dart';
import '../passenger_shell.dart';

final _busesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getBuses();
});

class PassengerHomeTab extends ConsumerStatefulWidget {
  const PassengerHomeTab({super.key});

  @override
  ConsumerState<PassengerHomeTab> createState() => _PassengerHomeTabState();
}

class _PassengerHomeTabState extends ConsumerState<PassengerHomeTab> {
  final _searchCtrl = TextEditingController();

  // Selected bus state - 1-avtobus (Guliston 1-yo'nalish)
  String _selectedRoute = '1';
  String _selectedRouteName = 'Yangi bozor ↔ GulDU';
  String _currentStop = 'Yangi bozor1';
  String _nextStop = 'Dehqon bozori';
  int _etaMinutes = 2;
  int _occupancyPercent = 42;
  String _currentStreet = "Yangi bozor ko'chasi";

  double _liveBusLat = 40.475401;
  double _liveBusLng = 68.780794;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectBus(String route, String direction, String current, String next, int eta, int occ, String street) {
    setState(() {
      _selectedRoute = route;
      _selectedRouteName = direction;
      _currentStop = current;
      _nextStop = next;
      _etaMinutes = eta;
      _occupancyPercent = occ;
      _currentStreet = street;
    });
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1D4ED8), size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Bildirishnomalar',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.directions_bus_rounded, color: Color(0xFF1D4ED8), size: 20)),
              title: Text('17-avtobus yaqinlashmoqda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text('Muqimiy bekatiga kelishiga 5 daqiqa qoldi.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              trailing: Text('18:20', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20)),
              title: Text('Tirbandlik ogohlantirishi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text("Chilonzor ko'chasida oraliq masofa 3 daqiqaga uzaytirildi.", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              trailing: Text('18:10', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ),
          ],
        ),
      ),
    );
  }

  void _showStopsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _selectedRoute,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_selectedRoute-avtobus yo\'nalishi',
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          _selectedRouteName,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Yo\'nalish bekatlari va kelish vaqtlari',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              if (_selectedRoute == '1' || _selectedRoute == '2') ...[
                ...GulistonRoutes.getStops(_selectedRoute, isForward: true).map((stop) {
                  final isCurrent = stop.name == _currentStop;
                  final isNext = stop.name == _nextStop;
                  final etaMin = GulistonRoutes.calculateEta(
                    _selectedRoute,
                    busLat: _liveBusLat,
                    busLng: _liveBusLng,
                    targetStopIndex: stop.index,
                    speedKmH: 11.0,
                  );
                  return _buildStopTimelineItem(
                    stop.name,
                    isCurrent
                        ? 'Hozirda shu bekatda'
                        : (isNext ? '$_etaMinutes daqiqa (Keyingi bekat)' : '~$etaMin daqiqa'),
                    isCurrent: isCurrent,
                    isNext: isNext,
                  );
                }),
              ] else ...[
                _buildStopTimelineItem('Chilonzor buyum bozori', '08:15', isPassed: true),
                _buildStopTimelineItem('Chilonzor metro', '08:21', isPassed: true),
                _buildStopTimelineItem(_currentStop, 'Hozirda shu yerda', isCurrent: true),
                _buildStopTimelineItem(_nextStop, '$_etaMinutes daqiqa (Keyingi bekat)', isNext: true),
                _buildStopTimelineItem('Novza bekati', '12 daqiqa'),
                _buildStopTimelineItem('Bunyodkor stadioni', '16 daqiqa'),
                _buildStopTimelineItem('Xalqlar do\'stligi', '20 daqiqa'),
                _buildStopTimelineItem('Chorsu bozori', '28 daqiqa'),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReportDelayModal(context);
                      },
                      icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                      label: const Text('Kechikish xabari', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w700, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFDE68A)),
                        backgroundColor: const Color(0xFFFFFBEB),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReportLostItemModal(context);
                      },
                      icon: const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF1D4ED8)),
                      label: const Text("Yo'qolgan buyum", style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        backgroundColor: const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopTimelineItem(String title, String subtitle, {bool isPassed = false, bool isCurrent = false, bool isNext = false}) {
    Color dotColor = const Color(0xFFCBD5E1);
    Color textColor = const Color(0xFF1E293B);
    Color subColor = const Color(0xFF64748B);

    if (isCurrent) {
      dotColor = const Color(0xFF1D4ED8);
      textColor = const Color(0xFF1D4ED8);
      subColor = const Color(0xFF1D4ED8);
    } else if (isNext) {
      dotColor = const Color(0xFF2563EB);
      textColor = const Color(0xFF0F172A);
      subColor = const Color(0xFF2563EB);
    } else if (isPassed) {
      dotColor = const Color(0xFF94A3B8);
      textColor = const Color(0xFF94A3B8);
      subColor = const Color(0xFFCBD5E1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isCurrent || isNext ? dotColor : Colors.white,
                  border: Border.all(color: dotColor, width: 3),
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 28, color: const Color(0xFFE2E8F0)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: isCurrent || isNext ? FontWeight.w800 : FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, fontWeight: isCurrent || isNext ? FontWeight.w700 : FontWeight.w500, color: subColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDelayModal(BuildContext context) {
    String selectedRoute = '$_selectedRoute-avtobus';
    String delayTime = '5-10 daqiqa';
    final reasonCtrl = TextEditingController(
      text: "Mustaqillik ko'chasidagi ta'mirlash tufayli $selectedRoute $delayTime kechikishi mumkin.",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kechikish haqida xabar',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Boshqa yo\'lovchilarga ogohlantirish yuborish',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Yo\'nalishni tanlang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['17-avtobus', '23-avtobus', '80-avtobus', '51-avtobus'].map((r) {
                  final sel = selectedRoute == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: sel,
                    onSelected: (_) => setModalState(() {
                      selectedRoute = r;
                      reasonCtrl.text = "Tirbandlik tufayli $r $delayTime kechikishi mumkin.";
                    }),
                    selectedColor: const Color(0xFF1D4ED8),
                    labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text('Kechikish vaqti', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['5-10 daqiqa', '10-15 daqiqa', '20+ daqiqa'].map((t) {
                  final sel = delayTime == t;
                  return ChoiceChip(
                    label: Text(t),
                    selected: sel,
                    onSelected: (_) => setModalState(() {
                      delayTime = t;
                      reasonCtrl.text = "Tirbandlik tufayli $selectedRoute $delayTime kechikishi mumkin.";
                    }),
                    selectedColor: const Color(0xFFD97706),
                    labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text('Ogohlantirish matni', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ogohlantirish matni...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final msg = reasonCtrl.text.trim().isNotEmpty
                        ? reasonCtrl.text.trim()
                        : "Tirbandlik tufayli $selectedRoute $delayTime kechikishi mumkin.";

                    final alertData = {
                      'routeName': selectedRoute,
                      'busCode': 'TAS-017',
                      'delayMinutes': delayTime,
                      'message': "⚠️ Ogohlantirish: $msg",
                    };

                    ref.read(delayAlertProvider.notifier).state = alertData;
                    ref.read(socketServiceProvider).reportDelay(alertData);
                    ref.read(apiServiceProvider).reportDelay(
                      routeName: selectedRoute,
                      delayMinutes: delayTime,
                      message: "⚠️ Ogohlantirish: $msg",
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Kechikish ogohlantirishi tizimga yuborildi!"),
                        backgroundColor: Color(0xFFD97706),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Kechikish xabarini yuborish', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportLostItemModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(
      text: ref.read(storageServiceProvider).userPhone.isNotEmpty
          ? ref.read(storageServiceProvider).userPhone
          : '+998 90 ',
    );
    final nameCtrl = TextEditingController(
      text: ref.read(storageServiceProvider).userName.isNotEmpty
          ? ref.read(storageServiceProvider).userName
          : "Yo'lovchi",
    );
    String selectedRoute = '$_selectedRoute-avtobus';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF1D4ED8), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Yo'qolgan Buyum Haqida Xabar", style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w900)),
                          Text("Dispetcherlik bo'limiga ma'lumot yuborish", style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Buyum nomi *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'Masalan: Qora charm hamyon, Sumka, Kalit...',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Qaysi avtobusda qolib ketgan?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['17-avtobus', '23-avtobus', '80-avtobus', '51-avtobus'].map((r) {
                    final sel = selectedRoute == r;
                    return ChoiceChip(
                      label: Text(r),
                      selected: sel,
                      onSelected: (_) => setModalState(() => selectedRoute = r),
                      selectedColor: const Color(0xFF1D4ED8),
                      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ismingiz', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Ism',
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Telefon raqamingiz *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: phoneCtrl,
                            decoration: InputDecoration(
                              hintText: '+998 ...',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Qo\'shimcha tavsif', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Qayerda va qachon yo\'qolgani, ichidagi buyumlar...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Iltimos, buyum nomini kiriting'), backgroundColor: Color(0xFFDC2626)),
                        );
                        return;
                      }

                      final itemData = {
                        'id': 'lost_${DateTime.now().millisecondsSinceEpoch}',
                        'title': title,
                        'description': descCtrl.text.trim(),
                        'busRoute': selectedRoute,
                        'passengerName': nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : "Yo'lovchi",
                        'passengerPhone': phoneCtrl.text.trim(),
                        'status': 'yoqolgan',
                        'createdAt': DateTime.now().toIso8601String(),
                        'foundAt': null,
                      };

                      ref.read(lostItemsProvider.notifier).addReport(itemData);
                      ref.read(apiServiceProvider).reportLostItem(
                        title: title,
                        description: descCtrl.text.trim(),
                        busRoute: selectedRoute,
                        passengerName: itemData['passengerName'] as String,
                        passengerPhone: itemData['passengerPhone'] as String,
                      );

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✅ Xabar Dispetcherga yuborildi! Topilganda sizga ovozli xabar keladi."),
                          backgroundColor: Color(0xFF1D4ED8),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text("Dispetcherga yuborish", style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveBuses = ref.watch(liveBusesProvider);
    final busesAsync = ref.watch(_busesProvider);
    final buses = liveBuses.isNotEmpty ? liveBuses : (busesAsync.value ?? []);

    // If live bus updates match selected bus, sync occupancy & ETA in real-time
    if (buses.isNotEmpty) {
      Map<String, dynamic>? matching;
      for (final b in buses) {
        if (b is Map && (b['routeNumber']?.toString() == _selectedRoute || b['busCode']?.toString().contains(_selectedRoute) == true)) {
          matching = Map<String, dynamic>.from(b);
          break;
        }
      }
      if (matching != null) {
        final occ = (matching['occupancyPercent'] ?? _occupancyPercent) as num;
        final eta = (matching['eta'] ?? _etaMinutes) as num;
        _occupancyPercent = occ.toInt();
        _etaMinutes = eta.toInt();
      }
    }

    // Determine occupancy color & text
    Color occBadgeBg = const Color(0xFFDCFCE7);
    Color occBadgeText = const Color(0xFF16A34A);
    String occBadgeLabel = "Bo'sh · $_occupancyPercent%";

    if (_occupancyPercent >= 70) {
      occBadgeBg = const Color(0xFFFEE2E2);
      occBadgeText = const Color(0xFFDC2626);
      occBadgeLabel = "Gavjum · $_occupancyPercent%";
    } else if (_occupancyPercent >= 40) {
      occBadgeBg = const Color(0xFFFEF3C7);
      occBadgeText = const Color(0xFFD97706);
      occBadgeLabel = "O'rtacha · $_occupancyPercent%";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. Top Notice Pill (NAMOYISH REJIMI) ───────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                ),
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
                        "NAMOYISH REJIMI · Namunaviy ma'lumotlar",
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

              // ─── 2. Header: SmartBus Toshkent + Notification Bell ───────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmartBus Guliston',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Guliston · Aqlli Jamoat Transporti",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        color: Colors.white,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 22),
                        onPressed: () => _showNotificationsSheet(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ─── 3. Search Pill Bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onTap: () => ref.read(passengerNavIndexProvider.notifier).state = 1,
                          decoration: const InputDecoration(
                            hintText: 'Avtobus yoki bekatni qidiring (masalan: 1-avtobus)',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (query) {
                            if (query.contains('2') || query.contains('mavze') || query.contains('nurafshon')) {
                              _selectBus('2', 'TYB ↔ Nurafshon (2-mavze)', 'TYB', 'Yarmarka bekati', 2, 42, "TYB ko'chasi");
                            } else if (query.contains('1')) {
                              _selectBus('1', 'Yangi bozor ↔ GulDU', 'Yangi bozor1', 'Dehqon bozori', 2, 42, "Yangi bozor ko'chasi");
                            } else if (query.contains('23')) {
                              _selectBus('23', 'Chilonzor → Buyuk Ipak yo\'li', 'Chilonzor metro', 'Mirzo Ulug\'bek', 3, 32, "Chilonzor ko'chasi");
                            } else if (query.contains('80')) {
                              _selectBus('80', 'Chilonzor → Toshkent vokzali', 'Novza', 'Bunyodkor', 12, 56, "Bunyodkor shoh ko'chasi");
                            } else if (query.contains('51')) {
                              _selectBus('51', 'Yunusobod → Chorsu', 'Shahriston', 'Bodomzor', 6, 38, "Amir Temur shoh ko'chasi");
                            } else {
                              _selectBus('1', 'Yangi bozor ↔ GulDU', 'Yangi bozor1', 'Dehqon bozori', 2, 42, "Yangi bozor ko'chasi");
                            }
                          },
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _searchCtrl.clear()),
                          child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ─── 3.1 Route Quick Selector: 1-yo'l & 2-mavze ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRoute = '1';
                            _selectedRouteName = 'Yangi bozor ↔ GulDU';
                            _currentStop = 'Yangi bozor1';
                            _nextStop = 'Dehqon bozori';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _selectedRoute == '1' ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedRoute == '1' ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: _selectedRoute == '1'
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus_rounded,
                                size: 16,
                                color: _selectedRoute == '1' ? Colors.white : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "1-yo'l (GulDU)",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedRoute == '1' ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRoute = '2';
                            _selectedRouteName = 'TYB ↔ Nurafshon (2-mavze)';
                            _currentStop = 'TYB';
                            _nextStop = 'Yarmarka bekati';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _selectedRoute == '2' ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedRoute == '2' ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: _selectedRoute == '2'
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus_rounded,
                                size: 16,
                                color: _selectedRoute == '2' ? Colors.white : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "2-mavze (Nurafshon)",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedRoute == '2' ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── 4. Guliston Xaritasi va Harakatlanuvchi Avtobus (1-yo'l & 2-mavze) ───────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 270,
                  child: GulistonRouteMapWidget(
                    routeNumber: _selectedRoute == '2' ? '2' : '1',
                    onRouteChanged: (r) {
                      setState(() {
                        _selectedRoute = r;
                        if (r == '2') {
                          _selectedRouteName = 'TYB ↔ Nurafshon (2-mavze)';
                          _currentStop = 'TYB';
                          _nextStop = 'Yarmarka bekati';
                        } else {
                          _selectedRouteName = 'Yangi bozor ↔ GulDU';
                          _currentStop = 'Yangi bozor1';
                          _nextStop = 'Dehqon bozori';
                        }
                      });
                    },
                    onBusStateChanged: (busState) {
                      if (mounted) {
                        setState(() {
                          _liveBusLat = busState.latitude;
                          _liveBusLng = busState.longitude;
                          _selectedRouteName = GulistonRoutes.getRouteName(_selectedRoute, isForward: busState.isForward);
                          _currentStop = busState.currentStop.name;
                          _nextStop = busState.nextStop.name;
                          _etaMinutes = busState.etaMinutesToNext;
                          _currentStreet = busState.isWaitingAtStop
                              ? "${busState.currentStop.name} (Bekatda ${busState.waitSecondsRemaining}s)"
                              : "${busState.currentStop.name} yaqini (11 km/s)";
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ─── 5. Hero Active Bus Card (Exact layout of Image 2) ───────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Square Badge + Title & Route + ETA
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _selectedRoute,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Outfit',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_selectedRoute-avtobus',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedRouteName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$_etaMinutes daqiqa',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_nextStop bekatigacha',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Row 2: Taxminiy bandlik + Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Taxminiy bandlik',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: occBadgeBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              occBadgeLabel,
                              style: TextStyle(
                                color: occBadgeText,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Row 3: Segmented 3-part Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAB308),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Legend
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Bo'sh 0–40%",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "O'rtacha 40–70%",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "Gavjum 70–100%",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Stop Timeline 1: HOZIR · Chilonzor ko'chasi
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.radio_button_checked, color: Color(0xFF2563EB), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "HOZIR · $_currentStreet",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentStop,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Stop Timeline 2: KEYINGI BEKAT · SIZNING BEKATINGIZ
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on_outlined, color: Color(0xFF2563EB), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'KEYINGI BEKAT · SIZNING BEKATINGIZ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _nextStop,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Action Button: Bekat va kelishlarni ko'rish →
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _showStopsModal(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Bekat va kelishlarni ko'rish",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Disclaimer
                      const Center(
                        child: Text(
                          'Joylashuv va bandlik — namuna, haqiqiy kuzatuv emas.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

