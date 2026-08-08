import 'package:flutter_test/flutter_test.dart';

import 'package:shohojpath/app/participant_state.dart';

/// Logging out has to leave nothing of the previous participant behind. The
/// study hands one device between readers, so a stale participant id would
/// silently attribute one reader's session rows to another.
void main() {
  group('ParticipantState.signOut', () {
    test('clears the reader identity', () {
      final state = ParticipantState()..signInAsReader('P-04', displayName: 'Mitu Rahman');
      expect(state.participantId, 'P-04');

      state.signOut();

      expect(state.participantId, isEmpty);
      expect(state.displayName, isEmpty);
      expect(state.role, UserRole.reader);
    });

    test('clears a supervised session and its condition lock', () {
      final state = ParticipantState()
        ..signInAsReader(
          'P-07',
          displayName: 'Rafi',
          supervisedByTherapist: true,
          settingsLocked: true,
        );
      expect(state.isSupervisedByTherapist, isTrue);
      expect(state.isSettingsLocked, isTrue);

      state.signOut();

      expect(state.isSupervisedByTherapist, isFalse);
      expect(state.isSettingsLocked, isFalse,
          reason: 'a locked condition must not survive into the next session');
      expect(state.participantId, isEmpty);
    });

    test('drops the therapist role back to the launch state', () {
      final state = ParticipantState()..signInAsTherapist();
      expect(state.isTherapist, isTrue);

      state.signOut();

      expect(state.isTherapist, isFalse);
      expect(state.role, UserRole.reader);
    });

    test('notifies listeners so the UI can react', () {
      final state = ParticipantState()..signInAsReader('P-04');
      var notified = 0;
      state.addListener(() => notified++);

      state.signOut();

      expect(notified, 1);
    });
  });
}
