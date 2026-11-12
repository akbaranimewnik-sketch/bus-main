import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trip_planner_service.dart';

class DropOffAlertState {
  final bool isActive;
  final String? busCode;
  final String? stopName;
  final double? targetLat;
  final double? targetLng;
  final bool triggered;

  DropOffAlertState({
    this.isActive = false,
    this.busCode,
    this.stopName,
    this.targetLat,
    this.targetLng,
    this.triggered = false,
  });

  DropOffAlertState copyWith({
    bool? isActive,
    String? busCode,
    String? stopName,
    double? targetLat,
    double? targetLng,
    bool? triggered,
  }) {
    return DropOffAlertState(
      isActive: isActive ?? this.isActive,
      busCode: busCode ?? this.busCode,
      stopName: stopName ?? this.stopName,
      targetLat: targetLat ?? this.targetLat,
      targetLng: targetLng ?? this.targetLng,
      triggered: triggered ?? this.triggered,
    );
  }
}

final dropOffAlertProvider = StateNotifierProvider<DropOffAlertNotifier, DropOffAlertState>((ref) {
  return DropOffAlertNotifier();
});

class DropOffAlertNotifier extends StateNotifier<DropOffAlertState> {
  DropOffAlertNotifier() : super(DropOffAlertState());

  void setAlert({
    required String busCode,
    required String stopName,
    required double targetLat,
    required double targetLng,
  }) {
    state = DropOffAlertState(
      isActive: true,
      busCode: busCode,
      stopName: stopName,
      targetLat: targetLat,
      targetLng: targetLng,
      triggered: false,
    );
  }

  void cancelAlert() {
    state = DropOffAlertState();
  }

  void checkLocation(double currentLat, double currentLng) {
    if (!state.isActive || state.triggered || state.targetLat == null || state.targetLng == null) {
      return;
    }

    final distanceKm = TripPlannerService.calculateDistance(
      currentLat,
      currentLng,
      state.targetLat!,
      state.targetLng!,
    );

    // If within ~300 meters (0.3 km)
    if (distanceKm <= 0.3) {
      state = state.copyWith(triggered: true);
    }
  }

  void dismissTriggered() {
    state = DropOffAlertState();
  }
}
