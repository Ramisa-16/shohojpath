import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/reading_settings.dart';
import 'reader_repository.dart';
import 'settings_repository.dart';

/// Loads whichever reading configuration a reader should start under —
/// their own previously-saved settings if they have any, otherwise the
/// `starting_profile` a therapist picked when registering them (or the
/// constructor default for an ad-hoc guest with no such record) — into the
/// single shared [ReadingSettings] instance.
///
/// Call this immediately after [ParticipantState.signInAsReader], whether
/// the reader signed themselves in or a therapist started the session for
/// them from the dashboard, so the passage they see next is already in
/// their own condition rather than whoever used the device last.
Future<void> loadReaderProfile(BuildContext context, String participantId) async {
  final settings = context.read<ReadingSettings>();
  final settingsRepo = context.read<SettingsRepository>();
  final readerRepo = context.read<ReaderRepository>();

  final saved = await settingsRepo.load(participantId);
  if (saved != null) {
    settings.restoreFromMap(saved);
    return;
  }

  final reader = await readerRepo.reader(participantId);
  final startingProfile = ReadingProfile.fromId(reader?['starting_profile'] as String?);
  settings.restoreFromMap(ReadingSettings(initialProfile: startingProfile).toMap());
}
