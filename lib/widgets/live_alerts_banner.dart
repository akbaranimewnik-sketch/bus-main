import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/socket_service.dart';

class LiveAlertsBanner extends ConsumerWidget {
  const LiveAlertsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(delayAlertProvider);

    // If no active delay alert has been triggered, do NOT show the banner
    if (alert == null) {
      return const SizedBox.shrink();
    }

    final message = alert['message']?.toString() ??
        "Ogohlantirish: Mustaqillik ko'chasidagi ta'mirlash tufayli 8-avtobus 5-10 minutga kechikishi mumkin.";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.black54),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: "Yopish",
            onPressed: () {
              ref.read(delayAlertProvider.notifier).state = null;
              ref.read(socketServiceProvider).resolveDelay();
            },
          ),
        ],
      ),
    );
  }
}
