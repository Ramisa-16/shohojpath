import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shohojpath/l10n/app_language.dart';
import 'package:shohojpath/l10n/app_strings.dart';
import 'package:shohojpath/services/app_config_repository.dart';

/// The language toggle in Settings was a bool living in that screen's State:
/// it moved the highlight and changed nothing. These cover the real one.
class _FakeConfig implements AppConfigRepository {
  final Map<String, String> store = {};

  @override
  Future<String?> get(String key) async => store[key];

  @override
  Future<void> set(String key, String value) async => store[key] = value;
}

void main() {
  test('Bangla is the default', () {
    // The participants are Bangladeshi children of about eleven. An English
    // interface would put a second reading task on top of the measured one.
    expect(LanguageState(config: _FakeConfig()).language, AppLanguage.bangla);
    expect(LanguageState(config: _FakeConfig()).isBangla, isTrue);
  });

  test('selecting a language persists it', () async {
    final config = _FakeConfig();
    final state = LanguageState(config: config);

    await state.select(AppLanguage.english);

    expect(state.language, AppLanguage.english);
    expect(config.store[LanguageState.storageKey], 'en');
  });

  test('the choice survives a restart', () async {
    final config = _FakeConfig();
    await LanguageState(config: config).select(AppLanguage.english);

    final relaunched = LanguageState(config: config);
    await relaunched.restore();

    expect(relaunched.language, AppLanguage.english);
  });

  test('an unreadable preference falls back to Bangla rather than throwing',
      () async {
    final config = _FakeConfig()..store[LanguageState.storageKey] = 'klingon';
    final state = LanguageState(config: config);

    await state.restore();

    expect(state.language, AppLanguage.bangla);
  });

  test('a storage failure does not stop the language changing on screen',
      () async {
    final state = LanguageState(config: _BrokenConfig());

    await state.select(AppLanguage.english);

    // The switch already happened for the person looking at it; persisting is
    // bookkeeping for next launch.
    expect(state.language, AppLanguage.english);
  });

  test('each language is labelled in its own script', () {
    // Someone looking for Bangla should not have to read English to find it.
    expect(AppLanguage.bangla.label, 'বাংলা');
    expect(AppLanguage.english.label, 'English');
  });

  test('strings actually differ between the two', () {
    const bn = AppStrings(AppLanguage.bangla);
    const en = AppStrings(AppLanguage.english);

    expect(bn.startReading, 'পড়া শুরু করুন');
    expect(en.startReading, 'Start Reading');
    expect(bn.nextQuestion, isNot(en.nextQuestion));
    expect(bn.answerCorrect, isNot(en.answerCorrect));
  });

  test('no Bangla string was left as its English original', () {
    // A getter that returns the same text in both languages is almost always
    // a translation someone forgot, not a word that happens to be identical.
    const bn = AppStrings(AppLanguage.bangla);
    const en = AppStrings(AppLanguage.english);

    final untranslated = <String>[];
    void check(String name, String b, String e) {
      if (b == e) untranslated.add('$name: "$b"');
    }

    check('startReading', bn.startReading, en.startReading);
    check('readingLibrary', bn.readingLibrary, en.readingLibrary);
    check('comprehension', bn.comprehension, en.comprehension);
    check('nextQuestion', bn.nextQuestion, en.nextQuestion);
    check('changePassword', bn.changePassword, en.changePassword);
    check('logOut', bn.logOut, en.logOut);
    check('offlineBanner', bn.offlineBanner, en.offlineBanner);
    check('answerRevealed', bn.answerRevealed, en.answerRevealed);

    expect(untranslated, isEmpty);
  });

  test('one feature has one name in Bangla', () {
    // Read-aloud was called three different things: শব্দ সহায়তা on the quiz
    // strip, পড়ে শোনানো in settings, and শব্দ বন্ধ on the session list —
    // which reads as "word stopped" as much as "audio off". A reader cannot
    // tell three names for one feature from three features.
    final strings = File('lib/l10n/app_strings.dart').readAsStringSync();

    expect(
      strings.contains('শব্দ সহায়তা'),
      isFalse,
      reason: 'read-aloud is called পড়ে শোনানো everywhere',
    );
    expect(strings.contains('শব্দ বন্ধ'), isFalse);
    expect(strings.contains('শব্দ চালু'), isFalse);

    const bn = AppStrings(AppLanguage.bangla);
    for (final s in [bn.readAloudLabel, bn.audioOnShort, bn.audioOffShort,
                     bn.readAloudUsed, bn.readAloudSection]) {
      expect(s, contains('পড়ে শোনানো'), reason: '"$s" uses another name');
    }
  });

  testWidgets('the whole screen re-reads when the language changes',
      (tester) async {
    final state = LanguageState(config: _FakeConfig());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          home: Builder(builder: (context) => Text(context.t.startReading)),
        ),
      ),
    );

    expect(find.text('পড়া শুরু করুন'), findsOneWidget);

    // context.t watches, so switching rebuilds every screen holding one —
    // no restart, and no screen left in the language it was built in.
    await state.select(AppLanguage.english);
    await tester.pumpAndSettle();

    expect(find.text('Start Reading'), findsOneWidget);
    expect(find.text('পড়া শুরু করুন'), findsNothing);
  });
}

class _BrokenConfig implements AppConfigRepository {
  @override
  Future<String?> get(String key) async => throw StateError('disk full');

  @override
  Future<void> set(String key, String value) async =>
      throw StateError('disk full');
}
