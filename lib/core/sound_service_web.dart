// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, avoid_print
import 'dart:js' as js;

void playWebSmsSound() {
  try {
    if (js.context.hasProperty('playSmsChime')) {
      js.context.callMethod('playSmsChime');
      return;
    }

    final audioCtxClass = js.context['AudioContext'] ?? js.context['webkitAudioContext'];
    if (audioCtxClass != null) {
      final audioCtx = js.JsObject(audioCtxClass);
      if (audioCtx.hasProperty('state') && audioCtx['state'] == 'suspended') {
        audioCtx.callMethod('resume');
      }
      final now = audioCtx['currentTime'] as num;

      // Note 1: 587.33 Hz (D5)
      final osc1 = audioCtx.callMethod('createOscillator') as js.JsObject;
      final gain1 = audioCtx.callMethod('createGain') as js.JsObject;
      osc1['type'] = 'sine';
      (osc1['frequency'] as js.JsObject).callMethod('setValueAtTime', [587.33, now]);
      (gain1['gain'] as js.JsObject).callMethod('setValueAtTime', [0.25, now]);
      (gain1['gain'] as js.JsObject).callMethod('exponentialRampToValueAtTime', [0.001, now + 0.18]);
      osc1.callMethod('connect', [gain1]);
      gain1.callMethod('connect', [audioCtx['destination']]);
      osc1.callMethod('start', [now]);
      osc1.callMethod('stop', [now + 0.18]);

      // Note 2: 880.0 Hz (A5) - melodic pleasant chime
      final osc2 = audioCtx.callMethod('createOscillator') as js.JsObject;
      final gain2 = audioCtx.callMethod('createGain') as js.JsObject;
      osc2['type'] = 'sine';
      (osc2['frequency'] as js.JsObject).callMethod('setValueAtTime', [880.0, now + 0.13]);
      (gain2['gain'] as js.JsObject).callMethod('setValueAtTime', [0.3, now + 0.13]);
      (gain2['gain'] as js.JsObject).callMethod('exponentialRampToValueAtTime', [0.001, now + 0.45]);
      osc2.callMethod('connect', [gain2]);
      gain2.callMethod('connect', [audioCtx['destination']]);
      osc2.callMethod('start', [now + 0.13]);
      osc2.callMethod('stop', [now + 0.45]);
    }
  } catch (e) {
    print('SoundService audio error: $e');
  }
}
