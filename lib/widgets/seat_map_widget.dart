import 'package:flutter/material.dart';
import '../core/theme.dart';

class SeatMapWidget extends StatelessWidget {
  final double occupancyPct;
  const SeatMapWidget({super.key, required this.occupancyPct});

  @override
  Widget build(BuildContext context) {
    // 20 total seats: green = free, red = occupied, blue = disabled priority
    final occupiedSeats = (20 * (occupancyPct / 100)).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.event_seat_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Avtobus O\'rindiqlar Sxemasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${20 - occupiedSeats} ta bo\'sh o\'rin',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bus cabin representation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Front driver section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sports_motorsports_rounded, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('Haydovchi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                    const Text('🚪 Kirish eshigi', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 16),

                // Seat rows (Left: 2 seats, Gangway, Right: 2 seats)
                Column(
                  children: List.generate(5, (row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left 2 seats
                          Row(
                            children: List.generate(2, (col) {
                              final seatIdx = row * 4 + col;
                              final isOccupied = seatIdx < occupiedSeats;
                              final isDisabled = seatIdx == 0;
                              return _buildSeatItem(isOccupied, isDisabled);
                            }),
                          ),
                          // Gangway / Yo'lakcha
                          const Text('•', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          // Right 2 seats
                          Row(
                            children: List.generate(2, (col) {
                              final seatIdx = row * 4 + 2 + col;
                              final isOccupied = seatIdx < occupiedSeats;
                              return _buildSeatItem(isOccupied, false);
                            }),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          // Legend
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendItem(color: Colors.green, label: 'Bo\'sh'),
              _LegendItem(color: Colors.red, label: 'Band'),
              _LegendItem(color: Colors.blue, label: 'Nogironlar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatItem(bool isOccupied, bool isDisabled) {
    Color seatColor = Colors.green;
    IconData icon = Icons.event_seat_rounded;

    if (isDisabled) {
      seatColor = Colors.blue;
      icon = Icons.accessible_rounded;
    } else if (isOccupied) {
      seatColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: seatColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: seatColor, width: 1.5),
      ),
      child: Icon(icon, color: seatColor, size: 18),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
