import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/csv_export.dart';

/// Generates the CSV files and opens the platform share sheet with all of
/// them at once — the one place both the Settings screen's "Export session
/// data" and the therapist's "Export all data as CSV" hand off to, so the
/// two entry points can't drift into writing the data out differently.
Future<void> exportAndShareCsv(BuildContext context) async {
  try {
    final files = await CsvExport.exportAll();
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: files.map((f) => XFile(f.path)).toList(),
        subject: 'Shohojpath session data export',
        text: 'Shohojpath session data export (${files.length} files).',
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export failed: $e')),
    );
  }
}
