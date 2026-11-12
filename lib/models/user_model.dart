class UserModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String username;
  final String role; // 'passenger', 'driver', 'admin'
  final String busCode;
  final String routeName;
  final bool isOnline;
  final DateTime? lastLogin;

  const UserModel({
    required this.id,
    required this.fullName,
    this.phoneNumber = '',
    this.username = '',
    this.role = 'passenger',
    this.busCode = '',
    this.routeName = '',
    this.isOnline = false,
    this.lastLogin,
  });

  bool get isAdmin => role.toLowerCase() == 'admin' || role.toUpperCase() == 'DISPATCHER';
  bool get isDriver => role.toLowerCase() == 'driver';
  bool get isPassenger => role.toLowerCase() == 'passenger';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      fullName: (json['fullName'] ?? 'Foydalanuvchi').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      role: (json['role'] ?? 'passenger').toString(),
      busCode: (json['busCode'] ?? '').toString(),
      routeName: (json['routeName'] ?? '').toString(),
      isOnline: json['isOnline'] == true,
      lastLogin: json['lastLogin'] != null ? DateTime.tryParse(json['lastLogin'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'username': username,
      'role': role,
      'busCode': busCode,
      'routeName': routeName,
      'isOnline': isOnline,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }
}
