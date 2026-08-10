import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/shohojpath_api.dart';
import '../app/auth_state.dart';
import '../app/participant_state.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/change_password_sheet.dart';
import '../widgets/therapist_password_dialog.dart';
import 'app_settings_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'statistics_screen.dart';

/// Screen 15 of the design — the Profile tab of [HomeShell].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static String _displayName(BuildContext context) {
    final auth = context.watch<AuthState>();
    if ((auth.fullName ?? '').isNotEmpty) return auth.fullName!;
    final participant = context.watch<ParticipantState>();
    if (participant.displayName.isNotEmpty) return participant.displayName;
    return context.t.guestReader;
  }

  static String _initials(BuildContext context) {
    final name = _displayName(context).trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  /// Falls back to the local participant id when signed out, so a guest still
  /// sees which id their sessions are being filed under.
  static String _subtitle(BuildContext context) {
    final auth = context.watch<AuthState>();
    final participant = context.watch<ParticipantState>();
    final id = auth.participantId ?? participant.participantId;
    final role = auth.isSignedIn ? context.t.reader : context.t.guest;
    return id.isEmpty ? role : '$role · $id';
  }

  /// Signs the reader out and returns to Login.
  ///
  /// A supervised session is password-gated, exactly like "End session" on
  /// [TherapistSessionBanner]: the therapist started this session and owns
  /// when it ends, so a reader must not be able to leave it — and reach the
  /// Login screen — on their own. Without the gate this button would be a way
  /// around the condition lock.
  Future<void> _logOut(BuildContext context) async {
    final participant = context.read<ParticipantState>();
    final auth = context.read<AuthState>();
    // Captured before the dialog: reaching back through `context` after an
    // await is what `use_build_context_synchronously` warns about, and this
    // route rebuilds the tree from the root.
    final navigator = Navigator.of(context);

    final bool confirmed;
    if (participant.isSupervisedByTherapist) {
      confirmed = await showTherapistPasswordDialog(
        context,
        title: context.t.logOut,
        description: context.tOnce.therapistPasswordToLogOut,
        confirmLabel: context.tOnce.logOut,
      );
    } else {
      confirmed = await _confirmLogOut(context);
    }
    if (!confirmed) return;

    // AuthState.signOut, not just ParticipantState.signOut: the latter only
    // clears the in-memory identity. The JWT would stay in the keystore and
    // AuthState.restore() would sign this reader straight back in on the next
    // launch — a logout that does not survive a restart is not a logout, and
    // on a device handed between participants it is a data-attribution bug.
    await auth.signOut();
    // pushAndRemoveUntil, not push: the reader's screens hold the previous
    // participant's context, and leaving them on the stack would let Back
    // walk straight into another participant's data.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<bool> _confirmLogOut(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.tOnce.logOutQuestion,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        content: Text(
          context.tOnce.logOutBody,
          style: const TextStyle(fontSize: 15, height: 1.55, color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tOnce.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(context.tOnce.logOut),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.navy,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.profile,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _initials(context),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Expanded: the name/ID line must never be squeezed off
                    // by the fixed-width avatar without anywhere to wrap.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName(context),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _subtitle(context),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.onNavyMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.canvas,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // Sized to its content. A fixed height with an inner
                // ListView clipped Participant ID and Email off the top,
                // and nesting a second scroll view inside the page's own
                // is awkward to use even when nothing is hidden.
                FutureBuilder<Map<String, dynamic>>(
                  future: context.read<ShohojpathApi>().myProfile(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final profile = snapshot.data;
                    if (profile == null) {
                      // A guest has no server profile, and neither does
                      // anyone offline. The header above already shows who
                      // they are, so say nothing rather than show an error.
                      return const SizedBox.shrink();
                    }
                    return _PreferenceCard(profile: profile);
                  },
                ),
                const SizedBox(height: 12),
                ListRowButton(
                  leading: const Icon(Icons.history_rounded, color: AppColors.navy, size: 24),
                  title: context.t.readingHistory,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                const SizedBox(height: 11),
                ListRowButton(
                  leading: const Icon(Icons.analytics_rounded, color: AppColors.navy, size: 24),
                  title: context.t.myStatistics,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                  ),
                ),
                const SizedBox(height: 11),
                ListRowButton(
                  leading: const Icon(Icons.settings_rounded, color: AppColors.navy, size: 24),
                  title: context.t.appSettings,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
                  ),
                ),
                if (context.watch<AuthState>().isSignedIn) ...[
                  const SizedBox(height: 11),
                  ListRowButton(
                    leading: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.navy, size: 24),
                    title: context.t.changePassword,
                    // Hidden for a guest: there is no account to change a
                    // password on, and offering it would be a dead end.
                    onTap: () => showChangePasswordSheet(context),
                  ),
                ],
                const SizedBox(height: 18),
                SecondaryButton(
                  label: context.t.logOut,
                  icon: Icons.logout_rounded,
                  color: AppColors.danger,
                  onPressed: () => _logOut(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The reader's own details, from `/api/me/profile/`.
///
/// Replaces the hard-coded preference rows: a participant looking at this
/// screen should see who the study actually has them recorded as, including
/// which therapist they are working with.
class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final age = profile['age'];
    final therapist = profile['therapist_name'] as String?;

    final rows = <(String, String)>[
      (context.t.participantId, profile['participant_id'] as String? ?? '—'),
      (context.t.email, profile['email'] as String? ?? context.t.noAccount),
      if (age != null) (context.t.age, '$age'),
      if ((profile['class_grade'] as String? ?? '').isNotEmpty)
        (context.t.classLabel, profile['class_grade'] as String),
      if ((profile['school'] as String? ?? '').isNotEmpty)
        (context.t.school, profile['school'] as String),
      (
        context.t.readingProfile,
        _profileLabel(profile['starting_profile'] as String? ?? ''),
      ),
      (context.t.therapist, therapist ?? context.t.notAssignedYet),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      // A Column, not a ListView: this card sits inside the page's own
      // scroll view, where a ListView has no bounded height and throws
      // "RenderBox was not laid out". There are at most seven rows, so there
      // is nothing to virtualise anyway.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: i == rows.length - 1
                  ? null
                  : const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
              // Stacked and left-aligned, not a right-aligned Row: a long
              // value wraps to two lines at large font sizes, and
              // right-aligned wrapped text gives a ragged left edge that is
              // harder to track — exactly what this app's typography avoids.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rows[i].$1,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.body,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rows[i].$2,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _profileLabel(String id) => switch (id) {
        'default' => 'Default',
        'recommended' => 'Recommended',
        'custom' => 'Custom',
        _ => '—',
      };
}
