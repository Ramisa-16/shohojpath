import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_exception.dart';
import '../../api/shohojpath_api.dart';
import '../../models/passage.dart';
import '../../services/passage_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_header.dart';
import '../../widgets/settings_controls.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/therapist_bottom_tab_bar.dart';
import '../../l10n/label_extensions.dart';

/// Screen `tassign` of the v2 design — a therapist picking which library
/// passages a reader should see. Each toggle writes straight to
/// [ReaderRepository.assignPassage]/[unassignPassage] so there is no separate
/// "confirm" step to forget; the reader's Home screen reads
/// [ReaderRepository.assignedPassageIds] to show what's been assigned to them.
class AssignPassageScreen extends StatefulWidget {
  const AssignPassageScreen({
    super.key,
    required this.participantId,
    this.readerName,
  });

  final String participantId;

  /// Shown instead of the participant id where there is one. The id is how
  /// the study records a child; it is not what their therapist calls them.
  final String? readerName;

  @override
  State<AssignPassageScreen> createState() => _AssignPassageScreenState();
}

class _AssignPassageScreenState extends State<AssignPassageScreen> {
  String _category = 'All';
  PassageDifficulty? _difficulty;
  Set<String> _assigned = {};
  List<Passage> _passages = const [];
  List<String> _categories = const ['All'];
  static const List<PassageDifficulty> _difficulties = PassageDifficulty.values;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// The catalogue and what is already set for this reader, both from the
  /// server — a therapist must be assigning from the same library the
  /// reader will actually see, not a list compiled into the app.
  Future<void> _load() async {
    final api = context.read<ShohojpathApi>();
    try {
      final passages = await context.read<PassageRepository>().library();
      final assignments = await api.readerAssignments(widget.participantId);
      if (!mounted) return;
      setState(() {
        _passages = passages;
        _categories = {'All', for (final p in passages) p.category}.toList();
        _assigned = {
          for (final a in assignments) a['passage_id'] as String,
        };
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.messageFor(context.tOnce);
      });
    }
  }

  Future<void> _toggle(Passage passage) async {
    final id = passage.id;
    final api = context.read<ShohojpathApi>();
    final wasAssigned = _assigned.contains(id);

    // Optimistic, then reverted on failure: tapping a row should feel
    // immediate, but a failed request must not leave the tick showing a
    // state the server never accepted.
    setState(() => wasAssigned ? _assigned.remove(id) : _assigned.add(id));
    try {
      if (wasAssigned) {
        await api.unassignPassage(widget.participantId, id);
      } else {
        await api.assignPassage(
          participantId: widget.participantId,
          passageId: id,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => wasAssigned ? _assigned.add(id) : _assigned.remove(id));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.messageFor(context.tOnce))));
    }
  }

  bool _matchesCategory(Passage p) =>
      _category == 'All' ||
      p.category.toLowerCase().contains(_category.toLowerCase());

  bool _matchesDifficulty(Passage p) =>
      _difficulty == null ||
      p.difficulty == _difficulty;

  @override
  Widget build(BuildContext context) {
    final results = _passages
        .where((p) => _matchesCategory(p) && _matchesDifficulty(p))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: context.t.assignPassagesTitle, onBack: () => Navigator.of(context).maybePop()),
            // Hidden when there is only one category, because then "All" and
            // that category select exactly the same passages — two chips that
            // do the same thing teach the therapist nothing and cost a row.
            if (_categories.length > 2)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: SizedBox(
                height: ChoiceTile.minHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 7),
                  itemBuilder: (context, i) {
                    final c = _categories[i];
                    return ChoiceTile(
                      label: c,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    );
                  },
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.t.difficulty,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.body),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: ChoiceTile.minHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _difficulties.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final d = _difficulties[i];
                        final label = d.localisedLabel(context.t);
                        final selected = _difficulty == d;
                        return ChoiceTile(
                          label: label,
                          selected: selected,
                          onTap: () => setState(() => _difficulty = selected ? null : d),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.tealTintSoft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Text(
                context.t.assignedCount(
                  _assigned.length,
                  widget.readerName ?? widget.participantId,
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.tealText),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      )
                    : results.isEmpty
                        ? Center(
                            child: Text(context.t.noPassagesMatch, style: TextStyle(fontSize: 15, color: AppColors.muted)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: results.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 11),
                            itemBuilder: (context, i) {
                              final entry = results[i];
                              final isAssigned = _assigned.contains(entry.id);
                              return WhiteCard(
                                onTap: () => _toggle(entry),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.navyTint,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.menu_book_rounded, color: AppColors.navy),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.title,
                                            style: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(entry.category, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            children: [
                                              _Tag('${entry.estimatedMinutes} min', AppColors.navyTint, AppColors.navy),
                                              _Tag(entry.difficulty.localisedLabel(context.t), AppColors.tealTint, AppColors.tealDeep),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isAssigned ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                      color: isAssigned ? AppColors.teal : AppColors.muted,
                                      size: 26,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    
      bottomNavigationBar:

          const TherapistBottomTabBar(current: TherapistTab.dashboard),

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
