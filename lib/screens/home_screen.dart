import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../api/shohojpath_api.dart';
import '../app/app_nav_state.dart';
import '../app/auth_state.dart';
import '../app/participant_state.dart';
import '../services/passage_repository.dart';
import '../data/mock_content.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import 'notifications_screen.dart';
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
  late Future<_HomeSummary> _summary;

  @override
  void initState() {
    super.initState();
    _assigned = _loadAssigned();
    _summary = _loadSummary();
  }

  Future<void> _refresh() async {
    setState(() {
      _assigned = _loadAssigned();
      _summary = _loadSummary();
    });
    await Future.wait<void>([_assigned, _summary]);
  }

  /// The four tile captions and the continue-reading card, in one place.
  ///
  /// Every figure is fetched rather than typed: this screen used to claim
  /// "28 passages / 18 min today / 5 saved / 12 sessions" to every reader,
  /// including one who had never opened a passage.
  Future<_HomeSummary> _loadSummary() async {
    final api = context.read<ShohojpathApi>();
    try {
      final results = await Future.wait([
        api.myProgress(),
        api.passages(),
        api.bookmarks(),
      ]);
      return _HomeSummary(
        progress: results[0] as Map<String, dynamic>,
        passageCount: (results[1] as List).length,
        bookmarkCount: (results[2] as List).length,
      );
    } on ApiException {
      // Offline: show the card and tiles without counts rather than lying.
      return const _HomeSummary.unavailable();
    }
  }

  /// What this reader's therapist has set for them, from the server.
  ///
  /// Returns empty rather than throwing when offline: an unreachable server
  /// means "no assignments to show right now", not a broken Home screen.
  Future<List<LibraryEntry>> _loadAssigned() async {
    final participantId = context.read<ParticipantState>().participantId;
    if (participantId.isEmpty) return const [];
    try {
      final rows = await context.read<ShohojpathApi>().myAssignments();
      return [
        for (final row in rows)
          LibraryEntry(
            title: row['passage_title'] as String? ?? '',
            category: 'Assigned by your therapist',
            time: '',
            level: '',
          ),
      ];
    } on ApiException {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(
          title: '',
          trailing: const [NotificationBell()],
          bottom: HeaderSearchField(
            hint: 'Search passages…',
            onTap: () => context.read<AppNavState>().select(AppTab.library),
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.canvas,
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(14),
              children: [
                const _Greeting(),
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
                FutureBuilder<_HomeSummary>(
                  future: _summary,
                  builder: (context, snapshot) {
                    final summary =
                        snapshot.data ?? const _HomeSummary.unavailable();
                    return Column(
                      children: [
                        _ContinueReadingCard(summary: summary),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Start Reading',
                          icon: Icons.auto_stories_rounded,
                          backgroundColor: AppColors.teal,
                          onPressed: () =>
                              context.read<AppNavState>().select(AppTab.library),
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
                                  caption: summary.passageCountLabel,
                                  onTap: () => context
                                      .read<AppNavState>()
                                      .select(AppTab.library),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: _QuickCard(
                                  icon: Icons.insights_rounded,
                                  label: 'My Progress',
                                  caption: summary.minutesTodayLabel,
                                  onTap: () => context
                                      .read<AppNavState>()
                                      .select(AppTab.progress),
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
                                  caption: summary.bookmarkCountLabel,
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
                                  caption: summary.sessionCountLabel,
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
                      ],
                    );
                  },
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
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  /// Time-aware rather than a fixed "Good morning": a study session run in
  /// the afternoon should not greet a child with the wrong time of day.
  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final participant = context.watch<ParticipantState>();

    final name = (auth.fullName?.isNotEmpty ?? false)
        ? auth.fullName!
        : (participant.displayName.isNotEmpty
            ? participant.displayName
            : 'Reader');

    return Row(
      children: [
        Material(
          color: AppColors.teal,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.read<AppNavState>().select(AppTab.profile),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Center(
                child: Text(
                  _initials(name),
                  style: const TextStyle(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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


/// The Home screen's numbers, fetched together.
///
/// Nullable counts throughout, and the labels render an em dash when a value
/// is missing: an offline Home must say "I do not know" rather than show a
/// confident zero, which a reader would read as "you have done nothing".
class _HomeSummary {
  const _HomeSummary({
    required this.progress,
    required this.passageCount,
    required this.bookmarkCount,
  });

  const _HomeSummary.unavailable()
      : progress = const {},
        passageCount = null,
        bookmarkCount = null;

  final Map<String, dynamic> progress;
  final int? passageCount;
  final int? bookmarkCount;

  Map? get currentPassage => progress['current_passage'] as Map?;

  int? get sessionCount => (progress['sessions_total'] as num?)?.toInt();

  double? get minutesToday => (progress['minutes_today'] as num?)?.toDouble();

  String get passageCountLabel =>
      passageCount == null ? '—' : '$passageCount passages';

  String get bookmarkCountLabel =>
      bookmarkCount == null ? '—' : '$bookmarkCount saved';

  String get sessionCountLabel {
    final n = sessionCount;
    if (n == null) return '—';
    return '$n session${n == 1 ? '' : 's'}';
  }

  String get minutesTodayLabel {
    final m = minutesToday;
    if (m == null) return '—';
    if (m == 0) return 'Nothing today';
    if (m < 1) return 'Under a minute';
    return '${m.round()} min today';
  }
}

/// Picks up where the reader left off, from their last synced session.
class _ContinueReadingCard extends StatefulWidget {
  const _ContinueReadingCard({required this.summary});

  final _HomeSummary summary;

  @override
  State<_ContinueReadingCard> createState() => _ContinueReadingCardState();
}

class _ContinueReadingCardState extends State<_ContinueReadingCard> {
  bool _opening = false;

  Future<void> _open(String passageId) async {
    setState(() => _opening = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final passage = await context.read<PassageRepository>().passage(passageId);
    if (!mounted) return;
    setState(() => _opening = false);

    if (passage.pages.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('That passage has no pages yet.')),
      );
      return;
    }
    navigator.push(
      MaterialPageRoute(builder: (_) => ReadingScreen(passage: passage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.summary.currentPassage;

    // Nothing read yet — an invitation, not a fabricated progress bar.
    if (current == null) {
      return WhiteCard(
        onTap: () => context.read<AppNavState>().select(AppTab.library),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'START HERE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.tealText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No reading yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Pick a passage from the Library to begin. Your progress will '
              'show up here.',
              style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    final title = current['title'] as String? ?? '';
    final passageId = current['passage_id'] as String? ?? '';
    final percent = (current['percent'] as num?)?.toDouble() ?? 0;
    final pagesRead = (current['pages_read'] as num?)?.toInt() ?? 0;
    final pageCount = (current['page_count'] as num?)?.toInt() ?? 0;

    return WhiteCard(
      onTap: _opening || passageId.isEmpty ? null : () => _open(passageId),
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
              if (_opening)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                const Icon(Icons.bookmark_rounded,
                    color: AppColors.navy, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
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
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0, 1),
                    minHeight: 9,
                    backgroundColor: AppColors.trackAlt,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percent.round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.body,
                ),
              ),
            ],
          ),
          if (pageCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Page $pagesRead of $pageCount',
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
