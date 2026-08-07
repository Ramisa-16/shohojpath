import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_content.dart';
import '../../services/reader_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_header.dart';
import '../../widgets/settings_controls.dart';

/// Screen `tassign` of the v2 design — a therapist picking which library
/// passages a reader should see. Each toggle writes straight to
/// [ReaderRepository.assignPassage]/[unassignPassage] so there is no separate
/// "confirm" step to forget; the reader's Home screen reads
/// [ReaderRepository.assignedPassageIds] to show what's been assigned to them.
class AssignPassageScreen extends StatefulWidget {
  const AssignPassageScreen({super.key, required this.participantId});

  final String participantId;

  @override
  State<AssignPassageScreen> createState() => _AssignPassageScreenState();
}

class _AssignPassageScreenState extends State<AssignPassageScreen> {
  String _category = 'All';
  String? _difficulty;
  Set<String> _assigned = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await context.read<ReaderRepository>().assignedPassageIds(widget.participantId);
    if (!mounted) return;
    setState(() {
      _assigned = ids.toSet();
      _loading = false;
    });
  }

  String _idFor(LibraryEntry e) => e.passage?.id ?? e.title;

  Future<void> _toggle(LibraryEntry e) async {
    final id = _idFor(e);
    final repo = context.read<ReaderRepository>();
    if (_assigned.contains(id)) {
      await repo.unassignPassage(widget.participantId, id);
      if (!mounted) return;
      setState(() => _assigned.remove(id));
    } else {
      await repo.assignPassage(widget.participantId, id);
      if (!mounted) return;
      setState(() => _assigned.add(id));
    }
  }

  bool _matchesCategory(LibraryEntry e) {
    if (_category == 'All') return true;
    return e.category.toLowerCase().contains(_category.toLowerCase());
  }

  bool _matchesDifficulty(LibraryEntry e) => _difficulty == null || e.level == _difficulty;

  @override
  Widget build(BuildContext context) {
    final results = MockContent.library
        .where((e) => _matchesCategory(e) && _matchesDifficulty(e))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Assign Passages', onBack: () => Navigator.of(context).maybePop()),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: SizedBox(
                height: ChoiceTile.minHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: MockContent.libraryCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 7),
                  itemBuilder: (context, i) {
                    final c = MockContent.libraryCategories[i];
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
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DIFFICULTY',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.body),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: ChoiceTile.minHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: MockContent.libraryDifficulties.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final d = MockContent.libraryDifficulties[i];
                        final selected = _difficulty == d;
                        return ChoiceTile(
                          label: d,
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
                '${_assigned.length} passage${_assigned.length == 1 ? '' : 's'} assigned to ${widget.participantId}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.tealText),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : results.isEmpty
                        ? const Center(
                            child: Text('No passages match these filters.', style: TextStyle(fontSize: 15, color: AppColors.muted)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: results.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 11),
                            itemBuilder: (context, i) {
                              final entry = results[i];
                              final isAssigned = _assigned.contains(_idFor(entry));
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
                                              _Tag(entry.time, AppColors.navyTint, AppColors.navy),
                                              _Tag(entry.level, AppColors.tealTint, AppColors.tealDeep),
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
