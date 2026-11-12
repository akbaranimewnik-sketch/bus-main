import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/socket_service.dart';
import '../core/theme.dart';

class PassengerSmsAlertOverlay extends ConsumerWidget {
  const PassengerSmsAlertOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smsAlert = ref.watch(passengerSmsAlertProvider);
    if (smsAlert == null) return const SizedBox.shrink();

    final isFound = smsAlert['type'] == 'found';
    final title = smsAlert['title'] ?? (isFound ? "🎉 BUYUMINGIZ TOPILDI!" : "⚠️ OGOHLANTIRISH");
    final message = smsAlert['message'] ?? '';

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFound ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isFound ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isFound ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sms_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'YANGI SMS XABARNOMA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Ovozli', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => ref.read(passengerSmsAlertProvider.notifier).state = null,
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),

              // Content body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isFound ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFound ? Icons.check_circle_rounded : Icons.traffic_rounded,
                            color: isFound ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: isFound ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => ref.read(passengerSmsAlertProvider.notifier).state = null,
                          child: const Text('Yopish', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(passengerSmsAlertProvider.notifier).state = null;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Dispetcherlik bilan bog'lanish: +998 67 225-01-23"),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          icon: const Icon(Icons.call_rounded, size: 16),
                          label: const Text('Dispetcher (+998 67 225-01-23)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFound ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
