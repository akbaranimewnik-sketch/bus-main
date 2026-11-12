import 'sound_service_stub.dart'
    if (dart.library.js) 'sound_service_web.dart';

class SoundService {
  static void playSmsSound() {
    try {
      playWebSmsSound();
    } catch (e) {
      // Sound playback silent fallback
    }
  }
}
