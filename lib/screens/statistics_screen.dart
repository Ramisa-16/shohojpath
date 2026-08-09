import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/shohojpath_api.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/duration_format.dart';
import '../widgets/api_data.dart';
import '../widgets/app_header.dart';
import '../widgets/settings_controls.dart';

/// Screen 10 of the design — reading statistics, all derived on the server
/// from synced sessions.
///
/// Takes an optional [participantId] so a therapist can open exactly the same
/// screen for one of their readers: the figures must not differ between who is
/// looking at them.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, this.participantId, this.readerName});

  /// Null means "the signed-in reader's own statistics".
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
              title: context.t.readingStatistics,
              subtitle: readerName,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ApiData<Map<String, dynamic>>(
                  load: () => id == null
                      ? api.myStatistics()
                      : api.readerStatistics(id),
                  builder: (context, data, refresh) => RefreshIndicator(
                    onRefresh: refresh,
                    child: _Body(data: data),
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

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final sessions = (data['sessions_logged'] as num?)?.toInt() ?? 0;
    if (sessions == 0) {
      return ListView(
        children: [
          SizedBox(height: 60),
          ApiMessage(
            icon: Icons.query_stats_outlined,
            title: context.t.noStatisticsYet,
            body: 'Reading speed, comprehension and settings use are '
                'calculated once the first session has been completed and '
                'synced.',
          ),
        ],
      );
    }

    final wordsWeek = (data['words_this_week'] as num?)?.toInt() ?? 0;
    final delta = (data['words_delta_vs_last_week'] as num?)?.toInt() ?? 0;
    final wpm = (data['words_per_minute'] as num?)?.toDouble();
    final comprehension = (data['comprehension_percent'] as num?)?.toDouble();
    final readAloud = (data['read_aloud_percent'] as num?)?.toDouble() ?? 0;
    final finished = (data['passages_finished'] as num?)?.toInt() ?? 0;
    final avgSeconds = (data['average_session_seconds'] as num?)?.toDouble() ?? 0;
    final mostChanged = (data['most_changed_settings'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.wordsReadThisWeek,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.84,
                  color: AppColors.onNavyMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$wordsWeek',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              Text(
                delta == 0
                    ? context.t.sameAsLastWeek
                    : '${delta > 0 ? '▲' : '▼'} ${delta.abs()} words vs last week',
                style: TextStyle(
                  fontSize: 15,
                  color: delta >= 0
                      ? const Color(0xFF8FD9D1)
                      : const Color(0xFFF0B9B9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // stretch pairs the two cards to a common height so their notes line
        // up, but a Row inside this ListView has unbounded height — without
        // IntrinsicHeight to measure it first, "stretch" means infinity.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  title: context.t.readingSpeed,
                  value: wpm == null ? '—' : wpm.toStringAsFixed(0),
                  unit: ' wpm',
                  note: 'Speed is read alongside accuracy.',
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _MetricCard(
                  title: context.t.comprehension,
                  value: comprehension == null
                      ? '—'
                      : comprehension.toStringAsFixed(0),
                  unit: '%',
                  note: comprehension == null
                      ? 'No quiz completed yet.'
                      : 'Across all quizzes taken.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      context.t.readAloudUsed,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${readAloud.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.tealText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: (readAloud / 100).clamp(0, 1),
                  minHeight: 10,
                  backgroundColor: AppColors.trackAlt,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Percentage of sessions where audio support was switched on.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.body,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SmallStat(
                  label: context.t.averageSession,
                  value: formatDurationLong(
                    Duration(seconds: avgSeconds.round()),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _SmallStat(
                  label: context.t.sessionsLogged,
                  value: '$sessions',
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
                child: _SmallStat(
                  label: context.t.passagesRead,
                  value: '$finished',
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _SmallStat(
                  label: context.t.wordsPerMinute,
                  value: wpm == null ? '—' : wpm.toStringAsFixed(1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t.settingsChangedMost,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Which controls this reader actually reaches for, straight '
                'from the settings-change log.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              if (mostChanged.isEmpty)
                Text(
                  context.t.noSettingsChanged,
                  style: TextStyle(fontSize: 15, color: AppColors.body),
                )
              else
                for (final row in mostChanged) ...[
                  _ChangeBar(
                    label: _prettyKey(row['key'] as String? ?? ''),
                    changes: (row['changes'] as num?)?.toInt() ?? 0,
                    peak: mostChanged
                        .map((r) => (r['changes'] as num?)?.toInt() ?? 0)
                        .fold<int>(1, (a, b) => a > b ? a : b),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ],
    );
  }

  /// `font_size` reads as a database column, not a control the reader touched.
  static String _prettyKey(String key) {
    if (key.isEmpty) return '—';
    final words = key.split('_');
    return words.first[0].toUpperCase() +
        words.first.substring(1) +
        (words.length > 1 ? ' ${words.sublist(1).join(' ')}' : '');
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.note,
  });

  final String title;
  final String value;
  final String unit;
  final String note;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.body,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.body,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeBar extends StatelessWidget {
  const _ChangeBar({
    required this.label,
    required this.changes,
    required this.peak,
  });

  final String label;
  final int changes;
  final int peak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: AppColors.body),
              ),
            ),
            Text(
              '$changes',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: peak == 0 ? 0 : (changes / peak).clamp(0, 1),
            minHeight: 7,
            backgroundColor: AppColors.trackAlt,
            color: AppColors.teal,
          ),
        ),
      ],
    );
  }
}
