import 'package:flutter/material.dart';

import '../models/reader_sign_in_display.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/reader_tile.dart';
import '../l10n/app_strings.dart';

/// The overflow screen from Login's "Show all readers (N)" — a search field
/// plus every reader grouped alphabetically, using the exact same
/// [ReaderTile] card the short list on Login uses.
class AllReadersScreen extends StatefulWidget {
  const AllReadersScreen({
    super.key,
    required this.readers,
    required this.display,
    required this.onSelect,
  });

  final List<Map<String, Object?>> readers;
  final ReaderSignInDisplay display;
  final ValueChanged<Map<String, Object?>> onSelect;

  @override
  State<AllReadersScreen> createState() => _AllReadersScreenState();
}

class _AllReadersScreenState extends State<AllReadersScreen> {
  final _search = TextEditingController();

  bool get _showNameAsPrimary => widget.display != ReaderSignInDisplay.participantIdsOnly;

  String _labelFor(Map<String, Object?> reader) =>
      _showNameAsPrimary ? reader['name'] as String : reader['participant_id'] as String;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = widget.readers.where((reader) {
      if (query.isEmpty) return true;
      final name = (reader['name'] as String).toLowerCase();
      final id = (reader['participant_id'] as String).toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList()
      ..sort((a, b) => _labelFor(a).toLowerCase().compareTo(_labelFor(b).toLowerCase()));

    final sections = <String, List<Map<String, Object?>>>{};
    for (final reader in filtered) {
      final label = _labelFor(reader);
      final letter = label.isEmpty ? '#' : label.substring(0, 1).toUpperCase();
      sections.putIfAbsent(letter, () => []).add(reader);
    }
    final letters = sections.keys.toList()..sort();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: context.t.allReaders, onBack: () => Navigator.of(context).maybePop()),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _showNameAsPrimary ? context.t.searchByName : context.t.searchById,
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: letters.isEmpty
                    ? Center(
                        child: Text(context.t.noReadersMatch, style: TextStyle(fontSize: 15, color: AppColors.muted)),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
                        children: [
                          for (final letter in letters) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 4),
                              child: Text(
                                letter,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.tealDeep),
                              ),
                            ),
                            for (final reader in sections[letter]!) ...[
                              ReaderTile(
                                name: reader['name'] as String,
                                participantId: reader['participant_id'] as String,
                                showNameAsPrimary: _showNameAsPrimary,
                                onTap: () => widget.onSelect(reader),
                              ),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
