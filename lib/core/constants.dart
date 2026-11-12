import 'package:flutter/foundation.dart';

class AppConstants {
  // Configurable backend host (allows real device testing via LAN or custom IP)
  static String? _customHost;
  static void setCustomHost(String? host) => _customHost = host;

  static String get serverHost {
    if (_customHost != null && _customHost!.isNotEmpty) {
      return _customHost!;
    }
    const envHost = String.fromEnvironment('BACKEND_HOST');
    if (envHost.isNotEmpty) {
      return envHost;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2:3000';
    }
    return 'localhost:3000';
  }

  // Backend API base URL
  static String get apiBase => 'http://$serverHost/api';

  // Backend Socket.IO base URL
  static String get socketUrl => 'http://$serverHost';

  // Storage keys
  static const keyUserRole = 'user_role';
  static const keyUserToken = 'user_token';
  static const keyUserName = 'user_name';
  static const keyUserPhone = 'user_phone';
  static const keyOnboardingDone = 'onboarding_done';
  static const keyRegistered = 'registered';

  // Map
  static const gulistonLat = 40.34;
  static const gulistonLng = 68.7813;
  static const mapZoom = 14.0;

  // OpenStreetMap tile URL (no API key needed!)
  static const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
