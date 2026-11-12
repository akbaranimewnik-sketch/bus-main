class BusModel {
  final String id;
  final String busCode;
  final String routeName;
  final String driverName;
  final double speed;
  final int occupancyPercent;
  final double latitude;
  final double longitude;
  final double dLat;
  final double dLng;
  final String status; // 'ok', 'late', 'sos', 'stopped'
  final int eta;

  const BusModel({
    required this.id,
    required this.busCode,
    required this.routeName,
    required this.driverName,
    this.speed = 0.0,
    this.occupancyPercent = 0,
    required this.latitude,
    required this.longitude,
    this.dLat = 0.0002,
    this.dLng = 0.0003,
    this.status = 'ok',
    this.eta = 5,
  });

  bool get isSos => status == 'sos';
  bool get isLate => status == 'late';

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      id: (json['id'] ?? json['busId'] ?? json['_id'] ?? '').toString(),
      busCode: (json['busCode'] ?? 'GUL-001').toString(),
      routeName: (json['routeName'] ?? '17-avtobus').toString(),
      driverName: (json['driverName'] ?? 'Haydovchi').toString(),
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      occupancyPercent: (json['occupancyPercent'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 40.485,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 68.775,
      dLat: (json['dLat'] as num?)?.toDouble() ?? 0.0002,
      dLng: (json['dLng'] as num?)?.toDouble() ?? 0.0003,
      status: (json['status'] ?? 'ok').toString(),
      eta: (json['eta'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busId': id,
      'busCode': busCode,
      'routeName': routeName,
      'driverName': driverName,
      'speed': speed,
      'occupancyPercent': occupancyPercent,
      'latitude': latitude,
      'longitude': longitude,
      'dLat': dLat,
      'dLng': dLng,
      'status': status,
      'eta': eta,
    };
  }

  BusModel copyWith({
    String? id,
    String? busCode,
    String? routeName,
    String? driverName,
    double? speed,
    int? occupancyPercent,
    double? latitude,
    double? longitude,
    double? dLat,
    double? dLng,
    String? status,
    int? eta,
  }) {
    return BusModel(
      id: id ?? this.id,
      busCode: busCode ?? this.busCode,
      routeName: routeName ?? this.routeName,
      driverName: driverName ?? this.driverName,
      speed: speed ?? this.speed,
      occupancyPercent: occupancyPercent ?? this.occupancyPercent,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dLat: dLat ?? this.dLat,
      dLng: dLng ?? this.dLng,
      status: status ?? this.status,
      eta: eta ?? this.eta,
    );
  }
}
