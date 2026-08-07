import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/participant_state.dart';
import '../../services/reader_repository.dart';
import '../../services/session_logger.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/export_data_action.dart';
import '../../widgets/settings_controls.dart';
import '../../widgets/therapist_bottom_tab_bar.dart';
import '../login_screen.dart';

/// Screen `tprofile` of the v2 design — the therapist's own profile tab.
/// The identity header ("Rownak Chowdhury / Speech & Language Therapist") is
/// a decorative mock persona, exactly like the reader side's "Mitu Rahman" —
/// there is no therapist-accounts backend in this prototype. The stat tiles
/// underneath are real, computed from [ReaderRepository] and [SessionLogger].
class TherapistProfileScreen extends StatefulWidget {
  const TherapistProfileScreen({super.key});

  @override
  State<TherapistProfileScreen> createState() => _TherapistProfileScreenState();
}

class _TherapistProfileScreenState extends State<TherapistProfileScreen> {
  late Future<(int, int)> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _load();
  }

  Future<(int, int)> _load() async {
    final readerRepo = context.read<ReaderRepository>();
    final logger = context.read<SessionLogger>();
    final readers = await readerRepo.readerCount();
    final sessions = await logger.sessionCount();
    return (readers, sessions);
  }

  void _logOut(BuildContext context) {
    context.read<ParticipantState>().signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rownak Chowdhury', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text(
                              'Speech & Language Therapist',
                              style: TextStyle(fontSize: 15, color: AppColors.onNavyMuted),
                            ),
                            Text(
                              'Dhaka Child Development Centre',
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
                child: FutureBuilder<(int, int)>(
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
                          leading: const Icon(Icons.business_rounded, color: AppColors.navy, size: 24),
                          title: 'Clinic details',
                          onTap: () => _notImplemented(context, 'Clinic settings'),
                        ),
                        const SizedBox(height: 11),
                        ListRowButton(
                          leading: const Icon(Icons.notifications_none_rounded, color: AppColors.navy, size: 24),
                          title: 'Notifications',
                          onTap: () => _notImplemented(context, 'Notification settings'),
                        ),
                        const SizedBox(height: 11),
                        ListRowButton(
                          leading: const Icon(Icons.help_outline_rounded, color: AppColors.navy, size: 24),
                          title: 'Help & support',
                          onTap: () => _notImplemented(context, 'Help & support'),
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
