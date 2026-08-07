import 'package:flutter/material.dart';

import '../data/mock_content.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/settings_controls.dart';
import 'reading_screen.dart';

/// Screen 09 of the design.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Bookmarks', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: MockContent.bookmarks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 11),
                  itemBuilder: (context, i) {
                    final bookmark = MockContent.bookmarks[i];
                    return WhiteCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.bookmark_rounded, color: AppColors.tealText, size: 24),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookmark.title,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansBengali',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  bookmark.excerpt,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansBengali',
                                    fontSize: 14,
                                    color: AppColors.body,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Wrap, not Row: two buttons of unbounded
                                // text width will overflow a plain Row at
                                // large font sizes — Wrap drops the second
                                // button to its own line instead once they
                                // no longer fit side by side.
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    PrimaryButton(
                                      label: 'Continue',
                                      expand: false,
                                      onPressed: () {
                                        final entry = MockContent.library.firstWhere(
                                          (e) => e.title == bookmark.title,
                                          orElse: () => MockContent.library.first,
                                        );
                                        final passage = entry.passage;
                                        if (passage == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('No full passage wired up for this bookmark yet.')),
                                          );
                                          return;
                                        }
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => ReadingScreen(passage: passage)),
                                        );
                                      },
                                    ),
                                    SecondaryButton(
                                      label: 'Delete',
                                      expand: false,
                                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('"${bookmark.title}" removed from bookmarks.')),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
