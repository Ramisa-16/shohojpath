import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:shohojpath/services/tts_service.dart';
import 'package:shohojpath/utils/bangla_text.dart';

/// Drives the real [FlutterTts] over a faked platform channel, so [TtsService]
/// is exercised through the same code path it uses on a device — including the
/// start/complete/progress callbacks, which arrive from the platform side and
/// are where the interesting behaviour lives.
class FakeTtsPlatform {
  FakeTtsPlatform({this.languages = const ['bn-BD', 'en-US']});

  static const MethodChannel _channel = MethodChannel('flutter_tts');
  static const StandardMethodCodec _codec = StandardMethodCodec();

  List<String> languages;

  /// Everything handed to speak(), in order.
  final List<String> spoken = [];
  final List<double> rates = [];
  int stopCalls = 0;
  int pauseCalls = 0;

  /// When false, an utterance hangs until [finishUtterance] or a stop, which
  /// is how a real one behaves: awaitSpeakCompletion(true) makes speak()
  /// resolve on completion *or* cancellation, not on dispatch.
  bool autoComplete = true;

  Completer<void>? _utterance;

  void finishUtterance() {
    final pending = _utterance;
    _utterance = null;
    if (pending != null && !pending.isCompleted) pending.complete();
  }

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'awaitSpeakCompletion':
          return 1;
        case 'getLanguages':
          return languages;
        case 'isLanguageAvailable':
          return languages.contains(call.arguments as String);
        case 'setLanguage':
          return 1;
        case 'setSpeechRate':
          rates.add(call.arguments as double);
          return 1;
        case 'speak':
          final args = call.arguments;
          spoken.add(args is Map ? args['text'] as String : args as String);
          if (autoComplete) {
            await Future<void>.delayed(Duration.zero);
          } else {
            _utterance = Completer<void>();
            await _utterance!.future;
          }
          return 1;
        case 'pause':
          pauseCalls++;
          return 1;
        case 'stop':
          stopCalls++;
          // A real stop cancels the utterance, releasing the awaited speak().
          finishUtterance();
          return 1;
        default:
          return 1;
      }
    });
  }

  void remove() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  Future<void> _send(String method, [Object? arguments]) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      _channel.name,
      _codec.encodeMethodCall(MethodCall(method, arguments)),
      (_) {},
    );
  }

  Future<void> sendStart() => _send('speak.onStart');
  Future<void> sendComplete() => _send('speak.onComplete');

  /// Simulates the engine reporting a word, with offsets into the string it is
  /// currently playing — which after a resume is a suffix of the original.
  Future<void> reportWord(String playing, int start, int end) => _send(
        'speak.onProgress',
        {
          'text': playing,
          'start': '$start',
          'end': '$end',
          'word': playing.substring(start, end),
        },
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTtsPlatform platform;
  late TtsService tts;

  setUp(() {
    platform = FakeTtsPlatform()..install();
    tts = TtsService(engine: FlutterTts());
  });

  // A closure, not a tear-off: `platform.remove` would be resolved here, in
  // main(), before setUp has assigned the late variable.
  tearDown(() => platform.remove());

  group('voice selection', () {
    test('prefers bn-BD', () async {
      platform.languages = ['bn-BD', 'bn-IN', 'en-US'];
      await tts.init();
      expect(tts.locale, 'bn-BD');
      expect(tts.hasBanglaVoice, isTrue);
    });

    test('falls back to bn-IN', () async {
      platform.languages = ['bn-IN', 'en-US'];
      await tts.init();
      expect(tts.locale, 'bn-IN');
    });

    test('falls back to a bare bn tag', () async {
      platform.languages = ['bn', 'en-US'];
      await tts.init();
      expect(tts.locale, 'bn');
    });

    test('falls back to any Bengali locale the device lists', () async {
      // Some OEM engines report underscore tags that match none of the
      // preferred spellings; a voice is still a voice.
      platform.languages = ['bn_BD', 'en-US'];
      await tts.init();
      expect(tts.locale, 'bn_BD');
      expect(tts.hasBanglaVoice, isTrue);
    });

    test('reports no voice when the device has none', () async {
      platform.languages = ['en-US', 'hi-IN'];
      await tts.init();
      expect(tts.hasBanglaVoice, isFalse);
      expect(tts.locale, isNull);
    });

    test('refuses to speak without a voice, rather than pretending', () async {
      platform.languages = ['en-US'];
      await tts.speak('একদিন সকালে');
      expect(platform.spoken, isEmpty);
    });
  });

  group('speaking', () {
    test('hands the engine exactly the text it was given', () async {
      const paragraph = 'ছোট্ট পাখি বারান্দার কোণে';
      await tts.speak(paragraph);
      expect(platform.spoken.single, paragraph);
    });

    test('never receives display-transformed text from its own pipeline', () {
      // Guards the contract documented on speak(): offsets are only meaningful
      // against the original, so a ZWNJ-split string must never be passed in.
      const paragraph = 'ছোট্ট পাখি';
      expect(paragraph.contains(BanglaText.zwnj), isFalse);
      expect(BanglaText.split(paragraph).contains(BanglaText.zwnj), isTrue);
    });

    test('ignores empty text', () async {
      await tts.speak('   ');
      expect(platform.spoken, isEmpty);
    });

    test('applies the study rate against the Android baseline', () async {
      await tts.speak('একদিন', rate: 0.75);
      expect(platform.rates.last, closeTo(0.75 * 0.5, 0.0001));
      await tts.speak('একদিন', rate: 1.25);
      expect(platform.rates.last, closeTo(1.25 * 0.5, 0.0001));
    });

    test('stops anything already playing before starting', () async {
      await tts.speak('প্রথম');
      final before = platform.stopCalls;
      await tts.speak('দ্বিতীয়');
      expect(platform.stopCalls, greaterThan(before));
    });
  });

  group('word progress offsets', () {
    test('are exposed against the text handed to speak', () async {
      platform.autoComplete = false;
      const paragraph = 'ছোট্ট পাখি';
      unawaited(tts.speak(paragraph));
      await Future<void>.delayed(Duration.zero);
      await platform.sendStart();

      await platform.reportWord(paragraph, 6, 10);

      expect(tts.wordStart, 6);
      expect(tts.wordEnd, 10);
      expect(paragraph.substring(6, 10), 'পাখি');
    });

    test('are re-based after a pause and resume', () async {
      platform.autoComplete = false;
      const paragraph = 'ছোট্ট পাখি বারান্দার কোণে';
      unawaited(tts.speak(paragraph));
      await Future<void>.delayed(Duration.zero);
      await platform.sendStart();

      // Engine reports "পাখি" at 6..10 of the full paragraph.
      await platform.reportWord(paragraph, 6, 10);
      await tts.pause();
      expect(tts.isPaused, isTrue);
      expect(platform.pauseCalls, 1);

      // Not awaited: resume() awaits the utterance itself, so it only returns
      // once playback finishes — same as speak().
      unawaited(tts.resume());
      await Future<void>.delayed(Duration.zero);
      expect(tts.isSpeaking, isTrue,
          reason: 'state must flip when playback starts, not when it ends');
      expect(tts.isPaused, isFalse);

      // The plugin resumes from its own remembered remainder, so its offsets
      // restart at zero; the service must add the consumed offset back on.
      final remainder = paragraph.substring(6);
      await platform.reportWord(remainder, 5, 14);

      expect(tts.wordStart, 11);
      expect(tts.wordEnd, 20);
      expect(paragraph.substring(11, 20), 'বারান্দার');
    });

    test('are cleared on stop', () async {
      platform.autoComplete = false;
      const paragraph = 'ছোট্ট পাখি';
      unawaited(tts.speak(paragraph));
      await Future<void>.delayed(Duration.zero);
      await platform.sendStart();
      await platform.reportWord(paragraph, 6, 10);
      expect(tts.wordStart, isNotNull);

      await tts.stop();

      expect(tts.wordStart, isNull);
      expect(tts.wordEnd, isNull);
      expect(tts.isSpeaking, isFalse);
      expect(tts.isPaused, isFalse);
    });

    test('pause does nothing when nothing is speaking', () async {
      await tts.init();
      await tts.pause();
      expect(platform.pauseCalls, 0);
      expect(tts.isPaused, isFalse);
    });
  });

  group('spoken duration', () {
    test('accumulates only while actually speaking', () async {
      platform.autoComplete = false;
      unawaited(tts.speak('একদিন সকালে'));
      await Future<void>.delayed(Duration.zero);

      expect(tts.totalSpokenDuration, Duration.zero,
          reason: 'clock must not run before the engine starts');

      await platform.sendStart();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await platform.sendComplete();

      final elapsed = tts.totalSpokenDuration;
      expect(elapsed, greaterThan(Duration.zero));

      // Stopped: no further accumulation once the utterance finished.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(tts.totalSpokenDuration, elapsed);
    });

    test('reset zeroes it for the next session', () async {
      platform.autoComplete = false;
      unawaited(tts.speak('একদিন'));
      await Future<void>.delayed(Duration.zero);
      await platform.sendStart();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await platform.sendComplete();
      expect(tts.totalSpokenDuration, greaterThan(Duration.zero));

      tts.resetSpokenDuration();

      expect(tts.totalSpokenDuration, Duration.zero);
    });
  });
}
