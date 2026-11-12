import 'package:flutter/material.dart';

class OccupancyBadge extends StatelessWidget {
  final double pct;
  const OccupancyBadge({super.key, required this.pct});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    if (pct <= 40) {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF047857);
      label = "BO'SH";
    } else if (pct <= 70) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      label = "O'RTACHA";
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      label = 'GAVJUM';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: fg,
          fontSize: 10, 
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
