import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Bangla text-to-speech.
///
/// Audio support is the one intervention the literature backs strongly —
/// dyslexia is a phonological difficulty, so this is the feature most likely to
/// carry an effect. That makes it worth failing loudly: if the handset has no
/// Bangla voice installed, [hasBanglaVoice] goes false and the UI must say so,
/// because a play button that silently does nothing would be recorded as
/// "audio support on" in the session log and quietly corrupt the data.
class TtsService extends ChangeNotifier {
  TtsService({FlutterTts? engine}) : _tts = engine ?? FlutterTts();

  final FlutterTts _tts;

  /// Locales tried in order. bn-BD first — the study is with Bangladeshi
  /// readers — then bn-IN, then a bare language tag.
  static const List<String> _preferredLocales = ['bn-BD', 'bn-IN', 'bn'];

  bool _initialised = false;
  String? _locale;
  bool _speaking = false;

  bool get isInitialised => _initialised;
  bool get isSpeaking => _speaking;

  /// The locale actually in use, or null if no Bangla voice was found.
  String? get locale => _locale;

  bool get hasBanglaVoice => _locale != null;

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      await _tts.awaitSpeakCompletion(true);

      for (final candidate in _preferredLocales) {
        final available = await _tts.isLanguageAvailable(candidate);
        if (available == true) {
          await _tts.setLanguage(candidate);
          _locale = candidate;
          break;
        }
      }

      _tts.setStartHandler(() {
        _speaking = true;
        notifyListeners();
      });
      _tts.setCompletionHandler(() {
        _speaking = false;
        notifyListeners();
      });
      _tts.setCancelHandler(() {
        _speaking = false;
        notifyListeners();
      });
      _tts.setErrorHandler((message) {
        _speaking = false;
        debugPrint('TTS error: $message');
        notifyListeners();
      });
    } catch (e) {
      debugPrint('TTS init failed: $e');
      _locale = null;
    }

    notifyListeners();
  }

  /// Speaks [text] at the participant's chosen rate.
  ///
  /// [rate] is the study-facing multiplier (0.75 / 1.0 / 1.25). Android's
  /// engine treats 1.0 as roughly double natural pace, so the multiplier is
  /// applied against a 0.5 baseline to make "1x" mean normal speech.
  Future<void> speak(String text, {double rate = 1.0}) async {
    if (text.trim().isEmpty) return;
    await init();
    if (!hasBanglaVoice) return;

    try {
      await _tts.stop();
      await _tts.setSpeechRate((rate * 0.5).clamp(0.1, 1.0));
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      _speaking = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TTS stop failed: $e');
    }
    _speaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
