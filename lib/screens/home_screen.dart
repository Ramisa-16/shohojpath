import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_nav_state.dart';
import '../app/participant_state.dart';
import '../data/mock_content.dart';
import '../data/passages.dart';
import '../services/reader_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/settings_controls.dart';
import 'about_screen.dart';
import 'app_settings_screen.dart';
import 'bookmarks_screen.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'reading_screen.dart';

/// Screen 03 of the design — the Home tab of [HomeShell].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<LibraryEntry>> _assigned;

  @override
  void initState() {
    super.initState();
    _assigned = _loadAssigned();
  }

  Future<List<LibraryEntry>> _loadAssigned() async {
    final participantId = context.read<ParticipantState>().participantId;
    if (participantId.isEmpty) return const [];
    final ids = await context.read<ReaderRepository>().assignedPassageIds(participantId);
    if (ids.isEmpty) return const [];
    final idSet = ids.toSet();
    return MockContent.library.where((e) => idSet.contains(e.passage?.id ?? e.title)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final passage = Passages.bristirDineMitu;

    return Column(
      children: [
        AppHeader(
          title: '',
          trailing: [
            IconButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No notifications yet.')),
              ),
              tooltip: 'Notifications',
              icon: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
              ),
            ),
          ],
          bottom: HeaderSearchField(
            hint: 'Search passages…',
            onTap: () => context.read<AppNavState>().select(AppTab.library),
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.canvas,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _Greeting(),
                const SizedBox(height: 12),
                FutureBuilder<List<LibraryEntry>>(
                  future: _assigned,
                  builder: (context, snapshot) {
                    final entries = snapshot.data ?? const [];
                    if (entries.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WhiteCard(
                        onTap: () => context.read<AppNavState>().select(AppTab.library),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.assignment_turned_in_rounded, color: AppColors.tealDeep, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ASSIGNED BY YOUR THERAPIST',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.tealText),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final entry in entries)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• ${entry.title}',
                                  style: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 15, color: AppColors.ink),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                WhiteCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReadingScreen(passage: passage),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text(
                              'CONTINUE READING',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.tealText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.bookmark_rounded,
                            color: AppColors.navy,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        passage.title,
                        style: const TextStyle(
                          fontFamily: 'NotoSansBengali',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: const LinearProgressIndicator(
                                value: 0.64,
                                minHeight: 9,
                                backgroundColor: AppColors.trackAlt,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '64%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.body,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Page 4 of 6 · about 4 min left',
                        style: TextStyle(fontSize: 14, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Start Reading',
                  icon: Icons.auto_stories_rounded,
                  backgroundColor: AppColors.teal,
                  onPressed: () => context.read<AppNavState>().select(AppTab.library),
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.local_library_rounded,
                          label: 'Library',
                          caption: '28 passages',
                          onTap: () => context.read<AppNavState>().select(
                            AppTab.library,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.insights_rounded,
                          label: 'My Progress',
                          caption: '18 min today',
                          onTap: () => context.read<AppNavState>().select(
                            AppTab.progress,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.bookmarks_rounded,
                          label: 'Bookmarks',
                          caption: '5 saved',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BookmarksScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.history_rounded,
                          label: 'History',
                          caption: '12 sessions',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: _ChromeButton(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppSettingsScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _ChromeButton(
                        icon: Icons.help_rounded,
                        label: 'Help',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HelpScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _ChromeButton(
                        icon: Icons.info_rounded,
                        label: 'About',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.teal,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.read<AppNavState>().select(AppTab.profile),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Center(
                child: Text(
                  'MR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              Text(
                'Mitu Rahman',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.navy, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            caption,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceTile(
      label: label,
      selected: false,
      onTap: onTap,
      child: Icon(icon, color: AppColors.navy, size: 24),
    );
  }
}
