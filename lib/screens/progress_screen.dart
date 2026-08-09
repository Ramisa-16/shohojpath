import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/shohojpath_api.dart';
import '../theme/app_colors.dart';
import '../widgets/api_data.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/settings_controls.dart';
import 'statistics_screen.dart';

/// Screen 07 of the design — the reader's own progress, computed on the
/// server from their synced sessions.
///
/// Every figure here is derived rather than counted into a stored total, so a
/// number on screen can always be traced back to the rows the study exports.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final api = context.read<ShohojpathApi>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'My Progress',
              onBack: showBack ? () => Navigator.of(context).maybePop() : null,
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ApiData<Map<String, dynamic>>(
                  load: api.myProgress,
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
    final minutesToday = (data['minutes_today'] as num?)?.toDouble() ?? 0;
    final pagesToday = (data['pages_today'] as num?)?.toInt() ?? 0;
    final sessions = (data['sessions_total'] as num?)?.toInt() ?? 0;
    final current = data['current_passage'] as Map?;
    final week = (data['week'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (sessions == 0)
          const ApiMessage(
            icon: Icons.auto_stories_outlined,
            title: 'No reading recorded yet',
            body: 'Finish a passage and your time, pages and progress will '
                'appear here.',
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.schedule_rounded,
                  value: minutesToday == minutesToday.roundToDouble()
                      ? '${minutesToday.toInt()}'
                      : minutesToday.toStringAsFixed(1),
                  unit: ' min',
                  label: 'Time today',
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _StatTile(
                  icon: Icons.description_rounded,
                  value: '$pagesToday',
                  unit: pagesToday == 1 ? ' page' : ' pages',
                  label: 'Pages read',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (current != null) _CurrentPassageCard(current: current),
          if (current != null) const SizedBox(height: 12),
          _WeekCard(week: week),
          const SizedBox(height: 12),
        ],
        ListRowButton(
          leading: const Icon(Icons.analytics_rounded,
              color: AppColors.navy, size: 24),
          title: 'Detailed reading statistics',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StatisticsScreen()),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: AppColors.tealText),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: const TextStyle(fontSize: 15, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _CurrentPassageCard extends StatelessWidget {
  const _CurrentPassageCard({required this.current});

  final Map current;

  @override
  Widget build(BuildContext context) {
    final percent = (current['percent'] as num?)?.toDouble();
    final available = current['available'] != false;
    final title = current['title'] as String? ??
        (current['passage_id'] as String? ?? '');
    final pagesRead = (current['pages_read'] as num?)?.toInt() ?? 0;
    final pageCount = (current['page_count'] as num?)?.toInt() ?? 0;

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  'Current passage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                percent == null ? '—' : '${percent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tealText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (percent != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: (percent / 100).clamp(0, 1),
                minHeight: 10,
                backgroundColor: AppColors.trackAlt,
                color: AppColors.teal,
              ),
            ),
          const SizedBox(height: 9),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'NotoSansBengali',
              fontSize: 16,
              color: AppColors.body,
            ),
          ),
          if (pageCount > 0) ...[
            const SizedBox(height: 3),
            Text(
              'Page $pagesRead of $pageCount',
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ] else if (!available) ...[
            const SizedBox(height: 3),
            const Text(
              'No longer in the library — your reading is still recorded.',
              style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final List<Map<String, dynamic>> week;

  static const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final minutes = [
      for (final day in week) (day['minutes'] as num?)?.toDouble() ?? 0,
    ];
    // Scaled against the busiest day rather than a fixed ceiling, so a quiet
    // week still shows relative shape instead of seven flat stubs.
    final peak = minutes.isEmpty
        ? 0.0
        : minutes.reduce((a, b) => a > b ? a : b);

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This week',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 116,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < week.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.5),
                      child: _Bar(
                        minutes: minutes[i],
                        fraction: peak == 0 ? 0 : minutes[i] / peak,
                        label: _label(week[i], i),
                        isToday: i == week.length - 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _label(Map<String, dynamic> day, int index) {
    final iso = day['date'] as String?;
    if (iso == null) return _weekdayInitials[index % 7];
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return _weekdayInitials[index % 7];
    return _weekdayInitials[(parsed.weekday - 1) % 7];
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.minutes,
    required this.fraction,
    required this.label,
    required this.isToday,
  });

  final double minutes;
  final double fraction;
  final String label;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (minutes > 0)
          Text(
            minutes < 1 ? '<1' : minutes.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        const SizedBox(height: 3),
        Expanded(
          child: FractionallySizedBox(
            alignment: Alignment.bottomCenter,
            // A day with any reading keeps a visible stub, so "a little" and
            // "none" never look the same.
            heightFactor: minutes == 0 ? 0.02 : (0.08 + fraction * 0.92),
            child: Container(
              decoration: BoxDecoration(
                color: minutes == 0
                    ? AppColors.track
                    : (isToday ? AppColors.tealSoft : AppColors.teal),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                  bottom: Radius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.body,
          ),
        ),
      ],
    );
  }
}
