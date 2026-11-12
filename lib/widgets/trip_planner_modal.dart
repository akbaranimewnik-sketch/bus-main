import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/trip_planner_service.dart';

class TripPlannerModal extends ConsumerStatefulWidget {
  const TripPlannerModal({super.key});

  @override
  ConsumerState<TripPlannerModal> createState() => _TripPlannerModalState();
}

class _TripPlannerModalState extends ConsumerState<TripPlannerModal> {
  String _origin = TripPlannerService.stopsList.first;
  String _destination = TripPlannerService.stopsList[5]; // GulDU
  List<TripRouteOption>? _routes;

  void _calculate() {
    final planner = ref.read(tripPlannerProvider);
    setState(() {
      _routes = planner.planTrip(_origin, _destination);
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.alt_route_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marshrut Tuzuvchi (A -> B)',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  Text(
                    'Eng maqbul va tezkor avtobus yo\'nalishini topish',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Selectors
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                // Origin
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 10),
                    const Text('Qayerdan: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _origin,
                          isExpanded: true,
                          items: TripPlannerService.stopsList.map((stop) {
                            return DropdownMenuItem(
                                value: stop, child: Text(stop));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _origin = val);
                              _calculate();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                // Destination
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    const Text('Qayerga: ',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _destination,
                          isExpanded: true,
                          items: TripPlannerService.stopsList.map((stop) {
                            return DropdownMenuItem(
                                value: stop, child: Text(stop));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _destination = val);
                              _calculate();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Tavsiya etilgan marshrutlar:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary),
          ),

          const SizedBox(height: 10),

          // Routes List
          Expanded(
            child: _routes == null || _routes!.isEmpty
                ? const Center(
                    child:
                        Text('Ushbu yo\'nalish bo\'yicha avtobus topilmadi.'))
                : ListView.builder(
                    itemCount: _routes!.length,
                    itemBuilder: (context, index) {
                      final option = _routes![index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: option.hasTransfer
                                ? Colors.orange.shade200
                                : AppColors.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: option.hasTransfer
                                        ? Colors.orange
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    option.routeNumber,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    option.routeName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '${option.durationMinutes} min',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.accent,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.straighten_rounded,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text('${option.distanceKm} km',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(width: 16),
                                Icon(Icons.payments_outlined,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text('${option.fare} UZS',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                            const Divider(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: option.steps.map((step) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          size: 14, color: AppColors.accent),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          step,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
