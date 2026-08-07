import 'package:flutter/material.dart';

import '../data/mock_content.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/settings_controls.dart';
import 'reading_screen.dart';

/// Screen 04 of the design — the Library tab of [HomeShell].
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _category = 'All';
  String? _difficulty;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesCategory(LibraryEntry e) {
    if (_category == 'All') return true;
    return e.category.toLowerCase().contains(_category.toLowerCase());
  }

  bool _matchesDifficulty(LibraryEntry e) =>
      _difficulty == null || e.level == _difficulty;

  bool _matchesSearch(LibraryEntry e) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return e.title.toLowerCase().contains(q) ||
        e.category.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final results = MockContent.library
        .where((e) => _matchesCategory(e) && _matchesDifficulty(e) && _matchesSearch(e))
        .toList();

    return Column(
      children: [
        const AppHeader(title: 'Reading Library'),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by title or topic',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.body,
                  ),
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
        Expanded(
          child: Container(
            color: AppColors.canvas,
            child: results.isEmpty
                ? const Center(
                    child: Text(
                      'No passages match these filters.',
                      style: TextStyle(fontSize: 15, color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 11),
                    itemBuilder: (context, i) {
                      final entry = results[i];
                      return WhiteCard(
                        onTap: () {
                          final passage = entry.passage;
                          if (passage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '"${entry.title}" is sample content — no full passage is wired up yet.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ReadingScreen(passage: passage)),
                          );
                        },
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
                                    style: const TextStyle(
                                      fontFamily: 'NotoSansBengali',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
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
                            const Icon(Icons.bookmark_border_rounded, color: AppColors.muted),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
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
