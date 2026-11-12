import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/dropoff_alert_service.dart';
import '../core/trip_planner_service.dart';

class DropOffModal extends ConsumerStatefulWidget {
  const DropOffModal({super.key});

  @override
  ConsumerState<DropOffModal> createState() => _DropOffModalState();
}

class _DropOffModalState extends ConsumerState<DropOffModal> {
  String _selectedStop = TripPlannerService.stopsList[1];
  String _selectedBus = '17-avtobus';

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(dropOffAlertProvider);
    final alertNotifier = ref.read(dropOffAlertProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tushish Bekati Eslatmasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Text(
                      'Bekatga 200m qolganda avtomatik ogohlantirish',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (alertState.isActive) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Eslatgich faol: ${alertState.stopName} (${alertState.busCode})',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      alertNotifier.cancelAlert();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Eslatgich o\'chirildi')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                    child: const Text('O\'chirish'),
                  )
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Avtobusni tanlang:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedBus,
                    isExpanded: true,
                    items: ['17-avtobus', '5-avtobus', '8-avtobus', '22-avtobus'].map((bus) {
                      return DropdownMenuItem(value: bus, child: Text(bus));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBus = val!),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tushmoqchi bo\'lgan bekatni tanlang:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedStop,
                    isExpanded: true,
                    items: TripPlannerService.stopsList.map((stop) {
                      return DropdownMenuItem(value: stop, child: Text(stop));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStop = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  alertNotifier.setAlert(
                    busCode: _selectedBus,
                    stopName: _selectedStop,
                    targetLat: 40.495,
                    targetLng: 68.783,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$_selectedStop bekati uchun eslatma yoqildi! 🔔')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.alarm_add_rounded),
                label: const Text('Eslatmani Yoqish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
