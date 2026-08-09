import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/participant_state.dart';
import '../models/reading_settings.dart';
import '../screens/therapist/therapist_dashboard_screen.dart';
import '../l10n/app_strings.dart';
import '../l10n/label_extensions.dart';
import '../theme/app_colors.dart';
import 'therapist_password_dialog.dart';

/// A slim, deliberately quiet bar shown on reader screens only while a
/// therapist started this session from the Dashboard — never for a reader's
/// own sign-in or a guest session, since only a supervised session needs a
/// password-gated way back to therapist data. Renders nothing otherwise.
class TherapistSessionBanner extends StatelessWidget {
  const TherapistSessionBanner({super.key});

  Future<void> _endSession(BuildContext context) async {
    final confirmed = await showTherapistPasswordDialog(
      context,
      title: context.tOnce.endSession,
      description: "Enter the therapist's password to return to the Dashboard.",
      confirmLabel: context.t.endSession,
    );
    if (!confirmed || !context.mounted) return;

    context.read<ParticipantState>().signInAsTherapist();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TherapistDashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final participant = context.watch<ParticipantState>();
    if (!participant.isSupervisedByTherapist) return const SizedBox.shrink();
    // Live, not captured at session start: under Custom the reader can
    // change profile freely, and this should always show whatever's
    // actually active, not just the condition the session began under.
    final condition =
        context.watch<ReadingSettings>().profile.localisedLabel(context.t);

    return Container(
      width: double.infinity,
      color: AppColors.chipNeutral,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${participant.displayName} · $condition',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ),
          GestureDetector(
            onTap: () => _endSession(context),
            child: const Text(
              'End session',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
