import 'package:flutter/material.dart';

import '../../models/reading_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/settings_controls.dart';

/// The sheet a therapist sees on "Start session" — a research-integrity
/// gate, not just a formality: Default and Recommended lock the reading
/// settings for the whole session, because a reader who tweaks font size or
/// spacing mid-session has quietly left the experimental condition the
/// logged data is supposed to represent. Only Custom leaves them free to
/// edit, same as signing in themselves.
///
/// Returns the chosen [ReadingProfile], or null if dismissed without
/// starting.
Future<ReadingProfile?> showStartSessionSheet(
  BuildContext context, {
  required String name,
  required String participantId,
}) {
  return showModalBottomSheet<ReadingProfile>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StartSessionSheet(name: name, participantId: participantId),
  );
}

class StartSessionSheet extends StatefulWidget {
  const StartSessionSheet({super.key, required this.name, required this.participantId});

  final String name;
  final String participantId;

  @override
  State<StartSessionSheet> createState() => _StartSessionSheetState();
}

class _StartSessionSheetState extends State<StartSessionSheet> {
  ReadingProfile _condition = ReadingProfile.recommended;

  static const _descriptions = {
    ReadingProfile.standard: 'Standard formatting. Settings locked.',
    ReadingProfile.recommended: 'Evidence-based settings. Settings locked.',
    ReadingProfile.custom: 'Reader chooses their own settings.',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Start session', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.navy)),
              const SizedBox(height: 4),
              Text(
                '${widget.name} · ${widget.participantId}',
                style: const TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              const Text(
                'READING CONDITION',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.body),
              ),
              const SizedBox(height: 8),
              for (final profile in ReadingProfile.values) ...[
                ProfileOptionTile(
                  title: profile.label,
                  description: _descriptions[profile]!,
                  selected: _condition == profile,
                  onTap: () => setState(() => _condition = profile),
                ),
                if (profile != ReadingProfile.values.last) const SizedBox(height: 8),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Start',
                onPressed: () => Navigator.of(context).pop(_condition),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
