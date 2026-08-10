import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/shohojpath_api.dart';
import '../../data/passages.dart';
import '../../services/session_logger.dart';
import '../../theme/app_colors.dart';
import '../../utils/duration_format.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/export_data_action.dart';
import '../../widgets/settings_controls.dart';
import '../../widgets/sparkline.dart';
import 'assign_passage_screen.dart';
import '../../l10n/app_strings.dart';

enum _ReaderTab { progress, sessions, settings, notes }

/// Screen `treader` of the v2 design — one reader's real progress, session
/// history, settings usage and therapist notes, all computed from
/// [SessionLogger] rows for [participantId] rather than the design's static
/// mock arrays.
class ReaderDetailScreen extends StatefulWidget {
  const ReaderDetailScreen({super.key, required this.participantId});

  final String participantId;

  @override
  State<ReaderDetailScreen> createState() => _ReaderDetailScreenState();
}

class _ReaderDetailScreenState extends State<ReaderDetailScreen> {
  _ReaderTab _tab = _ReaderTab.progress;
  late Future<_ReaderData> _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _data = _fetch());
  }

  /// Everything about one reader, from the server.
  ///
  /// The therapist sees the same figures the reader sees — progress and
  /// statistics come from the same server-side computation, so the two can
  /// never disagree about the same sessions.
  Future<_ReaderData> _fetch() async {
    final api = context.read<ShohojpathApi>();
    final id = widget.participantId;

    final progress = await api.readerProgress(id);
    final statistics = await api.readerStatistics(id);
    final sessions = await api.readerSessions(id);
    final notes = await api.readerNotes(id);

    return _ReaderData(
      reader: {
        'participant_id': id,
        'name': progress['display_name'],
      },
      sessions: sessions,
      notes: notes,
      progress: progress,
      statistics: statistics,
    );
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t.addNote),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(hintText: context.t.notePrompt),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.tOnce.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(context.tOnce.save),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    await context
        .read<ShohojpathApi>()
        .addReaderNote(widget.participantId, text);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_ReaderData>(
          future: _data,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final name = data.reader?['name'] as String? ?? widget.participantId;
            final age = data.reader?['age'];
            final classGrade = data.reader?['class_grade'] as String?;
            final createdAt = DateTime.tryParse(data.reader?['created_at'] as String? ?? '');

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.navy,
                  padding: const EdgeInsets.fromLTRB(6, 8, 14, 14),
                  child: Row(
                    children: [
                      IconOnlyButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: context.t.back,
                        icon: Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Wraps rather than truncates: a name cut off
                            // with an ellipsis is exactly the "must wrap"
                            // header the therapist can't fully read.
                            Text(
                              name,
                              style: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(
                              [
                                if (age != null) 'Age $age',
                                if (classGrade != null && classGrade.isNotEmpty) classGrade,
                                if (createdAt != null) 'Since ${_monthYear(createdAt)}',
                              ].join(' · '),
                              style: const TextStyle(fontSize: 14, color: AppColors.onNavyMuted),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => exportAndShareCsv(context),
                        icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                        label: Text(context.t.export, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                ColoredBox(
                  color: Colors.white,
                  child: _ReaderTabBar(
                    current: _tab,
                    onSelect: (tab) => setState(() => _tab = tab),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.canvas,
                    child: switch (_tab) {
                      _ReaderTab.progress => _ProgressTab(data: data, participantId: widget.participantId),
                      _ReaderTab.sessions => _SessionsTab(data: data),
                      _ReaderTab.settings => _SettingsTab(data: data),
                      _ReaderTab.notes => _NotesTab(data: data, onAddNote: _addNote),
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _monthYear(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _ReaderData {
  const _ReaderData({
    required this.reader,
    required this.sessions,
    required this.notes,
    this.progress = const {},
    this.statistics = const {},
  });

  final Map<String, Object?>? reader;
  final List<Map<String, Object?>> sessions;
  final List<Map<String, Object?>> notes;

  /// Server-computed, identical to what the reader sees on their own screens.
  final Map<String, dynamic> progress;
  final Map<String, dynamic> statistics;
}

/// The four tabs stretch evenly across the bar when they fit at a sensible
/// minimum width, and fall back to a horizontally-scrolling row instead of
/// squeezing once they don't — never a fixed 4-across [Row].
class _ReaderTabBar extends StatelessWidget {
  const _ReaderTabBar({required this.current, required this.onSelect});

  final _ReaderTab current;
  final ValueChanged<_ReaderTab> onSelect;

  static const _minTabWidth = 90.0;
  static String _label(AppStrings t, _ReaderTab tab) => switch (tab) {
        _ReaderTab.progress => t.tabProgress,
        _ReaderTab.sessions => t.sessions,
        _ReaderTab.settings => t.settings,
        _ReaderTab.notes => t.notes,
      };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabs = [
          for (final tab in _ReaderTab.values)
            _TabButton(label: _label(context.t, tab), selected: tab == current, onTap: () => onSelect(tab)),
        ];
        if (constraints.maxWidth >= _minTabWidth * _ReaderTab.values.length) {
          return Row(children: [for (final t in tabs) Expanded(child: t)]);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [for (final t in tabs) SizedBox(width: _minTabWidth, child: t)],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? AppColors.navy : Colors.transparent, width: 3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? AppColors.navy : AppColors.muted),
        ),
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({required this.data, required this.participantId});

  final _ReaderData data;
  final String participantId;

  @override
  Widget build(BuildContext context) {
    final chronological = data.sessions.reversed.toList();
    final speedSeries = <double>[];
    final accSeries = <double>[];
    var totalWords = 0;
    var totalSeconds = 0.0;
    var quizPctSum = 0.0;
    var quizPctCount = 0;
    var audioOnCount = 0;
    var audioKnownCount = 0;

    for (final s in chronological) {
      final seconds = (s['total_reading_seconds'] as num?)?.toDouble();
      final words = (s['words_read'] as num?)?.toInt();
      if (seconds != null) totalSeconds += seconds;
      if (words != null) totalWords += words;
      if (seconds != null && seconds > 0 && words != null) {
        speedSeries.add(words / seconds * 60);
      }
      final qs = (s['quiz_score'] as num?)?.toInt();
      final qt = (s['quiz_total'] as num?)?.toInt();
      if (qs != null && qt != null && qt > 0) {
        final pct = qs / qt * 100;
        accSeries.add(pct);
        quizPctSum += pct;
        quizPctCount++;
      }
      final audioOn = s['read_aloud_on'];
      if (audioOn != null) {
        audioKnownCount++;
        if (audioOn == 1) audioOnCount++;
      }
    }

    final totalDuration = Duration(seconds: totalSeconds.round());
    final comprehensionAvg = quizPctCount == 0 ? null : quizPctSum / quizPctCount;
    final audioUsagePct = audioKnownCount == 0 ? null : audioOnCount / audioKnownCount * 100;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(context.t.readingSpeedHeading, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.body)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    speedSeries.isEmpty ? '—' : '${speedSeries.last.round()} wpm',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.tealText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Sparkline(values: speedSeries, color: AppColors.navy),
              const SizedBox(height: 6),
              Text('${chronological.length} session${chronological.length == 1 ? '' : 's'} logged', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(context.t.accuracyHeading, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.body)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    accSeries.isEmpty ? '—' : '${accSeries.last.round()}%',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.tealText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Sparkline(values: accSeries, color: AppColors.teal),
              const SizedBox(height: 6),
              Text(context.t.quizScorePerPassage, style: TextStyle(fontSize: 14, color: AppColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Two rows built from IntrinsicHeight, not GridView.count: a fixed
        // childAspectRatio pins each cell's height as a function of its
        // width, which clips the value/label text at large font sizes
        // instead of letting the row grow to fit it.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _StatTile(value: '$totalWords', label: context.t.totalWordsRead)),
              const SizedBox(width: 11),
              Expanded(child: _StatTile(value: formatDurationLong(totalDuration), label: context.t.totalReadingTime)),
            ],
          ),
        ),
        const SizedBox(height: 11),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  value: comprehensionAvg == null ? '—' : '${comprehensionAvg.round()}%',
                  label: context.t.comprehensionAverage,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: _StatTile(
                  value: audioUsagePct == null ? '—' : '${audioUsagePct.round()}%',
                  label: context.t.readAloudUsage,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: context.t.assignPassages,
          icon: Icons.playlist_add_rounded,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AssignPassageScreen(participantId: participantId)),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.navy)),
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.35)),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.data});

  final _ReaderData data;

  @override
  Widget build(BuildContext context) {
    if (data.sessions.isEmpty) {
      return Center(
        child: Text(context.t.noSessionsLogged, style: TextStyle(fontSize: 15, color: AppColors.muted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: data.sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = data.sessions[i];
        final title = Passages.titleFor(s['passage_id'] as String);
        final startedAt = DateTime.tryParse(s['started_at'] as String? ?? '');
        final seconds = (s['total_reading_seconds'] as num?)?.toDouble();
        final quizScore = s['quiz_score'];
        final quizTotal = s['quiz_total'];
        final audioOn = s['read_aloud_on'] == 1;
        final audioKnown = s['read_aloud_on'] != null;

        return WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ),
                  Text(startedAt == null ? '' : _shortDate(startedAt), style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if (seconds != null) _Chip(formatDuration(Duration(seconds: seconds.round())), AppColors.navyTint, AppColors.navy),
                  if (quizScore != null && quizTotal != null) _Chip('Quiz $quizScore / $quizTotal', AppColors.navyTint, AppColors.navy),
                  if (audioKnown)
                    _Chip(
                      audioOn ? context.t.audioOnShort : context.t.audioOffShort,
                      audioOn ? AppColors.tealTint : AppColors.chipNeutral,
                      audioOn ? AppColors.tealDeep : AppColors.muted,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _shortDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.background, this.foreground);

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

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.data});

  final _ReaderData data;

  @override
  Widget build(BuildContext context) {
    final sessions = data.sessions;
    double? pctWhere(bool Function(Map<String, Object?>) test, {bool Function(Map<String, Object?>)? known}) {
      final knownSessions = known == null ? sessions : sessions.where(known).toList();
      if (knownSessions.isEmpty) return null;
      return knownSessions.where(test).length / knownSessions.length * 100;
    }

    final readAloudPct = pctWhere(
      (s) => s['read_aloud_on'] == 1,
      known: (s) => s['read_aloud_on'] != null,
    );
    final recommendedPct = pctWhere((s) => s['profile'] == 'recommended');
    final defaultPct = pctWhere((s) => s['profile'] == 'default');
    final customPct = pctWhere((s) => s['profile'] == 'custom');

    final bars = <(String, double?)>[
      (context.t.readAloudUsed, readAloudPct),
      (context.t.profileNamed(context.t.profileRecommended), recommendedPct),
      (context.t.profileNamed(context.t.profileDefault), defaultPct),
      (context.t.profileNamed(context.t.profileCustom), customPct),
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t.settingsActuallyUsed, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
              const SizedBox(height: 5),
              const Text(
                "Share of this reader's sessions where each was active.",
                style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 14),
              if (sessions.isEmpty)
                Text(context.t.noSessionsLogged, style: TextStyle(fontSize: 15, color: AppColors.muted))
              else
                for (final (label, pct) in bars) ...[
                  Row(
                    children: [
                      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.body))),
                      Text(pct == null ? '—' : '${pct.round()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.tealText)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: (pct ?? 0) / 100,
                      minHeight: 9,
                      backgroundColor: AppColors.trackAlt,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.data, required this.onAddNote});

  final _ReaderData data;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        for (final note in data.notes) ...[
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatted(note['at'] as String? ?? ''),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.tealText, letterSpacing: 0.4),
                ),
                const SizedBox(height: 4),
                Text(note['text'] as String? ?? '', style: const TextStyle(fontSize: 15, color: AppColors.body, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (data.notes.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(context.t.noNotesYet, style: TextStyle(fontSize: 15, color: AppColors.muted)),
          ),
        PrimaryButton(
          label: context.t.addNote,
          icon: Icons.edit_note_rounded,
          backgroundColor: AppColors.teal,
          onPressed: onAddNote,
        ),
      ],
    );
  }

  static String _formatted(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
