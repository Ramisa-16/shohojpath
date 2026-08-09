import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reader_sign_in_display.dart';
import '../models/reading_settings.dart';
import '../services/app_config_repository.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_header.dart';
import '../widgets/export_data_action.dart';
import '../widgets/settings_controls.dart';

const _readerSignInDisplayKey = 'reader_sign_in_display';

/// Screen 16 of the design — app-level settings, distinct from the Reading
/// Settings panel reached from inside a passage.
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _reminders = true;
  bool _soundEffects = false;
  bool _shareAnonymisedData = true;
  ReaderSignInDisplay _readerSignInDisplay = ReaderSignInDisplay.names;
  bool _loadingDisplay = true;

  @override
  void initState() {
    super.initState();
    _loadReaderSignInDisplay();
  }

  Future<void> _loadReaderSignInDisplay() async {
    final saved = await context.read<AppConfigRepository>().get(_readerSignInDisplayKey);
    if (!mounted) return;
    setState(() {
      _readerSignInDisplay = ReaderSignInDisplay.fromId(saved);
      _loadingDisplay = false;
    });
  }

  Future<void> _setReaderSignInDisplay(ReaderSignInDisplay value) async {
    setState(() => _readerSignInDisplay = value);
    await context.read<AppConfigRepository>().set(_readerSignInDisplayKey, value.id);
  }

  void _notImplemented(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is not available in this prototype yet.')),
    );
  }

  Future<void> _confirmReset() async {
    final t = context.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.resetAllSettings),
        content: Text(t.resetAllSettingsBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.reset, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ReadingSettings>().resetAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.settingsReset)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageState>();
    final t = context.t;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: t.settings, onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Container(
                color: AppColors.canvas,
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Text(
                      t.languageHeading,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.body),
                    ),
                    const SizedBox(height: 9),
                    // Was a bool living in this screen's State: it moved the
                    // highlight and nothing else. The language is device-wide
                    // and has to outlive this route, so it lives in
                    // LanguageState and is persisted.
                    Row(
                      children: [
                        for (final option in AppLanguage.values) ...[
                          Expanded(
                            child: ChoiceTile(
                              label: option.label,
                              selected: language.language == option,
                              onTap: () => language.select(option),
                            ),
                          ),
                          if (option != AppLanguage.values.last)
                            const SizedBox(width: 9),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    WhiteCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _SettingsToggle(
                            label: t.readingReminders,
                            value: _reminders,
                            onChanged: (v) => setState(() => _reminders = v),
                          ),
                          const Divider(height: 1),
                          _SettingsToggle(
                            label: 'Session sound effects',
                            value: _soundEffects,
                            onChanged: (v) => setState(() => _soundEffects = v),
                          ),
                          const Divider(height: 1),
                          _SettingsToggle(
                            label: 'Share anonymised data',
                            value: _shareAnonymisedData,
                            onChanged: (v) => setState(() => _shareAnonymisedData = v),
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'READER SIGN-IN DISPLAY',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.body),
                    ),
                    const SizedBox(height: 9),
                    if (_loadingDisplay)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    else
                      WhiteCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            for (final option in ReaderSignInDisplay.values)
                              _ReaderSignInOption(
                                option: option,
                                selected: _readerSignInDisplay == option,
                                onTap: () => _setReaderSignInDisplay(option),
                                last: option == ReaderSignInDisplay.values.last,
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    ListRowButton(
                      leading: const Icon(Icons.download_rounded, color: AppColors.navy, size: 24),
                      title: 'Export session data',
                      subtitle: 'CSV for research analysis',
                      onTap: () => exportAndShareCsv(context),
                    ),
                    const SizedBox(height: 11),
                    ListRowButton(
                      leading: const Icon(Icons.shield_rounded, color: AppColors.navy, size: 24),
                      title: 'Privacy & consent',
                      onTap: () => _notImplemented('Privacy & consent'),
                    ),
                    const SizedBox(height: 11),
                    Material(
                      color: AppColors.dangerTint,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _confirmReset,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 72),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.dangerBorder, width: 1.5),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.restart_alt_rounded, color: AppColors.danger, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Reset all settings',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _ReaderSignInOption extends StatelessWidget {
  const _ReaderSignInOption({
    required this.option,
    required this.selected,
    required this.onTap,
    this.last = false,
  });

  final ReaderSignInDisplay option;
  final bool selected;
  final VoidCallback onTap;
  final bool last;

  static const _captions = {
    ReaderSignInDisplay.names: 'Default — for a single-user device at home.',
    ReaderSignInDisplay.participantIdsOnly: 'For shared study devices.',
    ReaderSignInDisplay.off: 'Hides the reader picker; every session starts '
        'from the Therapist Dashboard.',
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: last
            ? null
            : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.navy : AppColors.muted,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _captions[option]!,
                    style: const TextStyle(fontSize: 14, color: AppColors.body, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.ink))),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
