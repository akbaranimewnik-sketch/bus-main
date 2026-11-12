import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripRouteOption {
  final String routeNumber;
  final String routeName;
  final String startStop;
  final String endStop;
  final int durationMinutes;
  final double distanceKm;
  final int fare;
  final List<String> steps;
  final bool hasTransfer;

  TripRouteOption({
    required this.routeNumber,
    required this.routeName,
    required this.startStop,
    required this.endStop,
    required this.durationMinutes,
    required this.distanceKm,
    required this.fare,
    required this.steps,
    this.hasTransfer = false,
  });
}

final tripPlannerProvider = Provider<TripPlannerService>((ref) => TripPlannerService());

class TripPlannerService {
  static const stopsList = [
    'Vokzal',
    'Markaziy Bozor',
    'Viloyat Hokimligi',
    'Yangi Bozor',
    'Bolalar Shifoxonasi',
    'GulDU Universiteti',
    '3-Mikrorayon',
    'Aeroport',
  ];

  List<TripRouteOption> planTrip(String origin, String destination) {
    if (origin == destination) return [];

    final idx1 = stopsList.indexOf(origin);
    final idx2 = stopsList.indexOf(destination);
    final diff = (idx1 >= 0 && idx2 >= 0) ? (idx1 - idx2).abs() : 2;
    final hopCount = diff == 0 ? 1 : diff;
    final distance = (hopCount * 1.5) + 1.2;
    final duration = (distance * 3).round();

    return [
      TripRouteOption(
        routeNumber: '17',
        routeName: '17-avtobus (Tezkor)',
        startStop: origin,
        endStop: destination,
        durationMinutes: duration,
        distanceKm: double.parse(distance.toStringAsFixed(1)),
        fare: 2000,
        steps: [
          'Bekatgacha 150m piyoda yuring ($origin)',
          '17-avtobusga chiqing (kutilmoqda: 3 daqiqa)',
          '5 ta bekat o\'tib $destination bekatida tushib qoling',
        ],
        hasTransfer: false,
      ),
      TripRouteOption(
        routeNumber: '5 ➔ 8',
        routeName: '5-avtobus ➔ Markaz ➔ 8-avtobus',
        startStop: origin,
        endStop: destination,
        durationMinutes: duration + 8,
        distanceKm: double.parse((distance + 1.2).toStringAsFixed(1)),
        fare: 4000,
        steps: [
          '$origin bekatida 5-avtobusga chiqing',
          'Markaziy Bozor bekatida tushib 8-avtobusga o\'ting (3 daqiqa kutiladi)',
          '$destination bekatida yetib keling',
        ],
        hasTransfer: true,
      ),
    ];
  }

  // Calculate distance in km between two lat/lng points
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Calculate ETA in minutes based on average speed (30 km/h)
  static int calculateETA(double distanceKm, {double avgSpeedKmh = 30.0}) {
    if (avgSpeedKmh <= 0) return 1;
    final timeHours = distanceKm / avgSpeedKmh;
    final mins = (timeHours * 60).round();
    return mins < 1 ? 1 : mins;
  }
}
