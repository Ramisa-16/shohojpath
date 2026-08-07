/// How the Login screen's reader picker identifies each reader — a
/// therapist/researcher choice made once in App Settings for the device
/// the study is running on, not something a reader ever sees a control for.
enum ReaderSignInDisplay {
  /// Tap-to-choose list shows each reader's name. Fine for a single-user
  /// device at home where no other participant will see the list.
  names(id: 'names', label: 'Names'),

  /// Tap-to-choose list shows participant IDs (e.g. "P-04") instead of
  /// names, so a shared study device never displays another participant's
  /// name to whoever is currently using it.
  participantIdsOnly(id: 'participant_ids_only', label: 'Participant IDs only'),

  /// The reader picker is hidden entirely — Login shows only the Therapist
  /// option and Continue as Guest. Every reading session starts from the
  /// Therapist Dashboard's "Start session" button.
  off(id: 'off', label: 'Off — therapist starts all sessions');

  const ReaderSignInDisplay({required this.id, required this.label});

  final String id;
  final String label;

  static ReaderSignInDisplay fromId(String? id) => values.firstWhere(
        (v) => v.id == id,
        orElse: () => ReaderSignInDisplay.names,
      );
}
