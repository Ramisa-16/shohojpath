import 'package:flutter/foundation.dart';

/// Which side of the study the signed-in person is on. Reader screens and
/// therapist screens are entirely separate flows sharing only the Login
/// screen and the same underlying database.
enum UserRole { reader, therapist }

/// Who is currently signed in — set once at Login, read wherever a screen
/// needs to know whose data it's looking at (a reading session's
/// `participant_id`, a therapist's own roster).
///
/// Deliberately in-memory only: a fresh participant ID per app launch matches
/// how the study actually runs (one participant sits down, reads, hands the
/// device back), and persisting it would risk a new participant silently
/// inheriting the previous one's ID if they forgot to log out.
class ParticipantState extends ChangeNotifier {
  UserRole _role = UserRole.reader;
  String _participantId = '';
  String _displayName = '';
  bool _supervisedByTherapist = false;
  bool _settingsLocked = false;

  UserRole get role => _role;
  String get participantId => _participantId;
  String get displayName => _displayName;
  bool get isTherapist => _role == UserRole.therapist;

  /// True while the current reader session was started by a therapist from
  /// the Dashboard's "Start session" button rather than the reader signing
  /// themselves in — the signal the session banner uses to show itself,
  /// since only a supervised session needs a password-gated way back to
  /// therapist data.
  bool get isSupervisedByTherapist => _supervisedByTherapist;

  /// True while this session's reading condition (Default or Recommended,
  /// chosen by the therapist at "Start session") must not be touched — a
  /// reader who changes settings mid-session invalidates the experimental
  /// condition the data is meant to represent. Never true for a reader who
  /// signed themselves in, or for a therapist-started session under
  /// "Custom". Cleared only via [unlockSettings], a deliberate therapist
  /// override, not by anything the reader can reach on their own.
  bool get isSettingsLocked => _settingsLocked;

  void signInAsReader(
    String participantId, {
    String? displayName,
    bool supervisedByTherapist = false,
    bool settingsLocked = false,
  }) {
    _role = UserRole.reader;
    _participantId = participantId;
    _displayName = displayName ?? participantId;
    _supervisedByTherapist = supervisedByTherapist;
    _settingsLocked = settingsLocked;
    notifyListeners();
  }

  void signInAsTherapist() {
    _role = UserRole.therapist;
    _participantId = '';
    _displayName = '';
    _supervisedByTherapist = false;
    _settingsLocked = false;
    notifyListeners();
  }

  /// The therapist's password-gated override on the locked settings panel —
  /// the session keeps running (unlike "End session"), just no longer under
  /// condition lock from this point on.
  void unlockSettings() {
    if (!_settingsLocked) return;
    _settingsLocked = false;
    notifyListeners();
  }

  /// Clears the signed-in identity on log-out, back to the Reader-role
  /// default with no participant id — the same starting state as app launch.
  void signOut() {
    _role = UserRole.reader;
    _participantId = '';
    _displayName = '';
    _supervisedByTherapist = false;
    _settingsLocked = false;
    notifyListeners();
  }
}
