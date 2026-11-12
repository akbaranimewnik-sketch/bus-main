import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier() : super(true) {
    _init();
  }

  void _init() {
    // Initial check
    checkConnection();

    // Listen to network interface changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _evaluateResults(results);
    });
  }

  Future<void> _evaluateResults(List<ConnectivityResult> results) async {
    final hasInterface = results.any((r) => r != ConnectivityResult.none);
    if (!hasInterface) {
      state = false;
      return;
    }
    // Network interface is available; verify internet reachability
    final hasNet = await _pingInternet();
    state = hasNet;
  }

  /// Pings reliable public servers to confirm real internet access
  Future<bool> _pingInternet() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) return false;
    } catch (_) {}

    // 1. Fast DNS lookup on native platforms
    if (!kIsWeb) {
      try {
        final res = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        if (res.isNotEmpty && res[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}
    }

    // 2. Android standard 204 captive portal check
    try {
      final res = await _dio.get(
        'https://clients3.google.com/generate_204',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (res.statusCode != null && res.statusCode! < 500) {
        return true;
      }
    } catch (_) {}

    // 3. Fallback: If device has active mobile or wifi connection,
    // trust interface status so user is NEVER falsely locked out!
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  /// Manually trigger a connectivity check (e.g. on "Qayta urinish" click)
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        state = false;
        return false;
      }
      final online = await _pingInternet();
      state = online;
      return online;
    } catch (_) {
      state = true;
      return true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
