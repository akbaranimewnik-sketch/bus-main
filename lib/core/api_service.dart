import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(LogInterceptor(responseBody: false));
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String role,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'password': password,
      'role': role,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> login({
    String? phoneNumber,
    String? username,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (username != null) 'username': username,
      'password': password,
    });
    return res.data;
  }

  // ─── Drivers API ───────────────────────────────────────────────────────────

  Future<List<dynamic>> getDrivers() async {
    try {
      final res = await _dio.get('/drivers');
      return res.data['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addDriver({
    required String fullName,
    String? phoneNumber,
    required String username,
    required String password,
    String? busCode,
    String? routeName,
  }) async {
    final res = await _dio.post('/drivers', data: {
      'fullName': fullName,
      'phoneNumber': phoneNumber ?? '',
      'username': username,
      'password': password,
      'busCode': busCode ?? 'GUL-001',
      'routeName': routeName ?? '17-avtobus',
    });
    return res.data;
  }

  Future<void> deleteDriver(String id) async {
    try {
      await _dio.delete('/drivers/$id');
    } catch (_) {}
  }

  // ─── Delay Alert API ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getDelayAlert() async {
    try {
      final res = await _dio.get('/delay-alert');
      return res.data['alert'];
    } catch (_) {
      return null;
    }
  }

  Future<void> reportDelay({
    String? routeName,
    String? busCode,
    String? delayMinutes,
    String? message,
  }) async {
    try {
      await _dio.post('/delay-alert', data: {
        'routeName': routeName ?? '8-avtobus',
        'busCode': busCode ?? 'GUL-003',
        'delayMinutes': delayMinutes ?? '5-10',
        'message': message ?? "Mustaqillik ko'chasidagi ta'mirlash tufayli 8-avtobus 5-10 minutga kechikishi mumkin.",
      });
    } catch (_) {}
  }

  Future<void> resolveDelay() async {
    try {
      await _dio.post('/delay-alert/resolve');
    } catch (_) {}
  }

  // ─── Lost & Found ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getLostItems() async {
    try {
      final res = await _dio.get('/lost-items');
      return res.data['items'] ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> reportLostItem({
    required String title,
    required String description,
    required String busRoute,
    required String passengerName,
    required String passengerPhone,
  }) async {
    try {
      final res = await _dio.post('/lost-items', data: {
        'title': title,
        'description': description,
        'busRoute': busRoute,
        'passengerName': passengerName,
        'passengerPhone': passengerPhone,
      });
      return res.data['item'];
    } catch (_) {
      return null;
    }
  }

  Future<bool> markLostItemFound(String id) async {
    try {
      final res = await _dio.post('/lost-items/$id/found');
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteLostItem(String id) async {
    try {
      final res = await _dio.delete('/lost-items/$id');
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Buses ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getBuses() async {
    try {
      final res = await _dio.get('/buses');
      return res.data['data'] ?? [];
    } catch (_) {
      return _mockBuses;
    }
  }

  // ─── Routes ────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getRoutes() async {
    try {
      final res = await _dio.get('/routes');
      return res.data['data'] ?? [];
    } catch (_) {
      return _mockRoutes;
    }
  }

  // ─── Stops ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getStops() async {
    try {
      final res = await _dio.get('/stops');
      return res.data['data'] ?? [];
    } catch (_) {
      return [];
    }
  }

  // ─── SOS ───────────────────────────────────────────────────────────────────

  Future<void> triggerSOS({
    required String busId,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    await _dio.post('/sos', data: {
      'busId': busId,
      'latitude': latitude ?? AppConstants.gulistonLat,
      'longitude': longitude ?? AppConstants.gulistonLng,
      'description': description ?? 'SOS signal triggered by driver',
    });
  }

  // ─── Reports ───────────────────────────────────────────────────────────────

  Future<void> submitReport({
    required String title,
    required String description,
    String type = 'COMPLAINT',
    String? busId,
  }) async {
    await _dio.post('/reports', data: {
      'title': title,
      'description': description,
      'type': type,
      'busId': busId,
    });
  }

  // ─── Ratings ───────────────────────────────────────────────────────────────

  Future<void> submitRating({
    required String busId,
    required int stars,
    String? comment,
  }) async {
    await _dio.post('/ratings', data: {
      'busId': busId,
      'stars': stars,
      'comment': comment ?? '',
    });
  }

  // ─── Analytics ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final res = await _dio.get('/analytics/dashboard');
      return res.data['data'] ?? {};
    } catch (_) {
      return {};
    }
  }

  // ─── Mock data (offline fallback) ──────────────────────────────────────────

  static final _mockBuses = [
    {'id': '1', 'busCode': 'GUL-001', 'routeName': "17-avtobus", 'speed': 28, 'occupancyPercent': 38, 'latitude': 40.491, 'longitude': 68.778, 'status': 'ok'},
    {'id': '2', 'busCode': 'GUL-002', 'routeName': "5-avtobus", 'speed': 34, 'occupancyPercent': 62, 'latitude': 40.495, 'longitude': 68.783, 'status': 'ok'},
    {'id': '3', 'busCode': 'GUL-003', 'routeName': "8-avtobus", 'speed': 0, 'occupancyPercent': 82, 'latitude': 40.487, 'longitude': 68.771, 'status': 'late'},
    {'id': '4', 'busCode': 'GUL-004', 'routeName': "22-avtobus", 'speed': 45, 'occupancyPercent': 55, 'latitude': 40.499, 'longitude': 68.790, 'status': 'ok'},
    {'id': '5', 'busCode': 'GUL-005', 'routeName': "3-avtobus", 'speed': 12, 'occupancyPercent': 90, 'latitude': 40.483, 'longitude': 68.764, 'status': 'ok'},
  ];    

  static final _mockRoutes = [
    {'id': '1', 'routeNumber': '17', 'name': "Vokzal — Yangi Bozor — GulDU", 'startStopName': 'Vokzal', 'endStopName': 'GulDU', 'distanceKm': 8.2, 'estimatedDurationMin': 22, 'activeBuses': 4},
    {'id': '2', 'routeNumber': '5', 'name': "Markaz — Shifoxona — Mikrorayon", 'startStopName': 'Markaz', 'endStopName': '3-Mikrorayon', 'distanceKm': 6.8, 'estimatedDurationMin': 18, 'activeBuses': 2},
    {'id': '3', 'routeNumber': '8', 'name': "Aeroport — Markaz — Vokzal", 'startStopName': 'Aeroport', 'endStopName': 'Vokzal', 'distanceKm': 12.5, 'estimatedDurationMin': 35, 'activeBuses': 3},
    {'id': '4', 'routeNumber': '22', 'name': "Dehqon Bozori — TTZ — Universitet", 'startStopName': 'Dehqon Bozori', 'endStopName': 'Universitet', 'distanceKm': 9.1, 'estimatedDurationMin': 25, 'activeBuses': 2},
  ];
}
