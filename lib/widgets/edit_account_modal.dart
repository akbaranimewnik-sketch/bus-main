import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage_service.dart';
import '../core/theme.dart';
import '../screens/passenger/passenger_shell.dart';

/// Opens the Edit Account modal bottom sheet
void showEditAccountModal(BuildContext context, WidgetRef ref, {VoidCallback? onUpdated}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => EditAccountModal(onUpdated: onUpdated),
  );
}

class EditAccountModal extends ConsumerStatefulWidget {
  final VoidCallback? onUpdated;
  const EditAccountModal({super.key, this.onUpdated});

  @override
  ConsumerState<EditAccountModal> createState() => _EditAccountModalState();
}

class _EditAccountModalState extends ConsumerState<EditAccountModal> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;
  int _selectedAvatarIndex = 0;

  final List<IconData> _avatarIcons = [
    Icons.person_rounded,
    Icons.face_rounded,
    Icons.school_rounded,
    Icons.directions_bus_rounded,
    Icons.emoji_people_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageServiceProvider);
    _nameCtrl = TextEditingController(
      text: storage.userName.isNotEmpty ? storage.userName : "Yo'lovchi",
    );
    _phoneCtrl = TextEditingController(
      text: storage.userPhone.isNotEmpty ? storage.userPhone : '+998 90 123 45 67',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, ismingizni kiriting'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final storage = ref.read(storageServiceProvider);
      await storage.setUserName(name);
      await storage.setUserPhone(phone);

      if (widget.onUpdated != null) {
        widget.onUpdated!();
      }

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text("Akkount ma'lumotlari muvaffaqiyatli saqlandi!"),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goToFullProfile() {
    Navigator.pop(context);
    ref.read(passengerNavIndexProvider.notifier).state = 3;
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final userRole = storage.userRole.isNotEmpty ? storage.userRole : 'PASSENGER';

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.manage_accounts_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Akkountni Tahrirlash',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Shaxsiy ma\'lumotlaringizni yangilang',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Avatar selector & preview
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      _avatarIcons[_selectedAvatarIndex],
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Quick avatar icon choices
            Center(
              child: Wrap(
                spacing: 8,
                children: List.generate(_avatarIcons.length, (i) {
                  final isSelected = _selectedAvatarIndex == i;
                  return InkWell(
                    onTap: () => setState(() => _selectedAvatarIndex = i),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        _avatarIcons[i],
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // Name input
            const Text(
              'Ism va Familiya',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                hintText: 'Ismingizni kiriting',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Phone input
            const Text(
              'Telefon raqami',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                hintText: '+998 90 123 45 67',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Role and City info badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rol: ${userRole.toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const Text(
                          'Shahar: Guliston, Sirdaryo',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _handleSave,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _saving ? 'Saqlanmoqda...' : 'O\'zgarishlarni Saqlash',
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Link to full profile tab
            Center(
              child: TextButton.icon(
                onPressed: _goToFullProfile,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryLight),
                label: const Text(
                  'To\'liq Profil sahifasiga o\'tish',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
