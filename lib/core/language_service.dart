import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { uz, ru, en }

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.uz);

  void setLanguage(AppLanguage lang) {
    state = lang;
  }

  String getText(String key) {
    final Map<String, Map<AppLanguage, String>> strings = {
      'app_title': {
        AppLanguage.uz: 'SmartBus Guliston',
        AppLanguage.ru: 'SmartBus Гулистан',
        AppLanguage.en: 'SmartBus Guliston',
      },
      'greeting': {
        AppLanguage.uz: 'Salom',
        AppLanguage.ru: 'Привет',
        AppLanguage.en: 'Hello',
      },
      'search_hint': {
        AppLanguage.uz: 'Bekat yoki yo\'nalish qidirish...',
        AppLanguage.ru: 'Поиск остановки или маршрута...',
        AppLanguage.en: 'Search stop or route...',
      },
      'live_buses': {
        AppLanguage.uz: 'liniyada',
        AppLanguage.ru: 'в линии',
        AppLanguage.en: 'live',
      },
      'trip_planner': {
        AppLanguage.uz: 'Marshrut tuzish (A -> B)',
        AppLanguage.ru: 'Планировщик (A -> B)',
        AppLanguage.en: 'Trip Planner (A -> B)',
      },
      'wallet': {
        AppLanguage.uz: 'Hamyon & QR Chipta',
        AppLanguage.ru: 'Кошелек & QR Билет',
        AppLanguage.en: 'Wallet & QR Ticket',
      },
      'dropoff_alert': {
        AppLanguage.uz: 'Tushish bekati eslatmasi',
        AppLanguage.ru: 'Напоминание об остановке',
        AppLanguage.en: 'Drop-off Stop Alert',
      },
      'weather_clear': {
        AppLanguage.uz: 'Guliston: 24°C, Quyoshli, Yo\'llar ochiq',
        AppLanguage.ru: 'Гулистан: 24°C, Ясно, Дороги свободны',
        AppLanguage.en: 'Guliston: 24°C, Sunny, Clear roads',
      },
    };

    if (strings.containsKey(key) && strings[key]!.containsKey(state)) {
      return strings[key]![state]!;
    }
    return key;
  }
}
