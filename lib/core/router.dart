import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'storage_service.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/register_screen.dart';
import '../screens/passenger/passenger_shell.dart';
import '../screens/driver/driver_home.dart';
import '../screens/admin/admin_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/' || loc == '/onboarding' || loc == '/register') {
        return null;
      }
      final storage = ref.read(storageServiceProvider);
      if (!storage.isRegistered) {
        return '/register';
      }
      final role = storage.userRole.toUpperCase();
      if (loc == '/admin' && role != 'ADMIN' && role != 'DISPATCHER') {
        return '/passenger';
      }
      if (loc == '/driver' && role != 'DRIVER') {
        return '/passenger';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/register', builder: (_, state) {
        final role = state.uri.queryParameters['role'] ?? 'PASSENGER';
        return RegisterScreen(selectedRole: role);
      }),
      GoRoute(path: '/passenger', builder: (_, __) => const PassengerShell()),
      GoRoute(path: '/driver', builder: (_, __) => const DriverHome()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),
    ],
  );
});
