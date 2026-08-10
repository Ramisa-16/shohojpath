import 'package:flutter/foundation.dart';
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
import '../l10n/app_strings.dart';
import '../l10n/label_extensions.dart';

/// Pushes the Reading Settings panel — screen 06 of the design — as a sheet
/// sliding in from the right over a dimmed backdrop, exactly as drawn there
/// (`position:absolute;top:0;right:0;bottom:0;width:352px`) rather than the
/// bottom sheet Material usually reaches for.
///
/// [bookmarked] is a listenable rather than a bool because saving is a round
/// trip to the server: the panel is already on screen when the answer arrives,
/// and a captured bool would leave its chip showing the state from before the
/// tap.
Future<void> showReadingSettingsPanel(
  BuildContext context, {
  required ValueListenable<bool> bookmarked,
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

  final ValueListenable<bool> bookmarked;
  final VoidCallback onToggleBookmark;

  @override
  State<ReadingSettingsScreen> createState() => _ReadingSettingsScreenState();
}

class _ReadingSettingsScreenState extends State<ReadingSettingsScreen> {
  Future<void> _unlock(BuildContext context) async {
    final confirmed = await showTherapistPasswordDialog(
      context,
      title: context.t.unlockSettings,
      description: context.t.therapistPasswordToUnlock,
      confirmLabel: context.t.unlock,
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
                          Expanded(
                            child: Text(
                              context.t.readingSettingsTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          IconOnlyButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            tooltip: context.t.closeReadingSettings,
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
                                    title: context.t.readAloudSection,
                                    badge: context.t.evidenceBased,
                                    caption:
                                        context.t.captionAudioSupport,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ToggleRow(
                                          label: context.t.readAloudLabel,
                                          value: settings.readAloud,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .readAloud =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label:
                                              context.t.highlightSpokenWord,
                                          value: settings.highlightSpokenWord,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .highlightSpokenWord =
                                                  v,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          context.t.speed,
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
                                            Text(
                                              context.t.voice,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.body,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              tts.locale ??
                                                  context.t.noBanglaVoiceShort,
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
                                    title: context.t.banglaReadingSupport,
                                    badge: context.t.researchFeature,
                                    caption:
                                        context.t.captionConjuncts,
                                    child: Column(
                                      children: [
                                        ToggleRow(
                                          label: context.t.highlightConjuncts,
                                          labelIsBangla: true,
                                          
                                          value: settings.highlightConjuncts,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .highlightConjuncts =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: context.t.splitConjuncts,
                                          labelIsBangla: true,
                                          value: settings.splitConjuncts,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .splitConjuncts =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: context.t.emphasiseMatra,
                                          labelIsBangla: true,
                                          value: settings.emphasiseMatra,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .emphasiseMatra =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: context.t.syllableBreaks,
                                          labelIsBangla: true,
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
                                    title: context.t.typography,
                                    badge: context.t.personalPreference,
                                    caption:
                                        context.t.captionFontChoice,
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
                                                  Expanded(
                                                    child: Text(
                                                      context.t.fontSize,
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
                                              // Read from the bounds rather
                                              // than typed in: these labels
                                              // said "72 px" long after the
                                              // maximum had changed. Expanded
                                              // + alignment so they can never
                                              // overflow the row at large
                                              // text scales.
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '${ReadingSettings.minFontSize.round()} px',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors.muted,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      '${ReadingSettings.maxFontSize.round()} px',
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors.muted,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                context.t.captionFontSizeApplies,
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
                                          label: context.t.boldText,
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
                                    title: context.t.spacing,
                                    badge: context.t.evidenceBased,
                                    child: Column(
                                      children: [
                                        SliderRow(
                                          label: context.t.letterSpacing,
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
                                        Padding(
                                          padding: EdgeInsets.only(bottom: 10),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              context.t.letterSpacingWarning,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.5,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SliderRow(
                                          label: context.t.wordSpacing,
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
                                          label: context.t.lineSpacing,
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
                                          label: context.t.paragraphSpacing,
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
                                    title: context.t.theme,
                                    badge: context.t.comfort,
                                    caption:
                                        context.t.captionThemeComfort,
                                    child: _ThemeRow(settings: settings),
                                  ),
                                  const SizedBox(height: 18),
                                  _Section(
                                    number: 6,
                                    title: context.t.readingFocus,
                                    badge: context.t.evidenceBased,
                                    child: Column(
                                      children: [
                                        ToggleRow(
                                          label: context.t.highlightCurrentLine,
                                          value: settings.highlightCurrentLine,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .highlightCurrentLine =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: context.t.readingRuler,
                                          value: settings.readingRuler,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .readingRuler =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: context.t.highlightCurrentParagraph,
                                          value: settings
                                              .highlightCurrentParagraph,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .highlightCurrentParagraph =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: context.t.hideImages,
                                          caption:
                                              context.t.captionIllustrations,
                                          value: settings.hideDecorativeImages,
                                          onChanged: (v) =>
                                              context
                                                      .read<ReadingSettings>()
                                                      .hideDecorativeImages =
                                                  v,
                                        ),
                                        ToggleRow(
                                          label: context.t.focusMode,
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
                                    title: context.t.readingAssistance,
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
                            label: locked ? context.t.returnToReading : context.t.applyAndReturn,
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
          Expanded(
            child: Text(
              context.t.settingsLockedForSession,
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
            child: Text(
              context.t.unlockTherapist,
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

  static String _description(AppStrings t, ReadingProfile profile) =>
      switch (profile) {
        ReadingProfile.standard => t.profileDescDefault,
        ReadingProfile.recommended => t.profileDescRecommended,
        ReadingProfile.custom => t.profileDescCustom,
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
          Text(
            context.t.readingProfileHeading,
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
              title: profile.localisedLabel(context.t),
              description: _description(context.t, profile),
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
    this.badge,
    this.caption,
  });

  final int number;
  final String title;
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
              // Was "1 · Read Aloud / পড়ে শোনাও" — a bilingual header that
              // is redundant now the title itself is in the reader's language.
              '$number · $title',
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
      label: surface.localisedLabel(context.t),
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
              surface.localisedLabel(context.t),
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

  final ValueListenable<bool> bookmarked;
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
          child: ValueListenableBuilder<bool>(
            valueListenable: bookmarked,
            builder: (context, saved, _) => ChoiceTile(
              label: context.t.bookmark,
              selected: saved,
              onTap: onToggleBookmark,
              child: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: saved ? Colors.white : AppColors.navy,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceTile(
            label: context.t.dictionary,
            selected: false,
            onTap: () => _notImplemented(context, context.t.dictionary),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.navy, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceTile(
            label: context.t.highlight,
            selected: false,
            onTap: () => _notImplemented(context, context.t.highlight),
            child: const Icon(Icons.border_color_rounded, color: AppColors.navy, size: 20),
          ),
        ),
      ],
    );
  }
}
