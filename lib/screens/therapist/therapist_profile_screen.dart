import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_exception.dart';
import '../../api/shohojpath_api.dart';
import '../../app/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/auth_form_field.dart';
import '../../widgets/export_data_action.dart';
import '../../widgets/settings_controls.dart';
import '../../widgets/therapist_bottom_tab_bar.dart';
import '../login_screen.dart';
import '../help_screen.dart';
import '../notifications_screen.dart';

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

  Future<void> _changePassword(BuildContext context) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    }
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
                  const Text('Profile', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)),
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
                                  : 'Therapist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(
                              context.watch<AuthState>().email ?? 'Not signed in',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, color: AppColors.onNavyMuted),
                            ),
                            const Text(
                              'Speech & Language Therapist',
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
                              Expanded(child: _StatTile(value: readers?.toString() ?? '—', label: 'Readers managed')),
                              const SizedBox(width: 11),
                              Expanded(child: _StatTile(value: sessions?.toString() ?? '—', label: 'Sessions logged')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ListRowButton(
                          leading: const Icon(Icons.download_rounded, color: AppColors.navy, size: 24),
                          title: 'Export all data as CSV',
                          onTap: () => exportAndShareCsv(context),
                        ),
                        const SizedBox(height: 11),
                        ListRowButton(
                          leading: const Icon(Icons.lock_outline_rounded, color: AppColors.navy, size: 24),
                          title: 'Change password',
                          onTap: () => _changePassword(context),
                        ),
                        const SizedBox(height: 11),
                        ListRowButton(
                          leading: const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 24),
                          title: 'Notifications',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                        ListRowButton(
                          leading: const Icon(Icons.help_outline_rounded, color: AppColors.navy, size: 24),
                          title: 'Help & support',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HelpScreen()),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SecondaryButton(
                          label: 'Log out',
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


/// Changes the signed-in therapist's password through `/api/auth/password/`.
///
/// The current password is required by the server, not merely asked for here:
/// a study device is handed around, and an unlocked screen must not be enough
/// to lock the therapist out of their own account.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    try {
      await context.read<ShohojpathApi>().changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      navigator.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Change password',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            AuthFormField(
              label: 'Current password',
              controller: _current,
              icon: Icons.lock_outline_rounded,
              obscure: true,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthFormField(
              label: 'New password',
              controller: _next,
              icon: Icons.lock_reset_rounded,
              hint: 'At least 8 characters',
              obscure: true,
              enabled: !_saving,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Change'),
        ),
      ],
    );
  }
}
