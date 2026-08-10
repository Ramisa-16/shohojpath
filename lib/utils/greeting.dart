/// The time-of-day greeting on Home, and when it next changes.
///
/// Split out of the widget so the boundary arithmetic can be tested at a
/// chosen time instead of whatever the clock happens to say during a test run.
library;

/// Hours at which the wording changes. Midnight is the third and is handled
/// by rolling over to the next day.
const List<int> greetingBoundaries = [12, 17];

/// Which greeting applies, as a value rather than a sentence.
///
/// This used to return the English text and the screen matched on it with a
/// switch — so translating the English would silently have fallen through to
/// the default and greeted every child "good evening" all day.
enum Greeting { morning, afternoon, evening }

Greeting greetingFor(DateTime now) {
  if (now.hour < 12) return Greeting.morning;
  if (now.hour < 17) return Greeting.afternoon;
  return Greeting.evening;
}

/// How long until [greetingFor] would return something different.
///
/// The greeting used to be read once, when Home was built: a session that
/// started before five and ran past it went on saying "Good afternoon" into
/// the evening. Waking exactly at the boundary costs one timer a day rather
/// than a rebuild every minute.
Duration untilGreetingChanges(DateTime now) {
  var next = DateTime(now.year, now.month, now.day + 1);
  for (final hour in greetingBoundaries) {
    if (now.hour < hour) {
      next = DateTime(now.year, now.month, now.day, hour);
      break;
    }
  }
  final wait = next.difference(now);
  // A clock change could otherwise leave this at zero and spin.
  return wait < const Duration(seconds: 1) ? const Duration(seconds: 1) : wait;
}
