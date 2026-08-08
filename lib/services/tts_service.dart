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
  /// readers — then bn-IN, then a bare language tag. If none of those report
  /// as available, [init] falls back to whatever Bengali voice the device
  /// actually lists, since some OEMs install a voice under a locale tag none
  /// of the above match exactly.
  static const List<String> _preferredLocales = ['bn-BD', 'bn-IN', 'bn'];

  bool _initialised = false;
  String? _locale;
  bool _speaking = false;
  bool _paused = false;

  /// The full text passed to the current/most recent [speak] call. Resuming
  /// after [pause] must hand this exact string back to the platform plugin —
  /// it is what lets the plugin recognise the call as a resume and substitute
  /// its own remembered remainder, rather than starting over.
  String? _fullText;

  /// How much of [_fullText] (in UTF-16 code units) was already spoken before
  /// the *current* speak cycle began. [_wordStart] / [_wordEnd] are reported
  /// by the plugin relative to whatever substring is currently playing, which
  /// after a resume is a suffix of [_fullText] — this offset re-bases them
  /// back to absolute positions in [_fullText] so a caller never has to know
  /// about pause/resume internals.
  int _consumedOffset = 0;

  int? _wordStart;
  int? _wordEnd;

  /// Cumulative time actually spent speaking since the last
  /// [resetSpokenDuration] — a plain [Stopwatch] gives exactly this for
  /// free: `start()`/`stop()` pause and resume accumulation across however
  /// many speak/pause/resume cycles happen in between, without the caller
  /// having to sum durations by hand.
  final Stopwatch _speakingClock = Stopwatch();

  bool get isInitialised => _initialised;
  bool get isSpeaking => _speaking;
  bool get isPaused => _paused;

  /// The locale actually in use, or null if no Bangla voice was found.
  String? get locale => _locale;

  bool get hasBanglaVoice => _locale != null;

  /// Start of the word currently being spoken, as an absolute offset into the
  /// text last passed to [speak]. Null when nothing has been spoken yet.
  int? get wordStart => _wordStart;

  /// One past the end of the word currently being spoken, same coordinate
  /// space as [wordStart].
  int? get wordEnd => _wordEnd;

  /// Total time actually spent speaking since the last [resetSpokenDuration]
  /// — the "audio duration" the study logs alongside whether read-aloud was
  /// merely switched on. Includes conjunct-teaching taps as well as the main
  /// passage narration: both play through this same engine while a reading
  /// session is open, and both are audio support the reader received during
  /// it.
  Duration get totalSpokenDuration => _speakingClock.elapsed;

  /// Zeroes the spoken-duration clock — call this when a new reading session
  /// starts so its total isn't inherited from whatever was read before.
  void resetSpokenDuration() {
    _speakingClock
      ..stop()
      ..reset();
  }

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

      if (_locale == null) {
        final languages = await _tts.getLanguages;
        if (languages is List) {
          for (final entry in languages) {
            final code = entry.toString();
            if (code.toLowerCase().startsWith('bn')) {
              await _tts.setLanguage(code);
              _locale = code;
              break;
            }
          }
        }
      }

      _tts.setStartHandler(() {
        _speaking = true;
        _paused = false;
        _speakingClock.start();
        notifyListeners();
      });
      _tts.setCompletionHandler(() {
        _speaking = false;
        _paused = false;
        _speakingClock.stop();
        _resetProgress();
        notifyListeners();
      });
      _tts.setCancelHandler(() {
        _speaking = false;
        _paused = false;
        _speakingClock.stop();
        _resetProgress();
        notifyListeners();
      });
      _tts.setPauseHandler(() {
        _speaking = false;
        _paused = true;
        _speakingClock.stop();
        notifyListeners();
      });
      _tts.setContinueHandler(() {
        _speaking = true;
        _paused = false;
        _speakingClock.start();
        notifyListeners();
      });
      _tts.setErrorHandler((message) {
        _speaking = false;
        _paused = false;
        _speakingClock.stop();
        _resetProgress();
        debugPrint('TTS error: $message');
        notifyListeners();
      });
      _tts.setProgressHandler((text, start, end, word) {
        _wordStart = _consumedOffset + start;
        _wordEnd = _consumedOffset + end;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('TTS init failed: $e');
      _locale = null;
    }

    notifyListeners();
  }

  void _resetProgress() {
    _fullText = null;
    _consumedOffset = 0;
    _wordStart = null;
    _wordEnd = null;
  }

  /// Speaks [text] from the beginning, at the participant's chosen rate.
  ///
  /// [rate] is the study-facing multiplier (0.75 / 1.0 / 1.25). Android's
  /// engine treats 1.0 as roughly double natural pace, so the multiplier is
  /// applied against a 0.5 baseline to make "1x" mean normal speech.
  ///
  /// Always pass the ORIGINAL passage text here, never the ZWNJ-split or
  /// syllable-dotted display text — [wordStart] / [wordEnd] are only
  /// meaningful against the text actually handed to the engine, and every
  /// caller downstream (conjunct offsets, the display mapping) works in
  /// original-text coordinates.
  Future<void> speak(String text, {double rate = 1.0}) async {
    if (text.trim().isEmpty) return;
    await init();
    if (!hasBanglaVoice) return;

    try {
      await _tts.stop();
      _fullText = text;
      _consumedOffset = 0;
      _wordStart = null;
      _wordEnd = null;
      _paused = false;
      await _tts.setSpeechRate((rate * 0.5).clamp(0.1, 1.0));
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      _speaking = false;
      notifyListeners();
    }
  }

  /// Pauses mid-utterance. [resume] continues from here rather than
  /// restarting, as long as nothing else calls [speak] or [stop] in between.
  Future<void> pause() async {
    if (!_speaking) return;
    // The plugin truncates its own remembered remainder to what is left
    // un-spoken at the moment of the native pause call, so the next resume's
    // reported offsets restart from 0 — capture the absolute position now so
    // future progress events can be re-based against it.
    _consumedOffset = _wordStart ?? _consumedOffset;
    try {
      await _tts.pause();
    } catch (e) {
      debugPrint('TTS pause failed: $e');
      return;
    }
    _speaking = false;
    _paused = true;
    notifyListeners();
  }

  /// Resumes a paused utterance from where it left off.
  Future<void> resume() async {
    if (!_paused || _fullText == null) return;

    // Flipped before the await, not after: [init] turns on
    // awaitSpeakCompletion, so `_tts.speak` does not resolve until the
    // utterance *finishes*. Assigning the state afterwards would set
    // `_speaking = true` at the moment playback ended — leaving the play/pause
    // button stuck showing "pause" for the rest of the session.
    _speaking = true;
    _paused = false;
    notifyListeners();

    try {
      // Handing the plugin the same full text it originally received is what
      // it uses to recognise this as a resume rather than a new utterance.
      await _tts.speak(_fullText!);
    } catch (e) {
      debugPrint('TTS resume failed: $e');
      _speaking = false;
      _paused = true;
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
    _paused = false;
    _resetProgress();
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
