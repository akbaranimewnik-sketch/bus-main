class LostItemModel {
  final String id;
  final String title;
  final String description;
  final String busRoute;
  final String passengerName;
  final String passengerPhone;
  final String status; // 'yoqolgan', 'topildi'
  final DateTime createdAt;
  final DateTime? foundAt;

  LostItemModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.busRoute,
    required this.passengerName,
    required this.passengerPhone,
    this.status = 'yoqolgan',
    DateTime? createdAt,
    this.foundAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isFound => status == 'topildi';

  factory LostItemModel.fromJson(Map<String, dynamic> json) {
    return LostItemModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      busRoute: (json['busRoute'] ?? '17-avtobus').toString(),
      passengerName: (json['passengerName'] ?? 'Yo\'lovchi').toString(),
      passengerPhone: (json['passengerPhone'] ?? '').toString(),
      status: (json['status'] ?? 'yoqolgan').toString(),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      foundAt: json['foundAt'] != null
          ? DateTime.tryParse(json['foundAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'busRoute': busRoute,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'foundAt': foundAt?.toIso8601String(),
    };
  }
}
