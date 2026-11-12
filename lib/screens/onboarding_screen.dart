import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/storage_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String _selectedRole = 'PASSENGER'; // 'PASSENGER', 'DRIVER', 'ADMIN'

  String get _roleTitle {
    switch (_selectedRole) {
      case 'DRIVER':
        return 'Haydovchi';
      case 'ADMIN':
        return 'Dispetcher';
      default:
        return "Yo'lovchi";
    }
  }

  void _startWithRole() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingDone();
    await storage.setUserRole(_selectedRole);

    if (!mounted) return;
    if (_selectedRole == 'DRIVER') {
      context.go('/driver');
    } else if (_selectedRole == 'ADMIN') {
      context.go('/admin');
    } else {
      context.go('/passenger');
    }
  }

  void _login() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingDone();
    if (!mounted) return;
    context.go('/register?role=$_selectedRole');
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

              // ─── 2. Header with Back button and SmartBus title ────────────
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
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmartBus',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "O'zbekiston · Yo'lingiz oson bo'lsin",
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

              const SizedBox(height: 14),

              // ─── 3. Schematic Map Preview Card (Image 1) ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 160),
                        painter: _WelcomeSchematicMapPainter(),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Text(
                          'Sxematik xarita · haqiqiy kuzatuv emas',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── 4. Badge pill: "Bir shahar. Bir qulay safar." ──────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Bir shahar. Bir qulay safar.',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ─── 5. Hero Heading & Subtitle ────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Shahar bo'ylab ishonchli yo'l toping",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Avtobus kelishini solishtiring, qulay yo'lni tanlang va safaringizni rejalang.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── 6. Role Selection Card (Image 1) ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active / Primary Selected Role Row
                      GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'PASSENGER'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedRole == 'PASSENGER' ? const Color(0xFF1D4ED8) : const Color(0xFFCBD5E1),
                                    width: _selectedRole == 'PASSENGER' ? 6 : 2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Yo'lovchi",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Bekatlar, yo'nalishlar va safarlar",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedRole == 'PASSENGER')
                                const Text(
                                  'Tanlangan',
                                  style: TextStyle(
                                    color: Color(0xFF1D4ED8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Quick role selector chips: Haydovchi & Dispetcher
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = 'DRIVER'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'DRIVER' ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedRole == 'DRIVER' ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_bus_rounded,
                                      size: 18,
                                      color: _selectedRole == 'DRIVER' ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Haydovchi',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedRole == 'DRIVER' ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
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
                              onTap: () => setState(() => _selectedRole = 'ADMIN'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'ADMIN' ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedRole == 'ADMIN' ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.grid_view_rounded,
                                      size: 18,
                                      color: _selectedRole == 'ADMIN' ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Dispetcher',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedRole == 'ADMIN' ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Xodimlar faqat tashkilot bergan ruxsat bilan kiradi.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ─── 7. Primary Action Button: "Yo'lovchi sifatida boshlash →" ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _startWithRole,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$_roleTitle sifatida boshlash",
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ─── 8. Secondary Button: "Hisobga kirish" ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: const Color(0xFF1D4ED8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Hisobga kirish',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ─── 9. Disclaimer at bottom ───────────────────────────────────
              const Center(
                child: Text(
                  'Xarita va kelishlar bu namoyishda namunaviy.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
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

/// Custom schematic map painter for Image 1 welcome card
class _WelcomeSchematicMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final greyPaint = Paint()..color = const Color(0xFFE2E8F0);
    final greenPaint = Paint()..color = const Color(0xFFDCFCE7);

    // Top-left block
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(26, 14, 52, 34), const Radius.circular(10)),
      greenPaint,
    );

    // Top-center block
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(115, 12, 36, 32), const Radius.circular(8)),
      greyPaint,
    );

    // Top-right block
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(190, 14, 72, 34), const Radius.circular(10)),
      greyPaint,
    );

    // Mid-left block
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(28, 62, 46, 30), const Radius.circular(8)),
      greenPaint,
    );

    // Mid-right block
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(204, 62, 54, 30), const Radius.circular(8)),
      greyPaint,
    );

    // Bottom-right green block
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(180, 108, 76, 32), const Radius.circular(10)),
      greenPaint,
    );

    // Text labels
    _drawText(canvas, 'Bunyodkor', const Offset(115, 78), const Color(0xFF475569), 9, FontWeight.w600);
    _drawText(canvas, 'Muqimiy', const Offset(160, 48), const Color(0xFF475569), 9, FontWeight.w600);
    _drawText(canvas, 'Chilonzor metro', const Offset(238, 48), const Color(0xFF475569), 9, FontWeight.w600);

    // Route line
    final routePaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(28, 98);
    path.lineTo(100, 98);
    path.lineTo(100, 42);
    path.lineTo(242, 42);

    canvas.drawPath(path, routePaint);

    // Stops
    _drawStopNode(canvas, const Offset(100, 68));
    _drawStopNode(canvas, const Offset(150, 42));
    _drawStopNode(canvas, const Offset(218, 42));

    // Bus 17 marker badge: [🚌 17]
    const busPos = Offset(100, 104);
    const w = 36.0;
    const h = 22.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(busPos.dx, busPos.dy - 3), width: w, height: h),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1D4ED8));

    final tp = TextPainter(
      text: const TextSpan(
        children: [
          TextSpan(text: '🚌 ', style: TextStyle(fontSize: 8)),
          TextSpan(text: '17', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(busPos.dx - tp.width / 2, busPos.dy - 3 - tp.height / 2));
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
