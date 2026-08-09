import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../api/shohojpath_api.dart';
import '../app/app_nav_state.dart';
import '../app/auth_state.dart';
import '../app/participant_state.dart';
import '../app/route_observer.dart';
import '../services/passage_repository.dart';
import '../data/mock_content.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/greeting.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with RefreshOnRouteReturn<HomeScreen> {
  late Future<List<LibraryEntry>> _assigned;
  late Future<_HomeSummary> _summary;

  @override
  void initState() {
    super.initState();
    _assigned = _loadAssigned();
    _summary = _loadSummary();
  }

  /// Coming back from Reading, Bookmarks or History means these counts are a
  /// snapshot from before whatever the reader just did. Bookmarking a page and
  /// returning used to leave the tile reading "0 saved".
  @override
  void onRouteReturn() => _refresh();

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
            category: '',
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
          leading: const _Greeting(),
          trailing: const [NotificationBell()],
          bottom: HeaderSearchField(
            hint: context.t.searchPassages,
            // Not just select(library): this field is a search affordance, so
            // it hands over to Library's real one with the cursor already in
            // it. The other Home shortcuts only change tab.
            onTap: () => context.read<AppNavState>().openLibrarySearch(),
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
                                    context.t.assignedByTherapist,
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
                          label: context.t.startReading,
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
                                  label: context.t.tabLibrary,
                                  caption: summary.passageCountLabel(context.t),
                                  onTap: () => context
                                      .read<AppNavState>()
                                      .select(AppTab.library),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: _QuickCard(
                                  icon: Icons.insights_rounded,
                                  label: context.t.myProgress,
                                  caption: summary.minutesTodayLabel(context.t),
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
                                  label: context.t.bookmarksTile,
                                  caption: summary.bookmarkCountLabel(context.t),
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
                                  label: context.t.historyTile,
                                  caption: summary.sessionCountLabel(context.t),
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
                        label: context.t.settings,
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
                        label: context.t.help,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HelpScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _ChromeButton(
                        icon: Icons.info_rounded,
                        label: context.t.about,
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

class _Greeting extends StatefulWidget {
  const _Greeting();

  @override
  State<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends State<_Greeting> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _scheduleNextChange();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// The greeting in whichever language the interface is in.
  String _greeting(BuildContext context) {
    final t = context.t;
    return switch (greetingFor(DateTime.now())) {
      'Good morning' => t.goodMorning,
      'Good afternoon' => t.goodAfternoon,
      _ => t.goodEvening,
    };
  }

  /// Wakes exactly when the wording is due to change, rather than polling.
  void _scheduleNextChange() {
    _tick?.cancel();
    _tick = Timer(untilGreetingChanges(DateTime.now()), () {
      if (!mounted) return;
      setState(() {});
      _scheduleNextChange();
    });
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

    // Sits on the navy header alongside the notification bell, so the
    // colours here are the on-navy pair rather than the page's ink/muted.
    return Row(
      children: [
        Material(
          color: AppColors.teal,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.read<AppNavState>().select(AppTab.profile),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _greeting(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onNavyMuted,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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

  String passageCountLabel(AppStrings t) =>
      passageCount == null ? '—' : t.passageCount(passageCount!);

  String bookmarkCountLabel(AppStrings t) =>
      bookmarkCount == null ? '—' : t.savedCount(bookmarkCount!);

  String sessionCountLabel(AppStrings t) {
    final n = sessionCount;
    if (n == null) return '—';
    return t.sessionCount(n);
  }

  String minutesTodayLabel(AppStrings t) {
    final m = minutesToday;
    if (m == null) return '—';
    if (m == 0) return t.nothingToday;
    if (m < 1) return t.underAMinute;
    return t.minutesToday(m.round());
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
        SnackBar(content: Text(context.tOnce.passageHasNoPages)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.startHere,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.tealText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              context.t.noReadingYetShort,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 4),
            Text(
              context.t.pickAPassage,
              style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    final passageId = current['passage_id'] as String? ?? '';
    final available = current['available'] != false;
    final title = current['title'] as String? ?? passageId;
    final percent = (current['percent'] as num?)?.toDouble();
    final pagesRead = (current['pages_read'] as num?)?.toInt() ?? 0;
    final pageCount = (current['page_count'] as num?)?.toInt() ?? 0;

    // The passage this session names is gone — study material gets
    // replaced between rounds. Say so rather than offering a tap that
    // opens the wrong text.
    if (!available) {
      return WhiteCard(
        onTap: () => context.read<AppNavState>().select(AppTab.library),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.lastRead,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.muted,
              ),
            ),
            SizedBox(height: 8),
            Text(
              context.t.passageRetired,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 4),
            Text(
              context.t.passageRetiredBody,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    return WhiteCard(
      onTap: _opening || passageId.isEmpty ? null : () => _open(passageId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  context.t.continueReading,
                  style: const TextStyle(
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
          // No bar when the server could not work out a percentage —
          // an empty bar reads as "no progress", which is a claim.
          if (percent != null)
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
              context.t.pageOf(pagesRead, pageCount),
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
