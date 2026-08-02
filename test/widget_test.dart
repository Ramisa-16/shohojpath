import 'package:flutter_test/flutter_test.dart';

import 'package:shohojpath/models/reading_settings.dart';
import 'package:shohojpath/theme/reading_surface.dart';
import 'package:shohojpath/utils/bangla_text.dart';

void main() {
  group('BanglaText.split', () {
    test('inserts ZWNJ after the hasant in a conjunct', () {
      expect(BanglaText.split('ক্ষ'), 'ক্‌ষ');
      expect(BanglaText.split('বৃষ্টি'), 'বৃষ্‌টি');
    });

    test('is idempotent', () {
      final once = BanglaText.split('লক্ষ্য');
      expect(BanglaText.split(once), once);
    });

    test('leaves text without conjuncts alone', () {
      expect(BanglaText.split('আমার'), 'আমার');
    });

    test('join undoes split', () {
      expect(BanglaText.join(BanglaText.split('বারান্দার')), 'বারান্দার');
    });

  });

  group('ReadingSettings', () {
    test('recommended preset matches the design config', () {
      final s = ReadingSettings(initialProfile: ReadingProfile.recommended);
      expect(s.fontSize, 22);
      expect(s.wordSpacingEm, 0.16);
      expect(s.lineHeight, 1.8);
      expect(s.letterSpacingEm, 0, reason: 'letter spacing breaks the মাত্রা');
      expect(s.surface, ReadingSurface.cream);
      expect(s.readAloud, isTrue);
    });

    test('default profile is a bare control condition', () {
      final s = ReadingSettings(initialProfile: ReadingProfile.standard);
      expect(s.fontSize, 16);
      expect(s.surface, ReadingSurface.white);
      expect(s.readAloud, isFalse);
      expect(s.highlightConjuncts, isFalse);
      expect(s.readingRuler, isFalse);
    });

    test('em spacing converts to pixels against the current font size', () {
      final s = ReadingSettings(initialProfile: ReadingProfile.recommended);
      expect(s.wordSpacingPx, closeTo(22 * 0.16, 0.0001));
      s.fontSize = 44;
      expect(s.wordSpacingPx, closeTo(44 * 0.16, 0.0001));
    });

    test('font size clamps to 12-72', () {
      final s = ReadingSettings();
      s.fontSize = 999;
      expect(s.fontSize, 72);
      s.fontSize = 1;
      expect(s.fontSize, 12);
    });

    test('editing a value moves the participant into the Custom condition', () {
      final s = ReadingSettings(initialProfile: ReadingProfile.recommended);
      s.fontSize = 30;
      expect(s.profile, ReadingProfile.custom);
    });

    test('applying a preset does not flip the profile to Custom', () {
      final s = ReadingSettings(initialProfile: ReadingProfile.recommended);
      s.applyProfile(ReadingProfile.standard);
      expect(s.profile, ReadingProfile.standard);
      expect(s.fontSize, 16);
    });

    test('custom values survive a round trip through another condition', () {
      final s = ReadingSettings(initialProfile: ReadingProfile.custom);
      s.fontSize = 34;
      s.surface = ReadingSurface.dark;
      s.applyProfile(ReadingProfile.standard);
      expect(s.fontSize, 16);
      s.applyProfile(ReadingProfile.custom);
      expect(s.fontSize, 34);
      expect(s.surface, ReadingSurface.dark);
    });

    test('every change is announced with a timestamp and condition', () {
      final s = ReadingSettings(initialProfile: ReadingProfile.recommended);
      final log = <SettingsChange>[];
      s.addChangeObserver(log.add);

      s.splitConjuncts = true;

      // The profile flip is logged alongside the value change.
      expect(log.map((c) => c.key), ['profile', 'split_conjuncts']);
      expect(log.last.from, false);
      expect(log.last.to, true);
      expect(log.last.profile, ReadingProfile.custom);
    });

    test('setting a value to what it already is logs nothing', () {
      final s = ReadingSettings(initialProfile: ReadingProfile.recommended);
      final log = <SettingsChange>[];
      s.addChangeObserver(log.add);
      s.fontSize = 22;
      expect(log, isEmpty);
      expect(s.profile, ReadingProfile.recommended);
    });

    test('restoreFromMap replays a persisted state without logging', () {
      final source = ReadingSettings(initialProfile: ReadingProfile.custom);
      source.fontSize = 41;
      source.readingRuler = false;

      final restored = ReadingSettings();
      final log = <SettingsChange>[];
      restored.addChangeObserver(log.add);
      restored.restoreFromMap(source.toMap());

      expect(restored.fontSize, 41);
      expect(restored.readingRuler, isFalse);
      expect(restored.profile, ReadingProfile.custom);
      expect(log, isEmpty);
    });

    test('reset returns to the control condition', () {
      final s = ReadingSettings(initialProfile: ReadingProfile.custom);
      s.fontSize = 50;
      s.resetAll();
      expect(s.profile, ReadingProfile.standard);
      expect(s.fontSize, 16);
    });
  });
}
