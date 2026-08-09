import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/shohojpath_api.dart';
import '../services/passage_repository.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/duration_format.dart';
import '../widgets/api_data.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/settings_controls.dart';
import 'reading_screen.dart';

/// Screen 08 of the design — every session this reader has synced.
///
/// Takes an optional [participantId] so a therapist opens the same screen for
/// one of their readers rather than a parallel implementation that could
/// disagree with what the reader sees.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.participantId, this.readerName});

  final String? participantId;
  final String? readerName;

  @override
  Widget build(BuildContext context) {
    final api = context.read<ShohojpathApi>();
    final id = participantId;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: context.t.readingHistoryTitle,
              subtitle: readerName,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ApiData<List<Map<String, dynamic>>>(
                  load: () =>
                      id == null ? api.mySessions() : api.readerSessions(id),
                  isEmpty: (rows) => rows.isEmpty,
                  emptyIcon: Icons.history_rounded,
                  emptyTitle: context.t.noSessionsYet,
                  emptyBody: id == null
                      ? 'Finished readings appear here once they have synced.'
                      : 'This reader has not completed a session yet.',
                  builder: (context, rows, refresh) => RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: rows.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 11),
                      itemBuilder: (context, i) => _SessionCard(
                        session: rows[i],
                        canContinue: id == null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  const _SessionCard({required this.session, required this.canContinue});

  final Map<String, dynamic> session;
  final bool canContinue;

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _opening = false;

  Future<void> _continue() async {
    setState(() => _opening = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final passageId = widget.session['passage_id'] as String? ?? '';

    final passage =
        await context.read<PassageRepository>().passage(passageId);
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
    final s = widget.session;
    final passageId = s['passage_id'] as String? ?? '';
    final seconds = (s['total_reading_seconds'] as num?)?.toDouble() ?? 0;
    final quizScore = (s['quiz_score'] as num?)?.toInt();
    final quizTotal = (s['quiz_total'] as num?)?.toInt();
    final profile = s['profile'] as String? ?? '';
    final readAloud = s['read_aloud_on'] == true;
    final started = DateTime.tryParse(s['started_at'] as String? ?? '');

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  passageId,
                  style: const TextStyle(
                    fontFamily: 'NotoSansBengali',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                started == null ? '' : _relativeDay(started),
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Fact(
                icon: Icons.schedule_rounded,
                text: formatDuration(Duration(seconds: seconds.round())),
              ),
              if (quizTotal != null && quizTotal > 0)
                _Fact(
                  icon: Icons.done_all_rounded,
                  text: '${quizScore ?? 0} / $quizTotal',
                ),
              _Fact(
                icon: readAloud
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                text: readAloud ? context.t.readAloudLabel : context.t.noAudio,
              ),
            ],
          ),
          if (profile.isNotEmpty) ...[
            const SizedBox(height: 9),
            BadgeChip(_profileLabel(profile)),
          ],
          if (widget.canContinue) ...[
            const SizedBox(height: 9),
            PrimaryButton(
              label: _opening ? context.t.opening : context.t.readAgain,
              onPressed: _opening ? null : _continue,
            ),
          ],
        ],
      ),
    );
  }

  static String _profileLabel(String id) => switch (id) {
        'default' => 'Default condition',
        'recommended' => 'Recommended condition',
        'custom' => 'Custom condition',
        _ => id,
      };

  /// "Today"/"Yesterday" rather than a date, because that is how a reader
  /// thinks about their own last few sessions.
  static String _relativeDay(DateTime when) {
    final now = DateTime.now();
    final local = when.toLocal();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(local.year, local.month, local.day))
        .inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.body),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 14, color: AppColors.body)),
      ],
    );
  }
}
