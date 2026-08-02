import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bangla_font.dart';
import '../models/reading_settings.dart';
import '../theme/app_colors.dart';
import '../theme/reading_surface.dart';

/// INTERIM control panel — to be replaced by the full Reading Settings screen
/// (screen 06 of the design).
///
/// It exists now because a renderer whose settings cannot be changed cannot be
/// evaluated: every control here maps to something [BanglaPassage] actually
/// implements, so the passage can be exercised end to end on a device. The
/// controls are built from [ReadingSettings] bounds rather than literals, so
/// the real screen can reuse the same limits.
class QuickSettingsSheet extends StatelessWidget {
  const QuickSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReadingSettings>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.track,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close reading settings',
                    icon: const Icon(Icons.close_rounded),
                    constraints:
                        const BoxConstraints.tightFor(width: 44, height: 44),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                children: [
                  _ProfilePicker(settings: settings),
                  const SizedBox(height: 20),
                  _Section(
                    title: '1 · Read Aloud',
                    badge: 'Evidence-based',
                    children: [
                      _Toggle(
                        label: 'Read aloud',
                        value: settings.readAloud,
                        onChanged: (v) =>
                            context.read<ReadingSettings>().readAloud = v,
                      ),
                      _Toggle(
                        label: 'Highlight each word as it is spoken',
                        value: settings.highlightSpokenWord,
                        onChanged: (v) => context
                            .read<ReadingSettings>()
                            .highlightSpokenWord = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: '2 · Bangla Reading Support',
                    badge: 'Research feature',
                    caption: 'Bangla conjuncts hide the letters inside them. '
                        'These options make the spelling visible.',
                    children: [
                      _Toggle(
                        label: 'যুক্তাক্ষর হাইলাইট',
                        caption: 'Highlight conjuncts',
                        value: settings.highlightConjuncts,
                        onChanged: (v) => context
                            .read<ReadingSettings>()
                            .highlightConjuncts = v,
                      ),
                      _Toggle(
                        label: 'যুক্তাক্ষর ভেঙে দেখাও',
                        caption: 'Split conjuncts: ক্ষ shows as ক্‌ + ষ',
                        value: settings.splitConjuncts,
                        onChanged: (v) =>
                            context.read<ReadingSettings>().splitConjuncts = v,
                      ),
                      _Toggle(
                        label: 'মাত্রা জোর করো',
                        caption: 'Emphasise the matra headline',
                        value: settings.emphasiseMatra,
                        onChanged: (v) =>
                            context.read<ReadingSettings>().emphasiseMatra = v,
                      ),
                      _Toggle(
                        label: 'কঠিন শব্দ ভাগ করো',
                        caption: 'Syllable breaks in long words',
                        value: settings.syllableBreaks,
                        onChanged: (v) =>
                            context.read<ReadingSettings>().syllableBreaks = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: '3 · Typography',
                    badge: 'Personal preference',
                    children: [
                      _FontPicker(settings: settings),
                      const SizedBox(height: 12),
                      _Slider(
                        label: 'Font size',
                        value: settings.fontSize,
                        min: ReadingSettings.minFontSize,
                        max: ReadingSettings.maxFontSize,
                        display: '${settings.fontSize.round()} px',
                        onChanged: (v) =>
                            context.read<ReadingSettings>().fontSize = v,
                      ),
                      _Toggle(
                        label: 'Bold text',
                        value: settings.boldText,
                        onChanged: (v) =>
                            context.read<ReadingSettings>().boldText = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: '4 · Spacing',
                    badge: 'Evidence-based',
                    children: [
                      _Slider(
                        label: 'Letter spacing',
                        value: settings.letterSpacingEm,
                        min: ReadingSettings.minLetterSpacingEm,
                        max: ReadingSettings.maxLetterSpacingEm,
                        display: '${settings.letterSpacingEm.toStringAsFixed(2)}'
                            ' em',
                        onChanged: (v) =>
                            context.read<ReadingSettings>().letterSpacingEm = v,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'বাংলায় বেশি letter spacing মাত্রা ভেঙে দেয় — সাবধানে '
                          'ব্যবহার করুন। Word spacing is safer for Bangla.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      _Slider(
                        label: 'Word spacing',
                        value: settings.wordSpacingEm,
                        min: ReadingSettings.minWordSpacingEm,
                        max: ReadingSettings.maxWordSpacingEm,
                        display:
                            '${settings.wordSpacingEm.toStringAsFixed(2)} em',
                        onChanged: (v) =>
                            context.read<ReadingSettings>().wordSpacingEm = v,
                      ),
                      _Slider(
                        label: 'Line spacing',
                        value: settings.lineHeight,
                        min: ReadingSettings.minLineHeight,
                        max: ReadingSettings.maxLineHeight,
                        display: settings.lineHeight.toStringAsFixed(2),
                        onChanged: (v) =>
                            context.read<ReadingSettings>().lineHeight = v,
                      ),
                      _Slider(
                        label: 'Paragraph spacing',
                        value: settings.paragraphSpacingEm,
                        min: ReadingSettings.minParagraphSpacingEm,
                        max: ReadingSettings.maxParagraphSpacingEm,
                        display:
                            '${settings.paragraphSpacingEm.toStringAsFixed(1)}'
                            ' em',
                        onChanged: (v) => context
                            .read<ReadingSettings>()
                            .paragraphSpacingEm = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: '5 · Theme',
                    badge: 'Comfort',
                    caption:
                        'Background colour affects comfort, not decoding '
                        'accuracy.',
                    children: [_SurfacePicker(settings: settings)],
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    title: '6 · Reading focus',
                    badge: 'Evidence-based',
                    children: [
                      _Toggle(
                        label: 'Highlight current line',
                        value: settings.highlightCurrentLine,
                        onChanged: (v) => context
                            .read<ReadingSettings>()
                            .highlightCurrentLine = v,
                      ),
                      _Toggle(
                        label: 'Reading ruler',
                        value: settings.readingRuler,
                        onChanged: (v) =>
                            context.read<ReadingSettings>().readingRuler = v,
                      ),
                      _Toggle(
                        label: 'Highlight current paragraph',
                        value: settings.highlightCurrentParagraph,
                        onChanged: (v) => context
                            .read<ReadingSettings>()
                            .highlightCurrentParagraph = v,
                      ),
                      _Toggle(
                        label: 'Focus mode',
                        caption: 'Dim every paragraph except the one being '
                            'read.',
                        value: settings.focusMode,
                        onChanged: (v) =>
                            context.read<ReadingSettings>().focusMode = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap a line in the passage to move the reading focus.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.muted,
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

class _ProfilePicker extends StatelessWidget {
  const _ProfilePicker({required this.settings});

  final ReadingSettings settings;

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
          Row(
            children: [
              for (final profile in ReadingProfile.values) ...[
                Expanded(
                  child: _Pill(
                    label: profile.label,
                    selected: settings.profile == profile,
                    onTap: () =>
                        context.read<ReadingSettings>().applyProfile(profile),
                  ),
                ),
                if (profile != ReadingProfile.values.last)
                  const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FontPicker extends StatelessWidget {
  const _FontPicker({required this.settings});

  final ReadingSettings settings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final font in BanglaFont.values)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 40) / 2,
            child: _Pill(
              label: font.label,
              selected: settings.fontFamily == font,
              alignLeft: true,
              onTap: () => context.read<ReadingSettings>().fontFamily = font,
            ),
          ),
      ],
    );
  }
}

class _SurfacePicker extends StatelessWidget {
  const _SurfacePicker({required this.settings});

  final ReadingSettings settings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final surface in ReadingSurface.values) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: settings.surface == surface,
              label: '${surface.label} theme',
              child: GestureDetector(
                onTap: () =>
                    context.read<ReadingSettings>().surface = surface,
                child: Container(
                  height: 62,
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: surface.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: settings.surface == surface
                          ? AppColors.teal
                          : AppColors.borderStrong,
                      width: settings.surface == surface ? 3 : 2,
                    ),
                  ),
                  child: Text(
                    surface.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: surface.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (surface != ReadingSurface.values.last) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
    this.badge,
    this.caption,
  });

  final String title;
  final String? badge;
  final String? caption;
  final List<Widget> children;

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
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tealTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tealDeep,
                  ),
                ),
              ),
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
        ...children,
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.caption,
  });

  final String label;
  final String? caption;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      caption!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.body,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.body,
                ),
              ),
            ),
            Text(
              display,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.alignLeft = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? null
                : Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: Text(
            label,
            textAlign: alignLeft ? TextAlign.left : TextAlign.center,
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
