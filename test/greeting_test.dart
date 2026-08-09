import 'package:flutter_test/flutter_test.dart';

import 'package:shohojpath/utils/greeting.dart';

/// The greeting was computed once, when Home was built, so a session that ran
/// past five went on saying "Good afternoon" all evening. These cover both the
/// wording and the timer that now refreshes it.
void main() {
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(2026, 8, 9, hour, minute);

  group('wording', () {
    test('morning up to noon', () {
      expect(greetingFor(at(0)), 'Good morning');
      expect(greetingFor(at(6, 30)), 'Good morning');
      expect(greetingFor(at(11, 59)), 'Good morning');
    });

    test('afternoon from noon to five', () {
      // The reported case: 12:17 is afternoon, not morning.
      expect(greetingFor(at(12)), 'Good afternoon');
      expect(greetingFor(at(12, 17)), 'Good afternoon');
      expect(greetingFor(at(16, 59)), 'Good afternoon');
    });

    test('evening from five', () {
      expect(greetingFor(at(17)), 'Good evening');
      expect(greetingFor(at(23, 59)), 'Good evening');
    });
  });

  group('when it next changes', () {
    test('morning waits for noon', () {
      expect(untilGreetingChanges(at(9, 30)), const Duration(hours: 2, minutes: 30));
    });

    test('afternoon waits for five', () {
      expect(untilGreetingChanges(at(12, 17)), const Duration(hours: 4, minutes: 43));
    });

    test('evening waits for midnight', () {
      expect(untilGreetingChanges(at(23, 30)), const Duration(minutes: 30));
      expect(untilGreetingChanges(at(17)), const Duration(hours: 7));
    });

    test('the wait always lands exactly on a boundary', () {
      // Walk the whole day: after waiting, the wording must have changed.
      for (var hour = 0; hour < 24; hour++) {
        final now = at(hour, 20);
        final then = now.add(untilGreetingChanges(now));
        expect(
          greetingFor(then),
          isNot(greetingFor(now)),
          reason: 'waiting from ${now.hour}:20 should reach a new greeting',
        );
      }
    });

    test('never returns zero, so the timer cannot spin', () {
      for (var hour = 0; hour < 24; hour++) {
        for (final minute in [0, 59]) {
          expect(
            untilGreetingChanges(at(hour, minute)),
            greaterThanOrEqualTo(const Duration(seconds: 1)),
          );
        }
      }
    });

    test('crosses a month end', () {
      // 31 August, evening: the next change is midnight on 1 September.
      final lastNight = DateTime(2026, 8, 31, 22);
      expect(untilGreetingChanges(lastNight), const Duration(hours: 2));
    });
  });
}
