import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

final aiAssistantProvider = StateNotifierProvider<AiAssistantNotifier, List<ChatMessage>>((ref) {
  return AiAssistantNotifier();
});

class AiAssistantNotifier extends StateNotifier<List<ChatMessage>> {
  AiAssistantNotifier()
      : super([
          ChatMessage(
            text: "Salom! Men SmartBus AI Yordamchisiman. 🤖\nQaysi avtobus yoki bekat haqida ma'lumot kerak?",
            isUser: false,
            time: DateTime.now(),
          )
        ]);

  void sendMessage(String userMsg) {
    final now = DateTime.now();
    final userMessage = ChatMessage(text: userMsg, isUser: true, time: now);
    state = [...state, userMessage];

    // Generate AI response
    final query = userMsg.toLowerCase();
    String aiResponse = "";

    if (query.contains('5') || query.contains('besh')) {
      aiResponse = "5-avtobus Markaziy Bozor bekatiga 4 daqiqadan so'ng yetib keladi. Hozirgi bandlik darajasi 45% (O'rtacha).";
    } else if (query.contains('17') || query.contains('vokzal') || query.contains('guldu')) {
      aiResponse = "17-avtobus Vokzaldan GulDU Universitetigacha harakatlanadi. Tizimda 4 ta avtobus faol xizmat ko'rsatmoqda.";
    } else if (query.contains('chipta') || query.contains('nfc') || query.contains('to\'lov') || query.contains('tolov')) {
      aiResponse = "SmartBus Hamyoni orqali QR chipta yaratib validatorga tekkizishingiz yoki Virtual Humo Transport Kartangizdan foydalanishingiz mumkin.";
    } else if (query.contains('salom') || query.contains('assalomu')) {
      aiResponse = "Assalomu alaykum! SmartBus Guliston ilovasiga xush kelibsiz. Qayerga borishni rejalashtirmoqdasiz?";
    } else {
      aiResponse = "'$userMsg' bo'yicha ma'lumot: Barcha avtobuslar harakat jadvali bo'yicha harakatlanmoqda. Tavsiya: Marshrut (A → B) tugmasini bosing.";
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      state = [
        ...state,
        ChatMessage(text: aiResponse, isUser: false, time: DateTime.now())
      ];
    });
  }
}
