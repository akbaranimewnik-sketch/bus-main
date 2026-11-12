import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'occupancy_badge.dart';

class BusCard extends StatelessWidget {
  final Map<String, dynamic>? bus;
  final int index;
  final void Function(Map<String, dynamic>) onTap;

  const BusCard({
    super.key,
    required this.bus,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final busData = bus ?? {
      'busCode': 'GUL-00${index + 1}',
      'routeName': '${index * 4 + 5}-avtobus',
      'eta': index * 3 + 3,
      'occupancyPercent': 45,
    };

    final occ = (busData['occupancyPercent'] ?? 45) as num;

    return GestureDetector(
      onTap: () => onTap(busData),
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        busData['busCode']?.toString().replaceAll('GUL-00', '') ?? '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                OccupancyBadge(pct: occ.toDouble()),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busData['routeName'] ?? 'Avtobus',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${busData['eta'] ?? (index * 3 + 3)} daqiqa',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
