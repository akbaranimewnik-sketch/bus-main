import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';
import '../core/storage_service.dart';
import '../core/socket_service.dart';
import '../core/theme.dart';

/// Shows Dispatcher Login Modal requiring login: 'admin' and password: 'admin123'
void showDispatcherLoginModal(BuildContext context, WidgetRef ref) {
  final loginCtrl = TextEditingController(text: 'admin');
  final passCtrl = TextEditingController(text: 'admin123');
  bool obscure = true;
  String? errorMsg;
  bool loading = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
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
                    child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dispetcher Tizimi',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Kirish uchun admin login va parolini kiriting',
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
              const SizedBox(height: 20),

              if (errorMsg != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMsg!, style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

              const Text('Login', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: loginCtrl,
                decoration: InputDecoration(
                  hintText: 'admin',
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Parol', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'admin123',
                  prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Standart ma\'lumotlar: Login: admin  |  Parol: admin123',
                        style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final login = loginCtrl.text.trim();
                          final pass = passCtrl.text;
                          if (login.isEmpty || pass.isEmpty) {
                            setState(() => errorMsg = "Login va parolni kiriting");
                            return;
                          }

                          setState(() {
                            loading = true;
                            errorMsg = null;
                          });

                          try {
                            if (login == 'admin' && pass == 'admin123') {
                              final storage = ref.read(storageServiceProvider);
                              await storage.setUserRole('ADMIN');
                              await storage.setUserName('Dispetcher Admin');
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                context.go('/admin');
                              }
                              return;
                            }

                            // Check API
                            final api = ref.read(apiServiceProvider);
                            final res = await api.login(username: login, password: pass);
                            if (res['success'] == true && res['data']?['role'] == 'admin') {
                              final storage = ref.read(storageServiceProvider);
                              await storage.setUserRole('ADMIN');
                              await storage.setUserName(res['data']?['fullName'] ?? 'Dispetcher Admin');
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                context.go('/admin');
                              }
                            } else {
                              setState(() => errorMsg = "Login yoki parol noto'g'ri! (Login: admin, Parol: admin123)");
                            }
                          } catch (e) {
                            if (login == 'admin' && pass == 'admin123') {
                              final storage = ref.read(storageServiceProvider);
                              await storage.setUserRole('ADMIN');
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                context.go('/admin');
                              }
                            } else {
                              setState(() => errorMsg = "Login yoki parol noto'g'ri! (Login: admin, Parol: admin123)");
                            }
                          } finally {
                            setState(() => loading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kirish', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Shows Driver Login Modal requiring login and password generated by Dispetcher
void showDriverLoginModal(BuildContext context, WidgetRef ref) {
  final loginCtrl = TextEditingController(text: 'haydovchi1');
  final passCtrl = TextEditingController(text: 'pass1');
  bool obscure = true;
  String? errorMsg;
  bool loading = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.drive_eta_rounded, color: Color(0xFF10B981), size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Haydovchi Tizimi',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Dispetcher tomonidan berilgan login va parolni kiriting',
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
              const SizedBox(height: 20),

              if (errorMsg != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMsg!, style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

              const Text('Login', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: loginCtrl,
                decoration: InputDecoration(
                  hintText: 'haydovchi...',
                  prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Parol', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  hintText: 'pass...',
                  prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dispetcher "Haydovchilar" bo\'limida yaratgan login (masalan: haydovchi1) va parolni kiriting.',
                        style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final login = loginCtrl.text.trim();
                          final pass = passCtrl.text.trim();
                          if (login.isEmpty || pass.isEmpty) {
                            setState(() => errorMsg = "Login va parolni kiriting");
                            return;
                          }

                          setState(() {
                            loading = true;
                            errorMsg = null;
                          });

                          try {
                            // 1. Authenticate against API
                            final api = ref.read(apiServiceProvider);
                            final res = await api.login(username: login, password: pass);
                            if (res['success'] == true) {
                              final storage = ref.read(storageServiceProvider);
                              await storage.setUserRole('DRIVER');
                              await storage.setUserName(res['data']?['fullName'] ?? 'Haydovchi');
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                context.go('/driver');
                              }
                              return;
                            } else {
                              setState(() => errorMsg = res['message'] ?? "Login yoki parol noto'g'ri!");
                            }
                          } catch (e) {
                            // 2. Offline fallback check for local environment
                            final drivers = ref.read(driversProvider);
                            final localMatch = drivers.cast<Map<String, dynamic>?>().firstWhere(
                              (d) => (d?['username']?.toString().toLowerCase() == login.toLowerCase() ||
                                      d?['phoneNumber'] == login),
                              orElse: () => null,
                            );

                            if (localMatch != null && (login == 'haydovchi1' && pass == 'pass1')) {
                              final storage = ref.read(storageServiceProvider);
                              await storage.setUserRole('DRIVER');
                              await storage.setUserName(localMatch['fullName'] ?? 'Haydovchi');
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                context.go('/driver');
                              }
                            } else {
                              setState(() => errorMsg = "Login yoki parol noto'g'ri! Iltimos, qayta urinib ko'ring.");
                            }
                          } finally {
                            setState(() => loading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kirish', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
