import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_exception.dart';
import '../../api/shohojpath_api.dart';
import '../../app/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/change_password_sheet.dart';
import '../../widgets/export_data_action.dart';
import '../../widgets/settings_controls.dart';
import '../../widgets/therapist_bottom_tab_bar.dart';
import '../login_screen.dart';
import '../help_screen.dart';
import '../notifications_screen.dart';
import '../../l10n/app_strings.dart';

/// Screen `tprofile` of the v2 design — the therapist's own profile tab.
/// The identity header shows the signed-in therapist, from [AuthState].
/// The stat tiles underneath come from the server.
class TherapistProfileScreen extends StatefulWidget {
  const TherapistProfileScreen({super.key});

  @override
  State<TherapistProfileScreen> createState() => _TherapistProfileScreenState();
}

class _TherapistProfileScreenState extends State<TherapistProfileScreen> {
  late Future<(int?, int?)> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _load();
  }

  /// From the server, not the local database: `readerCount()` counts every
  /// reader row on the device — including the sample ones seeded for a
  /// fresh install — rather than the roster this therapist actually owns.
  Future<(int?, int?)> _load() async {
    try {
      final overview = await context.read<ShohojpathApi>().therapistOverview();
      return (
        (overview['reader_count'] as num?)?.toInt(),
        (overview['session_count'] as num?)?.toInt(),
      );
    } on ApiException {
      // Null renders as an em dash. Offline must not claim zero readers —
      // that reads as "your roster is empty", which is a different and
      // alarming thing from "I could not check".
      return (null, null);
    }
  }

  /// Clears the stored token as well as the in-memory identity.
  ///
  /// ParticipantState.signOut alone leaves the JWT in the keystore, and
  /// AuthState.restore() would sign this therapist back in on the next launch
  /// — with access to their whole roster.
  Future<void> _logOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    await context.read<AuthState>().signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ignore: unused_element
  void _notImplemented(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is not available in this prototype.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t.profile, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                        child: const Center(
                          child: Text('RC', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.watch<AuthState>().fullName?.isNotEmpty == true
                                  ? context.watch<AuthState>().fullName!
                                  : context.t.therapistRole,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(
                              context.watch<AuthState>().email ?? context.t.notSignedIn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, color: AppColors.onNavyMuted),
                            ),
                            Text(
                              context.t.speechLanguageTherapist,
                              style: TextStyle(fontSize: 14, color: AppColors.onNavyMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: FutureBuilder<(int?, int?)>(
                  future: _stats,
                  builder: (context, snapshot) {
                    final readers = snapshot.data?.$1;
                    final sessions = snapshot.data?.$2;
                    return ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _StatTile(value: readers?.toString() ?? '—', label: context.t.readersManaged)),
                              const SizedBox(width: 11),
                              Expanded(child: _StatTile(value: sessions?.toString() ?? '—', label: context.t.sessionsLogged)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ListRowButton(
                          leading: const Icon(Icons.download_rounded, color: AppColors.navy, size: 24),
                          title: context.t.exportAllCsv,
                          onTap: () => exportAndShareCsv(context),
                        ),
                        const SizedBox(height: 11),
                        ListRowButton(
                          leading: const Icon(Icons.lock_outline_rounded, color: AppColors.navy, size: 24),
                          title: context.t.changePassword,
                          onTap: () => showChangePasswordSheet(context),
                        ),
                        const SizedBox(height: 11),
                        ListRowButton(
                          leading: const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 24),
                          title: context.t.notifications,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                        ListRowButton(
                          leading: const Icon(Icons.help_outline_rounded, color: AppColors.navy, size: 24),
                          title: context.t.helpAndSupport,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HelpScreen()),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SecondaryButton(
                          label: context.t.logOut,
                          icon: Icons.logout_rounded,
                          color: AppColors.danger,
                          onPressed: () => _logOut(context),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const TherapistBottomTabBar(current: TherapistTab.profile),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        ],
      ),
    );
  }
}
