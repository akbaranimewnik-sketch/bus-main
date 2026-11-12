import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_service.dart';
import '../../../core/storage_service.dart';
import '../../../core/theme.dart';
import '../../../widgets/auth_dialogs.dart';
import '../../../widgets/edit_account_modal.dart';

class PassengerProfileTab extends ConsumerStatefulWidget {
  const PassengerProfileTab({super.key});

  @override
  ConsumerState<PassengerProfileTab> createState() => _PassengerProfileTabState();
}

class _PassengerProfileTabState extends ConsumerState<PassengerProfileTab> {
  int _subTab = 0; // 0: info, 1: yo'qolgan, 2: shikoyat, 3: bildirishnoma

  // Lost items form
  final _lostItemCtrl = TextEditingController();
  final _lostBusCtrl = TextEditingController();
  final _lostDescCtrl = TextEditingController();
  bool _lostSubmitted = false;
  final List<Map<String, String>> _myLostItems = [
    {'item': 'Qora sumka', 'bus': 'GUL-003', 'date': '2026-08-24', 'status': "Ko'rib chiqilmoqda"},
    {'item': 'Telefon zaryadlagich', 'bus': 'GUL-001', 'date': '2026-08-20', 'status': 'Topildi'},
  ];

  // Complaint form
  final _reportTitleCtrl = TextEditingController();
  final _reportDescCtrl = TextEditingController();
  bool _reportSubmitted = false;

  // Notifications
  bool _notifSos = true;
  bool _notifDelay = true;
  bool _notifEta = true;

  @override
  void dispose() {
    _lostItemCtrl.dispose();
    _lostBusCtrl.dispose();
    _lostDescCtrl.dispose();
    _reportTitleCtrl.dispose();
    _reportDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLostSubmit() async {
    if (_lostItemCtrl.text.isEmpty || _lostBusCtrl.text.isEmpty) return;
    try {
      await ref.read(apiServiceProvider).submitReport(
        title: _lostItemCtrl.text,
        description: _lostDescCtrl.text,
        type: 'LOST_ITEM',
        busId: _lostBusCtrl.text,
      );
    } catch (_) {}

    setState(() {
      _myLostItems.insert(0, {
        'item': _lostItemCtrl.text,
        'bus': _lostBusCtrl.text,
        'date': DateTime.now().toString().split(' ').first,
        'status': "Ko'rib chiqilmoqda",
      });
      _lostSubmitted = true;
      _lostItemCtrl.clear();
      _lostBusCtrl.clear();
      _lostDescCtrl.clear();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _lostSubmitted = false);
    });
  }

  Future<void> _handleReportSubmit() async {
    if (_reportTitleCtrl.text.isEmpty || _reportDescCtrl.text.isEmpty) return;
    try {
      await ref.read(apiServiceProvider).submitReport(
        title: _reportTitleCtrl.text,
        description: _reportDescCtrl.text,
        type: 'COMPLAINT',
      );
    } catch (_) {}

    setState(() {
      _reportSubmitted = true;
      _reportTitleCtrl.clear();
      _reportDescCtrl.clear();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _reportSubmitted = false);
    });
  }

  Future<void> _logout() async {
    await ref.read(storageServiceProvider).clearAll();
    if (mounted) context.go('/register');
  }

  void _switchRole(String role) async {
    if (role == 'DRIVER') {
      showDriverLoginModal(context, ref);
      return;
    } else if (role == 'ADMIN') {
      showDispatcherLoginModal(context, ref);
      return;
    }
    await ref.read(storageServiceProvider).setUserRole(role);
    if (!mounted) return;
    context.go('/passenger');
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storage.userName.isNotEmpty ? storage.userName : 'Foydalanuvchi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      Text(
                        storage.userPhone.isNotEmpty ? storage.userPhone : '+998 90 123 45 67',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (storage.userRole.isNotEmpty ? storage.userRole : 'PASSENGER').toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => showEditAccountModal(
                    context,
                    ref,
                    onUpdated: () => setState(() {}),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
                  tooltip: "Akkountni tahrirlash",
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sub-tabs segment
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SubTabButton(label: "Ma'lumot", selected: _subTab == 0, onTap: () => setState(() => _subTab = 0)),
                const SizedBox(width: 8),
                _SubTabButton(label: "Yo'qolgan", selected: _subTab == 1, onTap: () => setState(() => _subTab = 1)),
                const SizedBox(width: 8),
                _SubTabButton(label: 'Shikoyat', selected: _subTab == 2, onTap: () => setState(() => _subTab = 2)),
                const SizedBox(width: 8),
                _SubTabButton(label: 'Bildirishnoma', selected: _subTab == 3, onTap: () => setState(() => _subTab = 3)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content based on sub-tab
          if (_subTab == 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const _InfoRow(label: 'Shahar', value: 'Guliston, Sirdaryo'),
                  const Divider(height: 20),
                  const _InfoRow(label: 'Tizim versiyasi', value: '2.0.0 (Flutter)'),
                  const Divider(height: 20),
                  const _InfoRow(label: 'Status', value: 'Faol'),
                  const Divider(height: 20),
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                      ),
                      title: const Text(
                        'Akkount ma\'lumotlarini tahrirlash',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      subtitle: const Text('Ism, telefon raqam va profilni yangilash', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showEditAccountModal(
                        context,
                        ref,
                        onUpdated: () => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Role switcher
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ROLNI ALMASHTIRISH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _RoleSwitchButton(
                        label: "Yo'lovchi",
                        icon: Icons.person_rounded,
                        selected: storage.userRole.isEmpty || storage.userRole == 'PASSENGER',
                        onTap: () => _switchRole('PASSENGER'),
                      ),
                      const SizedBox(width: 8),
                      _RoleSwitchButton(
                        label: 'Haydovchi',
                        icon: Icons.drive_eta_rounded,
                        selected: storage.userRole == 'DRIVER',
                        onTap: () => _switchRole('DRIVER'),
                      ),
                      const SizedBox(width: 8),
                      _RoleSwitchButton(
                        label: 'Dispetcher',
                        icon: Icons.headset_mic_rounded,
                        selected: storage.userRole == 'ADMIN',
                        onTap: () => _switchRole('ADMIN'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text('Akkountdan Chiqish', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ] else if (_subTab == 1) ...[
            // Lost items form & list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Yo'qolgan Buyum Arizasi", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (_lostSubmitted)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 48),
                            SizedBox(height: 8),
                            Text('Ariza yuborildi!', style: TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    TextField(controller: _lostItemCtrl, decoration: const InputDecoration(labelText: 'Buyum nomi *', hintText: 'Masalan: Qora ryukzak')),
                    const SizedBox(height: 10),
                    TextField(controller: _lostBusCtrl, decoration: const InputDecoration(labelText: 'Avtobus raqami *', hintText: 'GUL-003')),
                    const SizedBox(height: 10),
                    TextField(controller: _lostDescCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Batafsil', hintText: 'Qaysi bekatda, soat nechida...')),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleLostSubmit,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Ariza Yuborish'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text('MENING ARIZALARIM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            ..._myLostItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  const Icon(Icons.work_outline_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['item']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        Text("${item['bus']} · ${item['date']}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: item['status'] == 'Topildi' ? AppColors.accent.withOpacity(0.15) : AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text(item['status']!, style: TextStyle(color: item['status'] == 'Topildi' ? AppColors.accent : AppColors.warning, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            )),
          ] else if (_subTab == 2) ...[
            // Complaint form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shikoyat Yuborish', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (_reportSubmitted)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 48),
                            SizedBox(height: 8),
                            Text('Shikoyat qabul qilindi!', style: TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Wrap(
                      spacing: 8,
                      children: ['Kechikish', 'Haydovchi', 'Tozalik'].map((t) => ActionChip(
                        label: Text(t),
                        onPressed: () => setState(() => _reportTitleCtrl.text = t),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: _reportTitleCtrl, decoration: const InputDecoration(labelText: 'Mavzu')),
                    const SizedBox(height: 10),
                    TextField(controller: _reportDescCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Batafsil muammo...')),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleReportSubmit,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Yuborish'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (_subTab == 3) ...[
            // Notifications toggle
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('SOS ogohlantirishlari', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text("Yaqin SOS signallari haqida", style: TextStyle(fontSize: 12)),
                    value: _notifSos,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _notifSos = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Kechikish xabarlari', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text("Sevimli yo'nalishlarda kechikish", style: TextStyle(fontSize: 12)),
                    value: _notifDelay,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _notifDelay = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('ETA yaqinlashdi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Avtobus bekatga kelganda', style: TextStyle(fontSize: 12)),
                    value: _notifEta,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _notifEta = v),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _RoleSwitchButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleSwitchButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SubTabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    ],
  );
}
