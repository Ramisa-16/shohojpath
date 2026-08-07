import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/participant_state.dart';
import '../models/bangla_font.dart';
import '../models/reading_settings.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../theme/reading_surface.dart';
import '../widgets/app_buttons.dart';
import '../widgets/settings_controls.dart';
import '../widgets/therapist_password_dialog.dart';

/// Pushes the Reading Settings panel — screen 06 of the design — as a sheet
/// sliding in from the right over a dimmed backdrop, exactly as drawn there
/// (`position:absolute;top:0;right:0;bottom:0;width:352px`) rather than the
/// bottom sheet Material usually reaches for.
Future<void> showReadingSettingsPanel(
  BuildContext context, {
  required bool bookmarked,
  required VoidCallback onToggleBookmark,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x80142032),
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) =>
          ReadingSettingsScreen(
            bookmarked: bookmarked,
            onToggleBookmark: onToggleBookmark,
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    ),
  );
}

class ReadingSettingsScreen extends StatefulWidget {
  const ReadingSettingsScreen({
    super.key,
    required this.bookmarked,
    required this.onToggleBookmark,
  });

  final bool bookmarked;
  final VoidCallback onToggleBookmark;

  @override
  State<ReadingSettingsScreen> createState() => _ReadingSettingsScreenState();
}

class _ReadingSettingsScreenState extends State<ReadingSettingsScreen> {
  Future<void> _unlock(BuildContext context) async {
    final confirmed = await showTherapistPasswordDialog(
      context,
      title: 'Unlock settings',
      description: "Enter the therapist's password to let this reader change "
          'settings for the rest of the session.',
      confirmLabel: 'Unlock',
    );
    if (!confirmed || !context.mounted) return;
    context.read<ParticipantState>().unlockSettings();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReadingSettings>();
    final tts = context.watch<TtsService>();
    final locked = context.watch<ParticipantState>().isSettingsLocked;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = screenWidth > 383 ? 352.0 : screenWidth * 0.92;

    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          // Swallow taps on the panel itself so they don't fall through to
          // the barrier-dismiss handler above.
          onTap: () {},
          child: Material(
            color: Colors.white,
            elevation: 8,
            child: SizedBox(
              width: panelWidth,
              height: double.infinity,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Reading Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          IconOnlyButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            tooltip: 'Close reading settings',
                            icon: Icons.close_rounded,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    if (locked) _LockedStrip(onUnlock: () => _unlock(context)),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        children: [
                          // Everything from here through Section 7 stays
                          // visible but inert while locked: dimmed so it
                          // reads as read-only, and AbsorbPointer blocks
                          // every tap so a reader can't quietly leave the
                          // experimental condition mid-session.
                          Opacity(
                            opacity: locked ? 0.5 : 1,
                            child: AbsorbPointer(
                              absorbing: locked,
                              child: Column(
                                children: [
                                  _ProfileBox(settings: settings),
                                  const SizedBox(height: 18),
                                  _Section(
                                    number: 1,
                                    title: 'Read Aloud',
                                    titleBn: 'পড়ে শোনাও',
                                    badge: 'Evidence-based',
                                    caption:
                                        'Dyslexia is a phonological difficulty. '
                                        'Audio support addresses it directly.',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ToggleRow(
                                          label: 'Read aloud',
                                          value: settings.readAloud,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .readAloud =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label:
                                              'Highlight each word as it is spoken',
                                          value: settings.highlightSpokenWord,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .highlightSpokenWord =
                                                  v,
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Speed',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.body,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            for (final rate in ReadingSettings.speechRates) ...[
                                              Expanded(
                                                child: ChoiceTile(
                                                  label: rate == rate.roundToDouble() ? '${rate.toInt()}x' : '${rate}x',
                                                  selected: settings.speechRate == rate,
                                                  onTap: () => context.read<ReadingSettings>().speechRate = rate,
                                                ),
                                              ),
                                              if (rate != ReadingSettings.speechRates.last) const SizedBox(width: 6),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // Stacked and left-aligned rather
                                        // than a right-aligned value beside
                                        // the label — a long locale name
                                        // wraps to a ragged left edge when
                                        // right-aligned instead.
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Voice',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.body,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              tts.locale ??
                                                  'No Bangla voice found',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: tts.hasBanglaVoice
                                                    ? AppColors.navy
                                                    : AppColors.danger,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _Section(
                                    number: 2,
                                    title: 'Bangla Reading Support',
                                    titleBn: 'বাংলা পাঠ সহায়তা',
                                    badge: 'Research feature',
                                    caption:
                                        'Bangla conjuncts hide the letters '
                                        'inside them. These options make the '
                                        'spelling visible.',
                                    child: Column(
                                      children: [
                                        ToggleRow(
                                          label: 'যুক্তাক্ষর হাইলাইট',
                                          labelIsBangla: true,
                                          caption: 'Highlight conjuncts',
                                          value: settings.highlightConjuncts,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .highlightConjuncts =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: 'যুক্তাক্ষর ভেঙে দেখাও',
                                          labelIsBangla: true,
                                          caption:
                                              'Split conjuncts: ক্ষ shows as ক্‌ + ষ',
                                          value: settings.splitConjuncts,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .splitConjuncts =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: 'মাত্রা জোর করো',
                                          labelIsBangla: true,
                                          caption:
                                              'Emphasise the matra headline',
                                          value: settings.emphasiseMatra,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .emphasiseMatra =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: 'কঠিন শব্দ ভাগ করো',
                                          labelIsBangla: true,
                                          caption:
                                              'Syllable breaks in long words',
                                          value: settings.syllableBreaks,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .syllableBreaks =
                                                  v,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _Section(
                                    number: 3,
                                    title: 'Typography',
                                    badge: 'Personal preference',
                                    caption:
                                        'Font choice is a comfort preference. '
                                        'Research has not shown any single font '
                                        'improves reading accuracy.',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _FontGrid(settings: settings),
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.canvas,
                                            border: Border.all(
                                              color: AppColors.border,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              13,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      'Font size',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors.body,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${settings.fontSize.round()} px',
                                                    style: const TextStyle(
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors.navy,
                                                      height: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Slider(
                                                value: settings.fontSize.clamp(
                                                  ReadingSettings.minFontSize,
                                                  ReadingSettings.maxFontSize,
                                                ),
                                                min:
                                                    ReadingSettings.minFontSize,
                                                max:
                                                    ReadingSettings.maxFontSize,
                                                onChanged: (v) =>
                                                    context
                                                            .read<
                                                              ReadingSettings
                                                            >()
                                                            .fontSize =
                                                        v,
                                              ),
                                              const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '12 px',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.muted,
                                                    ),
                                                  ),
                                                  Text(
                                                    '72 px',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.muted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Applies to the whole app, not just '
                                                'the passage.',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  height: 1.5,
                                                  color: AppColors.body,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ToggleRow(
                                          label: 'Bold text',
                                          value: settings.boldText,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .boldText =
                                                  v,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _Section(
                                    number: 4,
                                    title: 'Spacing',
                                    badge: 'Evidence-based',
                                    child: Column(
                                      children: [
                                        SliderRow(
                                          label: 'Letter spacing',
                                          value: settings.letterSpacingEm,
                                          min: ReadingSettings
                                              .minLetterSpacingEm,
                                          max: ReadingSettings
                                              .maxLetterSpacingEm,
                                          display:
                                              '${settings.letterSpacingEm.toStringAsFixed(2)} em',
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .letterSpacingEm =
                                                  v,
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 10),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'বাংলায় বেশি letter spacing মাত্রা ভেঙে '
                                              'দেয় — সাবধানে ব্যবহার করুন। Word '
                                              'spacing is safer for Bangla.',
                                              style: TextStyle(
                                                fontSize: 14,
                                                height: 1.5,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SliderRow(
                                          label: 'Word spacing',
                                          value: settings.wordSpacingEm,
                                          min: ReadingSettings.minWordSpacingEm,
                                          max: ReadingSettings.maxWordSpacingEm,
                                          display:
                                              '${settings.wordSpacingEm.toStringAsFixed(2)} em',
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .wordSpacingEm =
                                                  v,
                                        ),
                                        SliderRow(
                                          label: 'Line spacing',
                                          value: settings.lineHeight,
                                          min: ReadingSettings.minLineHeight,
                                          max: ReadingSettings.maxLineHeight,
                                          display: settings.lineHeight
                                              .toStringAsFixed(2),
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .lineHeight =
                                                  v,
                                        ),
                                        SliderRow(
                                          label: 'Paragraph spacing',
                                          value: settings.paragraphSpacingEm,
                                          min: ReadingSettings
                                              .minParagraphSpacingEm,
                                          max: ReadingSettings
                                              .maxParagraphSpacingEm,
                                          display:
                                              '${settings.paragraphSpacingEm.toStringAsFixed(1)} em',
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .paragraphSpacingEm =
                                                  v,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _Section(
                                    number: 5,
                                    title: 'Theme',
                                    badge: 'Comfort',
                                    caption:
                                        'Background colour affects comfort, '
                                        'not decoding accuracy.',
                                    child: _ThemeRow(settings: settings),
                                  ),
                                  const SizedBox(height: 18),
                                  _Section(
                                    number: 6,
                                    title: 'Reading focus',
                                    badge: 'Evidence-based',
                                    child: Column(
                                      children: [
                                        ToggleRow(
                                          label: 'Highlight current line',
                                          value: settings.highlightCurrentLine,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .highlightCurrentLine =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: 'Reading ruler',
                                          value: settings.readingRuler,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .readingRuler =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: 'Highlight current paragraph',
                                          value: settings
                                              .highlightCurrentParagraph,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .highlightCurrentParagraph =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: 'Hide decorative images',
                                          caption:
                                              'Illustrations often help '
                                              'comprehension. Hide only if they '
                                              'distract.',
                                          value: settings.hideDecorativeImages,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .hideDecorativeImages =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: 'Focus mode',
                                          value: settings.focusMode,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .focusMode =
                                                  v,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _Section(
                                    number: 7,
                                    title: 'Reading assistance',
                                    child: _AssistanceGrid(
                                      bookmarked: widget.bookmarked,
                                      onToggleBookmark: widget.onToggleBookmark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Outside the locked wrapper: closing the panel
                          // isn't a settings change, so it stays enabled
                          // (and re-labelled) even while locked.
                          PrimaryButton(
                            label: locked ? 'Return to reading' : 'Apply & return',
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedStrip extends StatelessWidget {
  const _LockedStrip({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.chipNeutral,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, size: 16, color: AppColors.muted),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Settings are locked for this session',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onUnlock,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Unlock (therapist)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBox extends StatelessWidget {
  const _ProfileBox({required this.settings});

  final ReadingSettings settings;

  static const Map<ReadingProfile, String> _descriptions = {
    ReadingProfile.standard: 'Baseline — no reading aids, the study control.',
    ReadingProfile.recommended:
        'Evidence-based: audio, spacing, cream background.',
    ReadingProfile.custom: 'Your own configuration, saved for comparison.',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.tealTintSoft,
        border: Border.all(color: AppColors.teal, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'READING PROFILE',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.75,
              color: AppColors.tealDeep,
            ),
          ),
          const SizedBox(height: 10),
          for (final profile in ReadingProfile.values) ...[
            ProfileOptionTile(
              title: profile.label,
              description: _descriptions[profile]!,
              selected: settings.profile == profile,
              onTap: () =>
                  context.read<ReadingSettings>().applyProfile(profile),
            ),
            if (profile != ReadingProfile.values.last)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.number,
    required this.title,
    required this.child,
    this.titleBn,
    this.badge,
    this.caption,
  });

  final int number;
  final String title;
  final String? titleBn;
  final String? badge;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              titleBn == null
                  ? '$number · $title'
                  : '$number · $title / $titleBn',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            if (badge != null) BadgeChip(badge!),
          ],
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.body,
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _FontGrid extends StatelessWidget {
  const _FontGrid({required this.settings});

  final ReadingSettings settings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final font in BanglaFont.values)
              ChoiceTile(
                width: tileWidth,
                label: font.label,
                selected: settings.fontFamily == font,
                onTap: () => context.read<ReadingSettings>().fontFamily = font,
              ),
          ],
        );
      },
    );
  }
}

/// Five theme swatches wrapped 3-per-row (2 on the second row) instead of
/// squeezed into one 5-across [Row] — at this app's font sizes a fifth
/// column has no width left for its label at all.
class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.settings});

  final ReadingSettings settings;

  static const _perRow = 3;
  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth - _spacing * (_perRow - 1)) / _perRow;
        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final surface in ReadingSurface.values)
              SizedBox(
                width: tileWidth,
                child: _ThemeSwatch(
                  surface: surface,
                  selected: settings.surface == surface,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Bespoke rather than a plain [ChoiceTile]: the tile's own background IS
/// the theme being previewed (never a generic selected-fill colour), so it
/// borrows the CHOICE TILE padding/height/radius/border-width constants
/// directly rather than reusing the widget's selected/unselected colour
/// model, which doesn't apply here.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.surface, required this.selected});

  final ReadingSurface surface;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${surface.label} theme',
      child: GestureDetector(
        onTap: () => context.read<ReadingSettings>().surface = surface,
        child: Container(
          constraints: const BoxConstraints(minHeight: ChoiceTile.minHeight),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            vertical: ChoiceTile.verticalPadding,
            horizontal: ChoiceTile.horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: surface.background,
            borderRadius: BorderRadius.circular(ChoiceTile.radius),
            border: Border.all(
              color: selected ? AppColors.teal : AppColors.borderStrong,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              surface.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ChoiceTile.fontSize,
                fontWeight: FontWeight.w700,
                color: surface.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistanceGrid extends StatelessWidget {
  const _AssistanceGrid({
    required this.bookmarked,
    required this.onToggleBookmark,
  });

  final bool bookmarked;
  final VoidCallback onToggleBookmark;

  void _notImplemented(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is not available in this prototype yet.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ChoiceTile(
            label: 'Bookmark',
            selected: bookmarked,
            onTap: onToggleBookmark,
            child: Icon(
              bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: bookmarked ? Colors.white : AppColors.navy,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceTile(
            label: 'Dictionary',
            selected: false,
            onTap: () => _notImplemented(context, 'Dictionary'),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.navy, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceTile(
            label: 'Highlight',
            selected: false,
            onTap: () => _notImplemented(context, 'Highlight'),
            child: const Icon(Icons.border_color_rounded, color: AppColors.navy, size: 20),
          ),
        ),
      ],
    );
  }
}
