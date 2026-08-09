import 'package:flutter_test/flutter_test.dart';

import 'package:shohojpath/l10n/app_language.dart';
import 'package:shohojpath/l10n/app_strings.dart';
import 'package:shohojpath/models/passage.dart';
import 'package:shohojpath/models/study_session.dart';

/// SUS scoring, checked against worked examples rather than against itself.
///
/// The scale is only comparable to the 68-point benchmark if it is scored the
/// standard way: odd items contribute (response − 1), even items (5 −
/// response), and the total is multiplied by 2.5.
void main() {
  StudySession session([List<int>? answers]) {
    final s = StudySession(
      sessionId: 's',
      passage: Passage(
        id: 'p',
        title: 'গল্প',
        category: 'ইশপের গল্প',
        difficulty: PassageDifficulty.easy,
        estimatedMinutes: 2,
        pages: const [PassagePage(['এক'])],
      ),
      readAloudWasOn: false,
      readingDuration: const Duration(minutes: 1),
    );
    if (answers != null) {
      for (var i = 0; i < answers.length; i++) {
        s.susAnswers[i] = answers[i];
      }
    }
    return s;
  }

  test('the best possible answers score 100', () {
    // Agree with every positive item, disagree with every negative one.
    final best = [5, 1, 5, 1, 5, 1, 5, 1, 5, 1];
    expect(session(best).susScore, 100);
  });

  test('the worst possible answers score 0', () {
    final worst = [1, 5, 1, 5, 1, 5, 1, 5, 1, 5];
    expect(session(worst).susScore, 0);
  });

  test('all-neutral scores 50', () {
    expect(session(List.filled(10, 3)).susScore, 50);
  });

  test('a worked example', () {
    // odd items (5,4,4,4,3) -> 4+3+3+3+2 = 15
    // even items (2,1,2,2,1) -> 3+4+3+3+4 = 17
    // 32 x 2.5 = 80
    final answers = [5, 2, 4, 1, 4, 2, 4, 2, 3, 1];
    expect(session(answers).susScore, 80);
  });

  test('an incomplete response scores nothing rather than a partial total', () {
    // A half-filled scale that reported 40 would look like a bad usability
    // result instead of an unfinished questionnaire.
    final partial = session([5, 1, 5, 1, 5]);
    expect(partial.susComplete, isFalse);
    expect(partial.susScore, 0);
  });

  test('both languages present ten items, in the same order', () {
    const bn = AppStrings(AppLanguage.bangla);
    const en = AppStrings(AppLanguage.english);

    expect(bn.susItems, hasLength(10));
    expect(en.susItems, hasLength(10));

    // Order carries the scoring: item 2 must be the negative one in both, or
    // the odd/even rule inverts for whoever reads the other language.
    expect(en.susItems[1], contains('unnecessarily complex'));
    expect(bn.susItems[1], contains('জটিল'));
    expect(en.susItems[7], contains('cumbersome'));
    expect(bn.susItems[7], contains('ঝামেলার'));

    for (var i = 0; i < 10; i++) {
      expect(bn.susItems[i], isNot(en.susItems[i]));
    }
  });
}
