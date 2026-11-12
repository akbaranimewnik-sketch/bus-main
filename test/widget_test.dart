import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbus_mobile/main.dart';

void main() {
  testWidgets('SmartBusApp initializes and builds root MaterialApp correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': false,
      'registered': false,
    });

    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const SmartBusApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Verify MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
