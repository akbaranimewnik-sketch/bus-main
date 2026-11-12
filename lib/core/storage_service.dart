import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'constants.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

class StorageService {
  final SharedPreferences _prefs;
  StorageService(this._prefs);

  // ─── Role ─────────────────────────────────────────────────────────────────
  String get userRole => _prefs.getString(AppConstants.keyUserRole) ?? '';
  Future<void> setUserRole(String role) => _prefs.setString(AppConstants.keyUserRole, role);

  // ─── Token ────────────────────────────────────────────────────────────────
  String get token => _prefs.getString(AppConstants.keyUserToken) ?? '';
  Future<void> setToken(String t) => _prefs.setString(AppConstants.keyUserToken, t);

  // ─── User info ────────────────────────────────────────────────────────────
  String get userName => _prefs.getString(AppConstants.keyUserName) ?? '';
  Future<void> setUserName(String name) => _prefs.setString(AppConstants.keyUserName, name);

  String get userPhone => _prefs.getString(AppConstants.keyUserPhone) ?? '';
  Future<void> setUserPhone(String phone) => _prefs.setString(AppConstants.keyUserPhone, phone);

  // ─── Onboarding ───────────────────────────────────────────────────────────
  bool get onboardingDone => _prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(AppConstants.keyOnboardingDone, true);

  // ─── Registered ───────────────────────────────────────────────────────────
  bool get isRegistered => _prefs.getBool(AppConstants.keyRegistered) ?? false;
  Future<void> setRegistered() => _prefs.setBool(AppConstants.keyRegistered, true);

  // ─── Favorites ────────────────────────────────────────────────────────────
  List<String> get favorites => _prefs.getStringList('favorites') ?? [];
  Future<void> setFavorites(List<String> list) => _prefs.setStringList('favorites', list);

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
