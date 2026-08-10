import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/participant_state.dart';
import '../../models/reading_settings.dart';
import '../../api/shohojpath_api.dart';
import '../../services/reader_profile_loader.dart';
import '../../services/reader_repository.dart';
import '../../services/session_logger.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/therapist_bottom_tab_bar.dart';
import '../home_shell.dart';
import 'add_reader_screen.dart';
import 'reader_detail_screen.dart';
import 'start_session_sheet.dart';
import 'therapist_profile_screen.dart';
import '../../l10n/app_strings.dart';

/// One row of the caseload list — everything the roster card needs,
/// computed from this reader's actual session rows rather than carried as
/// separate mock fields.
class _ReaderRow {
  const _ReaderRow({
    required this.participantId,
    required this.name,
    required this.meta,
    required this.lastActiveLabel,
    required this.wpmLabel,
    required this.accuracyLabel,
    required this.accuracyFraction,
    required this.statusLabel,
    required this.statusColor,
  });

  final String participantId;
  final String name;
  final String meta;
  final String lastActiveLabel;
  final String wpmLabel;
  final String accuracyLabel;
  final double accuracyFraction;
  final String statusLabel;
  final Color statusColor;
}

/// Screen `tdash` of the v2 design — a therapist's caseload, computed live
/// from [ReaderRepository] and [SessionLogger] rather than the design's
/// static mock roster.
class TherapistDashboardScreen extends StatefulWidget {
  const TherapistDashboardScreen({super.key});

  @override
  State<TherapistDashboardScreen> createState() => _TherapistDashboardScreenState();
}

class _TherapistDashboardScreenState extends State<TherapistDashboardScreen> {
  late Future<List<_ReaderRow>> _roster;
  int _readerCount = 0;
  int _sessionsThisWeek = 0;
  double? _susAverage;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _roster = _buildRoster();
    });
  }

  /// The therapist's roster, from the server.
  ///
  /// One request rather than one per reader: `/api/therapist/readers-summary/`
  /// returns a row per reader already aggregated, so a therapist with twenty
  /// readers does not wait on twenty round trips to a host that may be waking
  /// from sleep.
  Future<List<_ReaderRow>> _buildRoster() async {
    final api = context.read<ShohojpathApi>();

    final overview = await api.therapistOverview();
    final summary = await api.therapistReaderSummary();

    _readerCount = (overview['reader_count'] as num?)?.toInt() ?? summary.length;
    _sessionsThisWeek = (overview['sessions_this_week'] as num?)?.toInt() ?? 0;
    // Not part of the overview payload; left null so the tile shows an em dash
    // rather than a number the server never sent.
    _susAverage = null;

    return summary.map(_rowFrom).toList();
  }

  _ReaderRow _rowFrom(Map<String, dynamic> reader) {
    final participantId = reader['participant_id'] as String? ?? '';
    final name = reader['display_name'] as String? ?? participantId;
    final age = reader['age'];
    final sessionsTotal = (reader['sessions_total'] as num?)?.toInt() ?? 0;
    final sessionsWeek = (reader['sessions_this_week'] as num?)?.toInt() ?? 0;
    final minutesTotal = (reader['minutes_total'] as num?)?.toDouble() ?? 0;
    final lastReadAt = DateTime.tryParse(reader['last_read_at'] as String? ?? '');

    var lastActiveLabel = context.t.never;
    var statusLabel = context.t.noSessionsYet;
    var statusColor = AppColors.muted;

    if (lastReadAt != null) {
      lastActiveLabel = _relativeDate(context.t, lastReadAt.toLocal());
      final daysSince = DateTime.now().difference(lastReadAt.toLocal()).inDays;
      if (daysSince <= 7) {
        statusLabel = sessionsWeek > 1 ? context.t.readingRegularly : context.t.active;
        statusColor = AppColors.teal;
      } else if (daysSince <= 21) {
        statusLabel = context.t.quietLately;
        statusColor = AppColors.focus;
      } else {
        statusLabel = context.t.inactive;
        statusColor = AppColors.danger;
      }
    }

    final metaParts = [
      if (age != null) 'Age $age',
      if (sessionsTotal > 0)
        '$sessionsTotal session${sessionsTotal == 1 ? '' : 's'}',
    ];

    return _ReaderRow(
      participantId: participantId,
      name: name,
      meta: metaParts.join(' · '),
      lastActiveLabel: lastActiveLabel,
      wpmLabel: minutesTotal <= 0
          ? '—'
          : '${minutesTotal.toStringAsFixed(0)} min total',
      accuracyLabel: sessionsWeek == 0 ? '—' : '$sessionsWeek this week',
      // Bar reflects activity this week against a five-session target, since
      // the summary carries no per-quiz accuracy.
      accuracyFraction: (sessionsWeek / 5).clamp(0.0, 1.0),
      statusLabel: statusLabel,
      statusColor: statusColor,
    );
  }

  /// "3 days ago" rather than a date: a therapist scanning a roster is
  /// judging recency, not looking anything up by calendar day.
  static String _relativeDate(AppStrings t, DateTime when) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(when.year, when.month, when.day))
        .inDays;
    if (days <= 0) return t.today;
    if (days == 1) return t.yesterday;
    if (days < 7) return t.daysAgo(days);
    if (days < 30) return t.daysAgo(days);
    return '${when.day}/${when.month}/${when.year}';
  }

  Future<void> _promptStartSession(String participantId, String name) async {
    final condition = await showStartSessionSheet(context, name: name, participantId: participantId);
    if (condition == null || !mounted) return;
    await _startSession(participantId, name, condition);
  }

  /// Switches the app straight into this reader's own Home screen, with
  /// their assigned passages already loaded and settings forced to the
  /// chosen condition (or their own saved settings, under Custom) — the
  /// therapist hands the device over from here. [ParticipantState.
  /// isSupervisedByTherapist] is what makes the session banner appear on the
  /// reader's screens and gates "End session" behind a password, so the
  /// reader can't back out into therapist data by accident.
  Future<void> _startSession(String participantId, String name, ReadingProfile condition) async {
    final locked = condition != ReadingProfile.custom;
    context.read<ParticipantState>().signInAsReader(
          participantId,
          displayName: name,
          supervisedByTherapist: true,
          settingsLocked: locked,
        );
    if (condition == ReadingProfile.custom) {
      await loadReaderProfile(context, participantId);
    } else {
      // Forces the exact canonical preset regardless of whatever the reader
      // last saved for themselves — the whole point of the lock is every
      // "Default" or "Recommended" session looking identical across
      // participants, not "whatever this reader happened to leave it at".
      context.read<ReadingSettings>().applyProfile(condition);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
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
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.t.therapistRole, style: TextStyle(fontSize: 14, color: AppColors.onNavyMuted, fontWeight: FontWeight.w600)),
                            Text(context.t.myReaders, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                      IconOnlyButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TherapistProfileScreen()),
                        ),
                        tooltip: context.t.therapistProfile,
                        icon: Icons.account_circle_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  // IntrinsicHeight + stretch: "Sessions this week" wraps to
                  // two lines while the other two stay on one, and a plain
                  // Row won't stretch its Expanded children to match — this
                  // forces all three chips to the tallest one's height.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _StatChip(value: '$_readerCount', label: context.t.readers)),
                        const SizedBox(width: 8),
                        Expanded(child: _StatChip(value: '$_sessionsThisWeek', label: context.t.sessionsThisWeek)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatChip(
                            value: _susAverage == null ? '—' : _susAverage!.toStringAsFixed(0),
                            label: context.t.susAverage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.onNavyFaint),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v.trim()),
                            style: const TextStyle(fontSize: 15, color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: context.t.searchReaders,
                              hintStyle: TextStyle(color: AppColors.onNavyFaint),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: FutureBuilder<List<_ReaderRow>>(
                  future: _roster,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rows = snapshot.data!
                        .where((r) =>
                            _query.isEmpty ||
                            r.name.toLowerCase().contains(_query.toLowerCase()) ||
                            r.participantId.toLowerCase().contains(_query.toLowerCase()))
                        .toList();
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
                      children: [
                        Row(
                          children: [
                            Text(
                              context.t.activeCaseload,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.body),
                            ),
                            const Spacer(),
                            Text(context.t.sortedByLastActive, style: TextStyle(fontSize: 14, color: AppColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (rows.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              context.t.noReadersYet,
                              style: TextStyle(fontSize: 15, color: AppColors.muted),
                            ),
                          )
                        else
                          for (final row in rows) ...[
                            _ReaderCard(
                              row: row,
                              onTap: () => Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => ReaderDetailScreen(participantId: row.participantId),
                                    ),
                                  )
                                  .then((_) => _load()),
                              onStartSession: () => _promptStartSession(row.participantId, row.name),
                            ),
                            const SizedBox(height: 11),
                          ],
                        PrimaryButton(
                          label: context.t.addReader,
                          icon: Icons.person_add_rounded,
                          backgroundColor: AppColors.teal,
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const AddReaderScreen()))
                              .then((_) => _load()),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.t.dashboardMarkerNote,
                          style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
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
      bottomNavigationBar: const TherapistBottomTabBar(current: TherapistTab.dashboard),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.onNavyMuted, height: 1.3)),
        ],
      ),
    );
  }
}

class _ReaderCard extends StatelessWidget {
  const _ReaderCard({required this.row, required this.onTap, required this.onStartSession});

  final _ReaderRow row;
  final VoidCallback onTap;
  final VoidCallback onStartSession;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.navyTint, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: AppColors.navy),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.name,
                          style: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                        Text(row.meta, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              // Its own full-width line rather than squeezed beside the name
              // column — a long status label ("Accuracy dropping") would
              // otherwise crush the name into a sliver at large font sizes.
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(color: row.statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(row.statusLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.body)),
                    ],
                  ),
                  Text(row.lastActiveLabel, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                children: [
                  _Tag(row.wpmLabel, AppColors.navyTint, AppColors.navy),
                  _Tag('${row.accuracyLabel} accuracy', AppColors.tealTint, AppColors.tealText),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: row.accuracyFraction.clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: AppColors.trackAlt,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 11),
              SecondaryButton(
                label: context.t.startSession,
                icon: Icons.play_circle_fill_rounded,
                onPressed: onStartSession,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: foreground)),
    );
  }
}
