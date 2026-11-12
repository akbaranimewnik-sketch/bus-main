import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/passenger_sms_alert_overlay.dart';
import 'tabs/passenger_home_tab.dart';
import 'tabs/passenger_routes_tab.dart';
import 'tabs/passenger_favorites_tab.dart';
import 'tabs/passenger_profile_tab.dart';

final passengerNavIndexProvider = StateProvider<int>((ref) => 0);

class PassengerShell extends ConsumerStatefulWidget {
  const PassengerShell({super.key});

  @override
  ConsumerState<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends ConsumerState<PassengerShell> {
  final _tabs = const [
    PassengerHomeTab(),
    PassengerRoutesTab(),
    PassengerFavoritesTab(),
    PassengerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(passengerNavIndexProvider);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(index: navIndex, children: _tabs),
          const PassengerSmsAlertOverlay(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: (i) => ref.read(passengerNavIndexProvider.notifier).state = i,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEFF6FF),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.map_rounded, color: Color(0xFF1D4ED8)),
            label: 'Xarita',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_calls_rounded, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.swap_calls_rounded, color: Color(0xFF1D4ED8)),
            label: 'Safar',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.inbox_rounded, color: Color(0xFF1D4ED8)),
            label: 'Murojaatlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF1D4ED8)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
