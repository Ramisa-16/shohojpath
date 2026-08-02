import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/passage.dart';
import '../models/reading_settings.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/reading_surface.dart';
import '../utils/bangla_text.dart';
import '../widgets/bangla_passage.dart';
import '../widgets/conjunct_card.dart';
import '../widgets/quick_settings_sheet.dart';

/// The Reading Interface, screen 05 of the design.
///
/// Layout follows the mockup: navy header with back / bookmark / settings,
/// a progress bar, the page indicator, the passage, the conjunct teaching card,
/// the read-aloud bar and Previous / Next. Everything inside the reader body
/// takes its colours from the selected [ReadingSurface] rather than the app
/// theme, so switching to cream or dark changes the page the reader is looking
/// at without repainting the chrome.
class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, required this.passage, this.initialPage = 0});

  final Passage passage;
  final int initialPage;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late int _pageIndex = widget.initialPage;
  final ScrollController _scrollController = ScrollController();

  ConjunctCluster? _selectedConjunct;
  bool _showFloatingCard = false;
  bool _bookmarked = false;

  PassagePage get _page => widget.passage.pages[_pageIndex];

  double get _progress =>
      (_pageIndex + 1) / widget.passage.pageCount.clamp(1, 9999);

  /// The card starts on the first conjunct of the page so the affordance is
  /// visible before the reader has tapped anything.
  ConjunctCluster? get _cardCluster {
    if (_selectedConjunct != null) return _selectedConjunct;
    final conjuncts = _page.conjuncts;
    return conjuncts.isEmpty ? null : conjuncts.first;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index >= widget.passage.pageCount) return;
    setState(() {
      _pageIndex = index;
      _selectedConjunct = null;
      _showFloatingCard = false;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onConjunctTap(ConjunctCluster cluster, Offset _) {
    setState(() {
      _selectedConjunct = cluster;
      _showFloatingCard = true;
    });
    final settings = context.read<ReadingSettings>();
    context.read<TtsService>().speak(cluster.text, rate: settings.speechRate);
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReadingSettings>();
    final surface = settings.surface;

    return Scaffold(
      backgroundColor: surface.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              passage: widget.passage,
              bookmarked: _bookmarked,
              onBack: () => Navigator.of(context).maybePop(),
              onBookmark: () => setState(() => _bookmarked = !_bookmarked),
              onSettings: _openSettings,
            ),
            _ProgressBar(progress: _progress, surface: surface),
            Expanded(
              child: Stack(
                children: [
                  _ReaderBody(
                    scrollController: _scrollController,
                    passage: widget.passage,
                    page: _page,
                    pageIndex: _pageIndex,
                    settings: settings,
                    cardCluster: _cardCluster,
                    selectedConjunct: _selectedConjunct,
                    onConjunctTap: _onConjunctTap,
                  ),
                  if (_showFloatingCard && _selectedConjunct != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: ConjunctCard(
                        cluster: _selectedConjunct!,
                        compact: true,
                        onClose: () =>
                            setState(() => _showFloatingCard = false),
                      ),
                    ),
                ],
              ),
            ),
            _ReaderControls(
              onPrevious: _pageIndex > 0 ? () => _goToPage(_pageIndex - 1) : null,
              onNext: _pageIndex < widget.passage.pageCount - 1
                  ? () => _goToPage(_pageIndex + 1)
                  : null,
              pageText: _page.paragraphs.join('\n'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.passage,
    required this.bookmarked,
    required this.onBack,
    required this.onBookmark,
    required this.onSettings,
  });

  final Passage passage;
  final bool bookmarked;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Row(
        children: [
          _HeaderButton(
            icon: Icons.arrow_back_rounded,
            label: 'Back to library',
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  passage.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  passage.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onNavyMuted,
                  ),
                ),
              ],
            ),
          ),
          _HeaderButton(
            icon: bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: bookmarked ? 'Remove bookmark' : 'Bookmark this page',
            onPressed: onBookmark,
          ),
          _HeaderButton(
            icon: Icons.tune_rounded,
            label: 'Open reading settings',
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon, color: Colors.white, size: 24),
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.surface});

  final double progress;
  final ReadingSurface surface;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 5,
      child: Row(
        children: [
          Expanded(
            flex: (progress * 1000).round().clamp(1, 1000),
            child: Container(color: AppColors.teal),
          ),
          Expanded(
            flex: ((1 - progress) * 1000).round().clamp(0, 1000),
            child: Container(color: AppColors.track),
          ),
        ],
      ),
    );
  }
}

class _ReaderBody extends StatelessWidget {
  const _ReaderBody({
    required this.scrollController,
    required this.passage,
    required this.page,
    required this.pageIndex,
    required this.settings,
    required this.cardCluster,
    required this.selectedConjunct,
    required this.onConjunctTap,
  });

  final ScrollController scrollController;
  final Passage passage;
  final PassagePage page;
  final int pageIndex;
  final ReadingSettings settings;
  final ConjunctCluster? cardCluster;
  final ConjunctCluster? selectedConjunct;
  final ConjunctTapCallback onConjunctTap;

  @override
  Widget build(BuildContext context) {
    final surface = settings.surface;

    return Container(
      color: surface.background,
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
        children: [
          Text(
            'Page ${pageIndex + 1} of ${passage.pageCount}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.84,
              color: surface.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          BanglaPassage(
            // A new key per page stops the previous page's reading focus from
            // being reused on text that no longer exists.
            key: ValueKey('${passage.id}#$pageIndex'),
            paragraphs: page.paragraphs,
            selectedConjunct: selectedConjunct,
            onConjunctTap: onConjunctTap,
          ),
          if (cardCluster != null) ...[
            SizedBox(height: settings.paragraphSpacingPx),
            ConjunctCard(cluster: cardCluster!),
            const SizedBox(height: 8),
            Text(
              settings.highlightConjuncts
                  ? 'Tap any underlined conjunct to see and hear it'
                  : 'Tap any conjunct to see and hear it',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: surface.secondaryText,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _ModeNote(settings: settings, surface: surface),
        ],
      ),
    );
  }
}

class _ModeNote extends StatelessWidget {
  const _ModeNote({required this.settings, required this.surface});

  final ReadingSettings settings;
  final ReadingSurface surface;

  static const Map<ReadingProfile, String> _notes = {
    ReadingProfile.standard:
        'Default — the baseline interface used as the control condition in '
            'the study.',
    ReadingProfile.recommended:
        'Evidence-based settings: audio support, wide line spacing, cream '
            'background, and no letter spacing so the মাত্রা stays intact.',
    ReadingProfile.custom:
        'Custom — the reader’s own configuration, logged for comparison '
            'against Default and Recommended.',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface.accent.withValues(alpha: 0.12),
        border: Border(left: BorderSide(color: surface.accent, width: 4)),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'READING MODE · ${settings.profile.label.toUpperCase()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: surface.isDark ? surface.text : AppColors.tealDeep,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _notes[settings.profile]!,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: surface.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderControls extends StatelessWidget {
  const _ReaderControls({
    required this.onPrevious,
    required this.onNext,
    required this.pageText,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final String pageText;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReadingSettings>();
    final tts = context.watch<TtsService>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (settings.readAloud)
              _ReadAloudBar(tts: tts, settings: settings, pageText: pageText),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPrevious,
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.body,
                        side: const BorderSide(
                          color: AppColors.borderStrong,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onNext,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      label: const Text('Next'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _ReadAloudBar extends StatelessWidget {
  const _ReadAloudBar({
    required this.tts,
    required this.settings,
    required this.pageText,
  });

  final TtsService tts;
  final ReadingSettings settings;
  final String pageText;

  @override
  Widget build(BuildContext context) {
    final noVoice = tts.isInitialised && !tts.hasBanglaVoice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.tealTintSoft,
        border: Border(bottom: BorderSide(color: AppColors.tealLine)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: tts.isSpeaking ? 'Stop read aloud' : 'Play read aloud',
            child: Material(
              color: noVoice ? AppColors.borderStrong : AppColors.teal,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: noVoice
                    ? null
                    : () {
                        final service = context.read<TtsService>();
                        if (tts.isSpeaking) {
                          service.stop();
                        } else {
                          service.speak(pageText, rate: settings.speechRate);
                        }
                      },
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    tts.isSpeaking
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    for (final rate in ReadingSettings.speechRates) ...[
                      Expanded(
                        child: _RatePill(
                          rate: rate,
                          selected: settings.speechRate == rate,
                          onTap: () =>
                              context.read<ReadingSettings>().speechRate = rate,
                        ),
                      ),
                      if (rate != ReadingSettings.speechRates.last)
                        const SizedBox(width: 5),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  noVoice
                      ? 'No Bangla voice on this device — install one in '
                          'Android TTS settings'
                      : 'Word highlighting is not wired up yet',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: noVoice ? AppColors.danger : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatePill extends StatelessWidget {
  const _RatePill({
    required this.rate,
    required this.selected,
    required this.onTap,
  });

  final double rate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = rate == rate.roundToDouble()
        ? '${rate.toInt()}x'
        : '${rate.toString()}x';

    return Material(
      color: selected ? AppColors.navy : Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: selected
                ? null
                : Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.body,
            ),
          ),
        ),
      ),
    );
  }
}
