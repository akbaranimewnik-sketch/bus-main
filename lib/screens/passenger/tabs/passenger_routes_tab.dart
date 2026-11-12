import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../passenger_shell.dart';

class PassengerRoutesTab extends ConsumerStatefulWidget {
  const PassengerRoutesTab({super.key});

  @override
  ConsumerState<PassengerRoutesTab> createState() => _PassengerRoutesTabState();
}

class _PassengerRoutesTabState extends ConsumerState<PassengerRoutesTab> {
  final _searchCtrl = TextEditingController(text: '2-mavze');
  String _selectedFilter = 'Barchasi'; // 'Barchasi', 'Avtobuslar', 'Bekatlar', 'Manzillar'

  final List<Map<String, String>> _recentSearches = [
    {'title': '2-avtobus (2-mavze)', 'subtitle': 'TYB ↔ Nurafshon bekati', 'type': 'bus'},
    {'title': '1-avtobus', 'subtitle': 'Yangi bozor ↔ GulDU', 'type': 'bus'},
    {'title': 'Nurafshon bekati', 'subtitle': '2-mavze yakuniy bekati', 'type': 'place'},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearRecent() {
    setState(() => _recentSearches.clear());
  }

  void _selectResult(String title) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Tanlandi: $title. Xarita oynasiga o'tilmoqda..."),
        backgroundColor: const Color(0xFF1D4ED8),
        duration: const Duration(seconds: 2),
      ),
    );
    // Switch to Xarita tab (tab 0)
    ref.read(passengerNavIndexProvider.notifier).state = 0;
  }

  @override
  Widget build(BuildContext context) {
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

              // ─── 2. Header with Back Button and Title ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        color: Colors.white,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B), size: 20),
                        onPressed: () {
                          // Switch back to Xarita tab
                          ref.read(passengerNavIndexProvider.notifier).state = 0;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Qidiruv',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Avtobus, bekat yoki manzil toping',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ─── 3. Search Query Input Field (Image 5) ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Qidiruv so\'rovi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Qidirish...',
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => setState(() => _searchCtrl.clear()),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ─── 4. Filter Chips Row: Barchasi, Avtobuslar, Bekatlar, Manzillar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Barchasi', 'Avtobuslar', 'Bekatlar', 'Manzillar'].map((filter) {
                      final isActive = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── 5. Matching Results Section (Mos natijalar) ─────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mos natijalar',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '3 ta natija',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Item 1: 2-avtobus (2-mavze)
                      _buildResultItem(
                        icon: Icons.directions_bus_outlined,
                        title: '2-avtobus (2-mavze)',
                        subtitle: 'TYB ↔ Nurafshon bekati · 11 km/s · 24 bekat',
                        trailing: '2 daq',
                        onTap: () => _selectResult('2-avtobus (2-mavze)'),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      // Item 2: Nurafshon bekati
                      _buildResultItem(
                        icon: Icons.location_on_outlined,
                        title: 'Nurafshon bekati',
                        subtitle: '2-mavze · 2-yo\'nalish yakuniy bekati',
                        trailing: '18 daq',
                        onTap: () => _selectResult('Nurafshon bekati'),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      // Item 3: 1-avtobus (GulDU)
                      _buildResultItem(
                        icon: Icons.directions_bus_outlined,
                        title: '1-avtobus',
                        subtitle: 'Yangi bozor ↔ GulDU · 11 km/s · 31 bekat',
                        trailing: '4 daq',
                        onTap: () => _selectResult('1-avtobus'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ─── 6. Recent Searches Section (Oxirgi qidiruvlar) ──────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Oxirgi qidiruvlar',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearRecent,
                      child: const Text(
                        'Tozalash',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              if (_recentSearches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: List.generate(_recentSearches.length, (i) {
                        final item = _recentSearches[i];
                        return Column(
                          children: [
                            _buildResultItem(
                              icon: Icons.history_rounded,
                              title: item['title']!,
                              subtitle: item['subtitle']!,
                              onTap: () {
                                _searchCtrl.text = item['title']!;
                                setState(() {});
                              },
                            ),
                            if (i < _recentSearches.length - 1)
                              const Divider(height: 1, indent: 56, endIndent: 16),
                          ],
                        );
                      }),
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              // ─── 7. Info Callout Note (Image 5) ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Natija topilmasa, bekat nomini qisqaroq yozing yoki yo\'nalish raqamini kiriting.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), height: 1.35, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ─── 8. Footer caption ─────────────────────────────────────────
              const Center(
                child: Text(
                  'Kelish va masofalar namunaviy taxminlar.',
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

  Widget _buildResultItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1D4ED8), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D4ED8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
