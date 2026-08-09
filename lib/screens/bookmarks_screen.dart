import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../api/shohojpath_api.dart';
import '../services/passage_repository.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/api_data.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/settings_controls.dart';
import 'reading_screen.dart';

/// Screen 09 of the design — saved places, stored server-side so a reader
/// keeps them across devices.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  /// Bumped to force ApiData to rebuild after a delete, so the list reflects
  /// the removal without a manual pull-to-refresh.
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final api = context.read<ShohojpathApi>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: context.t.bookmarks,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ApiData<List<Map<String, dynamic>>>(
                  key: ValueKey(_version),
                  load: api.bookmarks,
                  isEmpty: (rows) => rows.isEmpty,
                  emptyIcon: Icons.bookmark_border_rounded,
                  emptyTitle: context.t.noBookmarksYet,
                  emptyBody: context.t.noBookmarksBody,
                  builder: (context, rows, refresh) => RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: rows.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 11),
                      itemBuilder: (context, i) => _BookmarkCard(
                        bookmark: rows[i],
                        onDeleted: () => setState(() => _version++),
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

class _BookmarkCard extends StatefulWidget {
  const _BookmarkCard({required this.bookmark, required this.onDeleted});

  final Map<String, dynamic> bookmark;
  final VoidCallback onDeleted;

  @override
  State<_BookmarkCard> createState() => _BookmarkCardState();
}

class _BookmarkCardState extends State<_BookmarkCard> {
  bool _busy = false;

  Future<void> _open() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final passageId = widget.bookmark['passage_id'] as String? ?? '';
    final pageIndex = (widget.bookmark['page_index'] as num?)?.toInt() ?? 0;

    final passage = await context.read<PassageRepository>().passage(passageId);
    if (!mounted) return;
    setState(() => _busy = false);

    if (passage.pages.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tOnce.passageHasNoPages)),
      );
      return;
    }
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ReadingScreen(
          passage: passage,
          // Clamped: a bookmark can outlive an edit that shortened the passage.
          initialPage: pageIndex.clamp(0, passage.pages.length - 1),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final id = (widget.bookmark['id'] as num?)?.toInt();
    if (id == null) return;
    setState(() => _busy = true);
    try {
      await context.read<ShohojpathApi>().deleteBookmark(id);
      widget.onDeleted();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.bookmark['passage_title'] as String? ?? '';
    final excerpt = widget.bookmark['excerpt'] as String? ?? '';
    final page = (widget.bookmark['page_index'] as num?)?.toInt() ?? 0;

    return WhiteCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bookmark_rounded,
              size: 24, color: AppColors.tealText),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NotoSansBengali',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.t.pageNumber(page + 1),
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                if (excerpt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    excerpt,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'NotoSansBengali',
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.body,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: _busy ? 'Opening…' : 'Continue',
                        onPressed: _busy ? null : _open,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconOnlyButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: context.t.deleteBookmark,
                      color: AppColors.danger,
                      onPressed: _busy ? null : _delete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
