import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';
import '../core/storage_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String selectedRole;
  const RegisterScreen({super.key, this.selectedRole = 'PASSENGER'});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _step = 0; // 0: Phone entry (Image 2), 1: SMS OTP (Image 3), 2: Permissions (Image 4)

  final _phoneCtrl = TextEditingController(text: '+998 90 712 34 42');
  final List<TextEditingController> _otpControllers = List.generate(6, (i) => TextEditingController(text: '${i + 1}'));
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _agreeTerms = true;
  bool _otpError = false;
  int _resendCountdown = 42;
  Timer? _timer;

  bool _locationGranted = false;
  bool _notificationGranted = false;

  late String _role;

  @override
  void initState() {
    super.initState();
    _role = widget.selectedRole;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendCountdown = 42);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  void _submitPhone() {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, telefon raqamingizni kiriting')),
      );
      return;
    }
    _startTimer();
    setState(() => _step = 1);
  }

  void _submitOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _otpError = true);
      return;
    }

    // Complete login in storage
    final storage = ref.read(storageServiceProvider);
    await storage.setToken('token_${DateTime.now().millisecondsSinceEpoch}');
    await storage.setUserPhone(_phoneCtrl.text.trim());
    await storage.setUserName(_role == 'DRIVER' ? 'Haydovchi' : "Yo'lovchi");
    await storage.setUserRole(_role);
    await storage.setOnboardingDone();
    await storage.setRegistered();

    try {
      await ref.read(apiServiceProvider).register(
        fullName: _role == 'DRIVER' ? 'Haydovchi' : "Yo'lovchi",
        phoneNumber: _phoneCtrl.text.trim(),
        password: 'pass_${DateTime.now().millisecondsSinceEpoch}',
        role: _role,
      );
    } catch (_) {}

    setState(() => _step = 2);
  }

  void _finishOnboarding() {
    if (_role == 'DRIVER') {
      context.go('/driver');
    } else if (_role == 'ADMIN') {
      context.go('/admin');
    } else {
      context.go('/passenger');
    }
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
              // ─── Top Notice Bar (NAMOYISH REJIMI) ───────────────────────────
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

              // ─── Step Content ───────────────────────────────────────────────
              if (_step == 0) _buildPhoneLoginStep(),
              if (_step == 1) _buildOtpStep(),
              if (_step == 2) _buildPermissionsStep(),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 0: IMAGE 2 — Telefon orqali kirish
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPhoneLoginStep() {
    final roleName = _role == 'DRIVER' ? 'Haydovchi' : "Yo'lovchi";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          Row(
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
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/onboarding');
                    }
                  },
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Telefon orqali kirish',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$roleName hisobi · Kirish yoki ro'yxatdan o'tish",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Smartphone illustration in soft blue square
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Icon(Icons.smartphone_rounded, color: Color(0xFF1D4ED8), size: 36),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title & Subtitle
          const Text(
            'Safarlaringiz bir joyda',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sevimli manzillar va murojaatlaringizni saqlash uchun telefon raqamingizni kiriting.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
          ),

          const SizedBox(height: 20),

          // Phone input field
          const Text(
            'Telefon raqami',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Container(
            height: 52,
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
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '+998 90 ••• •• 42',
                    ),
                  ),
                ),
                const Icon(Icons.phone_outlined, color: Color(0xFF64748B), size: 20),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Raqam namunaviy ko\'rsatilgan. Tasdiqlash uchun 6 xonali SMS kod kerak bo\'ladi.',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),

          const SizedBox(height: 16),

          // Checkbox: Terms agreement
          GestureDetector(
            onTap: () => setState(() => _agreeTerms = !_agreeTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _agreeTerms ? const Color(0xFF1D4ED8) : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _agreeTerms ? const Color(0xFF1D4ED8) : const Color(0xFFCBD5E1)),
                  ),
                  child: _agreeTerms ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Foydalanish shartlari va maxfiylik siyosatiga roziman.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Primary Button: "SMS kod olish →"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _agreeTerms ? _submitPhone : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SMS kod olish', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Links
          const Center(
            child: Text(
              'Foydalanish shartlari  ·  Maxfiylik siyosati',
              style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 20),

          // Organization Worker Card (Image 2)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(18)),
              border: Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: Color(0xFF1D4ED8), size: 22),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tashkilot xodimimisiz?',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Tashkilot ruxsati bilan kirish',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Haydovchi va dispetcher vakolatini tashkilot administratori beradi. Rolni o\'zingiz yoqa olmaysiz.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Info note at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Namoyish rejimida SMS yuborilmaydi va yangi hisob yaratilmaydi.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), height: 1.3, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 1: IMAGE 3 — Raqamni tasdiqlang (SMS 6-digit OTP)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOtpStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
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
                  onPressed: () => setState(() => _step = 0),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raqamni tasdiqlang',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Telefon orqali kirish · 2-bosqich',
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

          const SizedBox(height: 24),

          // Message bubble icon in light blue container
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF1D4ED8), size: 36),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title & Subtitle
          const Text(
            '6 xonali kodni kiriting',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kod ${_phoneCtrl.text} raqamiga yuborilishi kerak. Bu ekrandagi kod faqat namuna.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
          ),

          const SizedBox(height: 8),

          GestureDetector(
            onTap: () => setState(() => _step = 0),
            child: const Text(
              'Telefon raqamini o\'zgartirish',
              style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),

          const SizedBox(height: 20),

          // 6 OTP Digit Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              return Container(
                width: 48,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _otpError ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _otpFocusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    maxLength: 1,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) {
                        _otpFocusNodes[i + 1].requestFocus();
                      } else if (val.isEmpty && i > 0) {
                        _otpFocusNodes[i - 1].requestFocus();
                      }
                      setState(() => _otpError = false);
                    },
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Error sample note (Image 3)
          if (_otpError)
            const Text(
              'Xato holati namunasi: kod mos kelmadi. Qayta tekshiring.',
              style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
            ),

          const SizedBox(height: 16),

          // Primary Button: "Tasdiqlash"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Tasdiqlash', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 14),

          // Resend timer row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kodni qayta yuborish', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              Text(
                '00:${_resendCountdown.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Help Card: "Kod kelmadimi?"
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(18)),
              border: Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kod kelmadimi?',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 6),
                Text(
                  'Raqamni tekshiring va hisoblagich tugashini kuting. Kodni hech kimga bermang.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35),
                ),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Kirish bo\'yicha yordam',
                      style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: Color(0xFF1D4ED8), size: 16),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Info Callout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bu tasdiqlash holati namuna. Haqiqiy SMS yoki kirish ma\'lumotlari ishlatilmaydi.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), height: 1.3, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2: IMAGE 4 — Safarni qulayroq qiling (Permissions Screen)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPermissionsStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          Row(
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
                  onPressed: () => setState(() => _step = 1),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safarni qulayroq qiling',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ruxsatlar · Tanlov sizning qo\'lingizda',
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

          const SizedBox(height: 16),

          const Text(
            'Kerakli imkoniyatlarni yoqing. Ruxsat bermasdan ham manzil va bekatlarni qo\'lda qidirishingiz mumkin.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
          ),

          const SizedBox(height: 20),

          // Permission Card 1: Joylashuv (Location)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.my_location_rounded, color: Color(0xFF1D4ED8), size: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _locationGranted ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _locationGranted ? 'Ruxsat berildi' : 'Hali so\'ralmagan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _locationGranted ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Yaqin bekatlarni toping',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Joylashuvingiz safar boshlanishini tanlash va yaqin bekatlarni ko\'rsatish uchun kerak.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _locationGranted = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _locationGranted ? '✓ Joylashuvga ruxsat berildi' : 'Joylashuvga ruxsat berish',
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ruxsat turi telefonning tizim oynasida tanlanadi.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Permission Card 2: Bildirishnomalar (Notifications)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.notifications_outlined, color: Color(0xFF1D4ED8), size: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _notificationGranted ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _notificationGranted ? 'Ruxsat berildi' : 'Hali so\'ralmagan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _notificationGranted ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bekatingizni o\'tkazib yubormang',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kelish eslatmalari va murojaat holatidagi o\'zgarishlar haqida xabar olishni tanlang.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _notificationGranted = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: const Color(0xFF1D4ED8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _notificationGranted ? '✓ Bildirishnomalar faollashtirildi' : 'Bildirishnomalarga ruxsat',
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Skip / Continue Button: "Hozircha o'tkazib yuborish"
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _finishOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: const Color(0xFF1D4ED8),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                (_locationGranted || _notificationGranted) ? 'Davom etish  →' : 'Hozircha o\'tkazib yuborish',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Info Callout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ruxsatlar hali berilmagan. Ularni keyin Profil → Maxfiylik bo\'limida boshqarasiz.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), height: 1.3, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
