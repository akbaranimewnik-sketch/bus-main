import 'package:flutter_test/flutter_test.dart';
import 'package:smartbus_mobile/core/trip_planner_service.dart';
import 'package:smartbus_mobile/core/dropoff_alert_service.dart';

void main() {
  group('TripPlannerService Tests', () {
    final planner = TripPlannerService();

    test('calculateDistance calculates correct distance between coordinates', () {
      // Distance between two points in Guliston (~1-2 km)
      final dist = TripPlannerService.calculateDistance(40.4915, 68.7801, 40.4955, 68.7850);
      expect(dist, greaterThan(0.3));
      expect(dist, lessThan(2.0));
    });

    test('calculateDistance returns 0 for identical points', () {
      final dist = TripPlannerService.calculateDistance(40.4915, 68.7801, 40.4915, 68.7801);
      expect(dist, closeTo(0.0, 0.0001));
    });

    test('calculateETA estimates reasonable time in minutes', () {
      // 5 km at 30 km/h is 10 minutes
      final eta = TripPlannerService.calculateETA(5.0, avgSpeedKmh: 30.0);
      expect(eta, 10);

      // Distance near 0 should return at least 1 minute
      final minEta = TripPlannerService.calculateETA(0.1, avgSpeedKmh: 30.0);
      expect(minEta, greaterThanOrEqualTo(1));
    });

    test('planTrip returns empty when origin equals destination', () {
      final routes = planner.planTrip('Vokzal', 'Vokzal');
      expect(routes.isEmpty, true);
    });

    test('planTrip returns viable route options between distinct stops', () {
      final routes = planner.planTrip('Vokzal', 'GulDU Universiteti');
      expect(routes.length, 2);
      expect(routes.first.startStop, 'Vokzal');
      expect(routes.first.endStop, 'GulDU Universiteti');
      expect(routes.first.durationMinutes, greaterThan(0));
      expect(routes.first.steps.isNotEmpty, true);
    });
  });

  group('DropOffAlertNotifier Tests', () {
    test('DropOffAlertNotifier manages alert state properly', () {
      final notifier = DropOffAlertNotifier();

      expect(notifier.state.isActive, false);
      expect(notifier.state.triggered, false);

      // Set alert
      notifier.setAlert(
        busCode: 'GUL-001',
        stopName: 'GulDU Universiteti',
        targetLat: 40.4880,
        targetLng: 68.7750,
      );

      expect(notifier.state.isActive, true);
      expect(notifier.state.busCode, 'GUL-001');
      expect(notifier.state.stopName, 'GulDU Universiteti');
      expect(notifier.state.triggered, false);

      // Far away check (> 300m)
      notifier.checkLocation(40.5000, 68.8000);
      expect(notifier.state.triggered, false);

      // Near check (< 300m)
      notifier.checkLocation(40.4881, 68.7751);
      expect(notifier.state.triggered, true);

      // Cancel alert resets state
      notifier.cancelAlert();
      expect(notifier.state.isActive, false);
      expect(notifier.state.triggered, false);
    });
  });
}
