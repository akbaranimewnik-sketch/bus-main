class RouteModel {
  final String id;
  final String routeNumber;
  final String name;
  final String startStopName;
  final String endStopName;
  final double distanceKm;
  final int estimatedDurationMin;
  final int activeBuses;

  const RouteModel({
    required this.id,
    required this.routeNumber,
    required this.name,
    required this.startStopName,
    required this.endStopName,
    this.distanceKm = 0.0,
    this.estimatedDurationMin = 20,
    this.activeBuses = 1,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      routeNumber: (json['routeNumber'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      startStopName: (json['startStopName'] ?? '').toString(),
      endStopName: (json['endStopName'] ?? '').toString(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMin: (json['estimatedDurationMin'] as num?)?.toInt() ?? 20,
      activeBuses: (json['activeBuses'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeNumber': routeNumber,
      'name': name,
      'startStopName': startStopName,
      'endStopName': endStopName,
      'distanceKm': distanceKm,
      'estimatedDurationMin': estimatedDurationMin,
      'activeBuses': activeBuses,
    };
  }
}
