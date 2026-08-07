import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/participant_state.dart';
import '../models/passage.dart';
import '../models/reading_settings.dart';
import '../models/study_session.dart';
import '../services/session_logger.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/reading_surface.dart';
import '../utils/bangla_text.dart';
import '../widgets/app_buttons.dart';
import '../widgets/bangla_passage.dart';
import '../widgets/conjunct_card.dart';
import '../widgets/no_bangla_voice_dialog.dart';
import '../widgets/therapist_session_banner.dart';
import 'quiz_screen.dart';
import 'reading_settings_screen.dart';

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

  /// Total time spent on this screen, reported to the quiz as the reading
  /// duration for the session.
  final Stopwatch _stopwatch = Stopwatch()..start();

  /// Time spent on the page currently on screen — logged and restarted every
  /// time the reader turns a page.
  final Stopwatch _pageStopwatch = Stopwatch()..start();

  ConjunctCluster? _selectedConjunct;
  bool _showFloatingCard = false;
  bool _bookmarked = false;

  late final String _sessionId;

  /// Captured in [initState] rather than looked up again in [dispose] —
  /// `context.read` is not safe to call once a widget starts tearing down.
  late final ReadingSettings _settings;
  late final SessionLogger _logger;

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
  void initState() {
    super.initState();
    _settings = context.read<ReadingSettings>();
    _logger = context.read<SessionLogger>();
    _sessionId = _logger.newSessionId();
    _logger.startSession(
      sessionId: _sessionId,
      participantId: context.read<ParticipantState>().participantId,
      passageId: widget.passage.id,
      profile: _settings.profile,
    );
    context.read<TtsService>().resetSpokenDuration();
  }

  @override
  void dispose() {
    _logger.endActiveSession(_sessionId);
    _scrollController.dispose();
    super.dispose();
  }

  void _logCurrentPageTime() {
    _pageStopwatch.stop();
    _logger.logPageTime(_sessionId, _pageIndex, _pageStopwatch.elapsed);
  }

  void _goToPage(int index) {
    if (index < 0 || index >= widget.passage.pageCount) return;
    _logCurrentPageTime();
    setState(() {
      _pageIndex = index;
      _selectedConjunct = null;
      _showFloatingCard = false;
    });
    _pageStopwatch
      ..reset()
      ..start();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  /// Tapping "Finish" on the last page moves from reading into the
  /// comprehension quiz, carrying forward exactly what the study needs to
  /// know about this reading: how long it took and whether read-aloud was
  /// switched on.
  void _finishReading() {
    _logCurrentPageTime();
    _stopwatch.stop();
    final tts = context.read<TtsService>();
    _logger.finishReading(
      sessionId: _sessionId,
      totalReadingTime: _stopwatch.elapsed,
      wordsRead: widget.passage.wordCount,
      readAloudOn: _settings.readAloud,
      audioDuration: tts.totalSpokenDuration,
    );
    final session = StudySession(
      sessionId: _sessionId,
      passage: widget.passage,
      readAloudWasOn: _settings.readAloud,
      readingDuration: _stopwatch.elapsed,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizScreen(session: session)),
    );
  }

  void _onConjunctTap(ConjunctCluster cluster, Offset _) async {
    setState(() {
      _selectedConjunct = cluster;
      _showFloatingCard = true;
    });
    final tts = context.read<TtsService>();
    if (!await ensureBanglaVoice(context, tts)) return;
    if (!mounted) return;
    final settings = context.read<ReadingSettings>();
    tts.speak(cluster.spokenForm, rate: settings.speechRate);
  }

  /// Translates an absolute offset pair in `page.paragraphs.join('\n')` (the
  /// coordinate space read-aloud's progress handler reports in, since that is
  /// the exact string handed to [TtsService.speak]) into the paragraph and
  /// original-text range [BanglaPassage] needs to draw the highlight.
  ({int paragraphIndex, TextUnitRange range})? _spokenRangeFor(
    int start,
    int end,
  ) {
    if (end <= start) return null;
    var offset = 0;
    final paragraphs = _page.paragraphs;
    for (var i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      final paragraphEnd = offset + paragraph.length;
      if (start >= offset && start < paragraphEnd) {
        final localStart = start - offset;
        final localEnd = (end - offset).clamp(localStart + 1, paragraph.length);
        return (paragraphIndex: i, range: TextUnitRange(localStart, localEnd));
      }
      offset = paragraphEnd + 1; // +1 for the '\n' the pages are joined with.
    }
    return null;
  }

  Future<void> _openSettings() async {
    await showReadingSettingsPanel(
      context,
      bookmarked: _bookmarked,
      onToggleBookmark: () => setState(() => _bookmarked = !_bookmarked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReadingSettings>();
    final tts = context.watch<TtsService>();
    final surface = settings.surface;

    final showSpokenWord = settings.readAloud &&
        settings.highlightSpokenWord &&
        (tts.isSpeaking || tts.isPaused) &&
        tts.wordStart != null &&
        tts.wordEnd != null;
    final spoken =
        showSpokenWord ? _spokenRangeFor(tts.wordStart!, tts.wordEnd!) : null;

    final settingsLocked = context.watch<ParticipantState>().isSettingsLocked;

    return Scaffold(
      backgroundColor: surface.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TherapistSessionBanner(),
            _Header(
              passage: widget.passage,
              bookmarked: _bookmarked,
              settingsLocked: settingsLocked,
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
                    spokenParagraphIndex: spoken?.paragraphIndex,
                    spokenRange: spoken?.range,
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
                  : _finishReading,
              isLastPage: _pageIndex == widget.passage.pageCount - 1,
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
    required this.settingsLocked,
    required this.onBack,
    required this.onBookmark,
    required this.onSettings,
  });

  final Passage passage;
  final bool bookmarked;
  final bool settingsLocked;
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderButton(
                icon: Icons.tune_rounded,
                label: settingsLocked ? 'Reading settings (locked for this session)' : 'Open reading settings',
                onPressed: onSettings,
              ),
              if (settingsLocked)
                const Positioned(
                  right: 4,
                  bottom: 4,
                  child: IgnorePointer(
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: AppColors.navy,
                      child: Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
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
    return IconOnlyButton(
      onPressed: onPressed,
      tooltip: label,
      icon: icon,
      color: Colors.white,
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
    required this.spokenParagraphIndex,
    required this.spokenRange,
  });

  final ScrollController scrollController;
  final Passage passage;
  final PassagePage page;
  final int pageIndex;
  final ReadingSettings settings;
  final ConjunctCluster? cardCluster;
  final ConjunctCluster? selectedConjunct;
  final ConjunctTapCallback onConjunctTap;
  final int? spokenParagraphIndex;
  final TextUnitRange? spokenRange;

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
            spokenParagraphIndex: spokenParagraphIndex,
            spokenRange: spokenRange,
            scrollController: scrollController,
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
    required this.isLastPage,
    required this.pageText,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isLastPage;
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
                    child: SecondaryButton(
                      label: 'Previous',
                      icon: Icons.chevron_left_rounded,
                      color: AppColors.body,
                      expand: false,
                      onPressed: onPrevious,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: isLastPage ? 'Finish' : 'Next',
                      icon: isLastPage ? Icons.check_rounded : Icons.chevron_right_rounded,
                      expand: false,
                      onPressed: onNext,
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

  Future<void> _onPlayPause(BuildContext context) async {
    final service = context.read<TtsService>();
    if (tts.isSpeaking) {
      service.pause();
      return;
    }
    if (tts.isPaused) {
      service.resume();
      return;
    }
    if (!await ensureBanglaVoice(context, service)) return;
    service.speak(pageText, rate: settings.speechRate);
  }

  @override
  Widget build(BuildContext context) {
    final noVoice = tts.isInitialised && !tts.hasBanglaVoice;
    final active = tts.isSpeaking || tts.isPaused;

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
            label: tts.isSpeaking
                ? 'Pause read aloud'
                : tts.isPaused
                    ? 'Resume read aloud'
                    : 'Play read aloud',
            child: Material(
              color: noVoice ? AppColors.borderStrong : AppColors.teal,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _onPlayPause(context),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    tts.isSpeaking
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          if (active) ...[
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Stop read aloud',
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.read<TtsService>().stop(),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.stop_rounded,
                      color: AppColors.navy,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                      : settings.highlightSpokenWord
                          ? 'Word highlighting on'
                          : 'Word highlighting off',
                  style: TextStyle(
                    fontSize: 14,
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
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: selected
                ? null
                : Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
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
      ),
    );
  }
}
