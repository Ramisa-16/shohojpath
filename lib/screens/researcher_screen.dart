import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/reader_repository.dart';
import '../services/session_logger.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/export_data_action.dart';
import '../widgets/settings_controls.dart';

/// Not on any menu — reached only by a long-press on the version number on
/// the About screen. A researcher running the study needs a quick way to
/// see how much data has piled up and to wipe it clean before handing the
/// device to the next participant, without that control being something a
/// participant could stumble into from the regular UI.
class ResearcherScreen extends StatefulWidget {
  const ResearcherScreen({super.key});

  @override
  State<ResearcherScreen> createState() => _ResearcherScreenState();
}

class _ResearcherScreenState extends State<ResearcherScreen> {
  int? _sessionCount;
  int? _readerCount;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final logger = context.read<SessionLogger>();
    final readerRepo = context.read<ReaderRepository>();
    final sessions = await logger.sessionCount();
    final readers = await readerRepo.readerCount();
    if (!mounted) return;
    setState(() {
      _sessionCount = sessions;
      _readerCount = readers;
    });
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'Deletes every session, settings-change log, quiz answer, SUS '
          'response and NASA-TLX rating for every participant. This cannot '
          'be undone — export first if you need a copy.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear everything', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<SessionLogger>().clearAllData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All session data cleared.')),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Researcher', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: WhiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _sessionCount?.toString() ?? '—',
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy),
                                ),
                                const Text('Sessions logged', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: WhiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _readerCount?.toString() ?? '—',
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy),
                                ),
                                const Text('Readers registered', style: TextStyle(fontSize: 14, color: AppColors.muted)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    WhiteCard(
                      onTap: () => exportAndShareCsv(context),
                      child: Row(
                        children: const [
                          Icon(Icons.download_rounded, color: AppColors.navy, size: 24),
                          SizedBox(width: 11),
                          Expanded(
                            child: Text('Export all data as CSV', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    Material(
                      color: AppColors.dangerTint,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _confirmClear,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.dangerBorder, width: 1.5),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 24),
                              SizedBox(width: 11),
                              Text(
                                'Clear all data',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'For use between participants. Export before clearing if the data '
                      'hasn\'t been pulled off the device yet.',
                      style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
                    ),
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
