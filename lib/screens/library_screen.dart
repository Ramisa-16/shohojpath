import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/passage.dart';
import '../services/passage_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/api_data.dart';
import '../widgets/app_header.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/settings_controls.dart';
import 'reading_screen.dart';

/// Screen 04 of the design — the passage library, served from the backend so
/// a researcher can change study material without shipping a new APK.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  final _search = TextEditingController();
  Timer? _debounce;

  String _category = 'All';
  String? _difficulty;
  int _version = 0;

  List<String> _categories = const ['All'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await context.read<PassageRepository>().categories();
    if (!mounted) return;
    setState(() => _categories = categories);
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => setState(() => _version++),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PassageRepository>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Reading Library',
              onBack:
                  widget.showBack ? () => Navigator.of(context).maybePop() : null,
              bottom: AuthFormField(
                label: '',
                controller: _search,
                icon: Icons.search_rounded,
                hint: 'Search by title or topic',
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => setState(() => _version++),
              ),
            ),
            _Filters(
              categories: _categories,
              difficulties: _difficulties,
              category: _category,
              difficulty: _difficulty,
              onCategory: (c) => setState(() {
                _category = c;
                _version++;
              }),
              onDifficulty: (d) => setState(() {
                _difficulty = _difficulty == d ? null : d;
                _version++;
              }),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ApiData<List<Passage>>(
                  key: ValueKey('$_version|$_category|$_difficulty'),
                  load: () => repo.library(
                    search: _search.text.trim(),
                    category: _category == 'All' ? null : _category,
                    difficulty: _difficulty?.toLowerCase(),
                  ),
                  isEmpty: (rows) => rows.isEmpty,
                  emptyIcon: Icons.menu_book_outlined,
                  emptyTitle: 'No passages found',
                  emptyBody: 'Try a different search or filter. Passages are '
                      'added by the research team in the admin.',
                  builder: (context, passages, refresh) => RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: passages.length + (repo.usingBundledFallback ? 1 : 0),
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 11),
                      itemBuilder: (context, i) {
                        if (repo.usingBundledFallback && i == 0) {
                          return const _OfflineNotice();
                        }
                        final passage = passages[
                            i - (repo.usingBundledFallback ? 1 : 0)];
                        return _PassageCard(passage: passage);
                      },
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

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.chipNeutral,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 20, color: AppColors.muted),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Offline — showing the passage bundled with the app. Connect to '
              'see the full library.',
              style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.categories,
    required this.difficulties,
    required this.category,
    required this.difficulty,
    required this.onCategory,
    required this.onDifficulty,
  });

  final List<String> categories;
  final List<String> difficulties;
  final String category;
  final String? difficulty;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onDifficulty;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              itemCount: categories.length,
              separatorBuilder: (context, i) => const SizedBox(width: 7),
              itemBuilder: (context, i) => _Chip(
                label: categories[i],
                selected: categories[i] == category,
                onTap: () => onCategory(categories[i]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'DIFFICULTY',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: AppColors.body,
                  ),
                ),
                for (final d in difficulties)
                  _Chip(
                    label: d,
                    selected: d == difficulty,
                    teal: true,
                    onTap: () => onDifficulty(d),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.teal = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool teal;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? (teal ? AppColors.tealTint : AppColors.navy)
        : Colors.white;
    final foreground = selected
        ? (teal ? AppColors.tealDeep : Colors.white)
        : AppColors.body;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: selected
                ? (teal ? Border.all(color: AppColors.teal, width: 1.5) : null)
                : Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _PassageCard extends StatefulWidget {
  const _PassageCard({required this.passage});

  final Passage passage;

  @override
  State<_PassageCard> createState() => _PassageCardState();
}

class _PassageCardState extends State<_PassageCard> {
  bool _opening = false;

  Future<void> _open() async {
    setState(() => _opening = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // The Library list carries no page bodies — fetching the detail here is
    // what makes the reader screen able to open offline afterwards, since the
    // repository caches whatever it fetched.
    final full = await context.read<PassageRepository>().passage(
          widget.passage.id,
        );
    if (!mounted) return;
    setState(() => _opening = false);

    if (full.pages.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('That passage has no pages yet. Add them in the admin.'),
        ),
      );
      return;
    }
    navigator.push(
      MaterialPageRoute(builder: (_) => ReadingScreen(passage: full)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.passage;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _opening ? null : _open,
      child: WhiteCard(
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
              child: _opening
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.menu_book_rounded,
                      size: 26, color: AppColors.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(
                      fontFamily: 'NotoSansBengali',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.category,
                    style: const TextStyle(fontSize: 14, color: AppColors.muted),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      BadgeChip('${p.estimatedMinutes} min'),
                      BadgeChip(p.difficulty.label),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
