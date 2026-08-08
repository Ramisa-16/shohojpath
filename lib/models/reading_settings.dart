import 'package:flutter/material.dart';

import '../theme/reading_surface.dart';
import 'bangla_font.dart';

/// The research condition a participant is currently reading under.
enum ReadingProfile {
  /// Baseline control condition.
  standard(id: 'default', label: 'Default'),

  /// Evidence-based preset.
  recommended(id: 'recommended', label: 'Recommended'),

  /// Whatever the reader configured themselves.
  custom(id: 'custom', label: 'Custom');

  const ReadingProfile({required this.id, required this.label});

  final String id;
  final String label;

  static ReadingProfile fromId(String? id) => values.firstWhere(
        (p) => p.id == id,
        orElse: () => ReadingProfile.standard,
      );
}

/// One logged mutation of a reading setting.
///
/// Every change carries a timestamp because the thesis needs to correlate
/// settings changes with reading time — "log every change with a timestamp for
/// the independent-variable analysis", per the design's own next-steps note.
@immutable
class SettingsChange {
  const SettingsChange({
    required this.key,
    required this.from,
    required this.to,
    required this.profile,
    required this.at,
  });

  final String key;
  final Object? from;
  final Object? to;
  final ReadingProfile profile;
  final DateTime at;

  Map<String, Object?> toMap() => {
        'key': key,
        'from': from,
        'to': to,
        'profile': profile.id,
        'at': at.toUtc().toIso8601String(),
      };

  @override
  String toString() => '$key: $from -> $to (${profile.id})';
}

typedef SettingsChangeListener = void Function(SettingsChange change);

/// A complete, immutable set of reading parameters — used for the presets and
/// for snapshotting the participant's own configuration.
@immutable
class ReadingPreset {
  const ReadingPreset({
    required this.fontFamily,
    required this.fontSize,
    required this.letterSpacingEm,
    required this.wordSpacingEm,
    required this.lineHeight,
    required this.paragraphSpacingEm,
    required this.surface,
    required this.boldText,
    required this.readAloud,
    required this.highlightSpokenWord,
    required this.speechRate,
    required this.highlightConjuncts,
    required this.splitConjuncts,
    required this.emphasiseMatra,
    required this.syllableBreaks,
    required this.highlightCurrentLine,
    required this.readingRuler,
    required this.highlightCurrentParagraph,
    required this.hideDecorativeImages,
    required this.focusMode,
  });

  final BanglaFont fontFamily;
  final double fontSize;
  final double letterSpacingEm;
  final double wordSpacingEm;
  final double lineHeight;
  final double paragraphSpacingEm;
  final ReadingSurface surface;
  final bool boldText;

  final bool readAloud;
  final bool highlightSpokenWord;
  final double speechRate;

  final bool highlightConjuncts;
  final bool splitConjuncts;
  final bool emphasiseMatra;
  final bool syllableBreaks;

  final bool highlightCurrentLine;
  final bool readingRuler;
  final bool highlightCurrentParagraph;
  final bool hideDecorativeImages;
  final bool focusMode;

  /// Control condition. Plain 16 px on white with every support switched off —
  /// this is what the app must look like when it is *not* helping, so the
  /// comparison in the study means something.
  static const ReadingPreset standard = ReadingPreset(
    fontFamily: BanglaFont.notoSansBengali,
    fontSize: 16,
    letterSpacingEm: 0,
    wordSpacingEm: 0,
    lineHeight: 1.5,
    paragraphSpacingEm: 1.0,
    surface: ReadingSurface.white,
    boldText: false,
    readAloud: false,
    highlightSpokenWord: false,
    speechRate: 1.0,
    highlightConjuncts: false,
    splitConjuncts: false,
    emphasiseMatra: false,
    syllableBreaks: false,
    highlightCurrentLine: false,
    readingRuler: false,
    highlightCurrentParagraph: false,
    hideDecorativeImages: false,
    focusMode: false,
  );

  /// Evidence-based preset, transcribed from the mockup's `recommended` config
  /// and its toggle states. Note letter spacing stays at 0: widening letters in
  /// Bangla breaks the মাত্রা headline, so word spacing carries the load.
  static const ReadingPreset recommended = ReadingPreset(
    fontFamily: BanglaFont.notoSansBengali,
    fontSize: 22,
    letterSpacingEm: 0,
    wordSpacingEm: 0.16,
    lineHeight: 1.8,
    paragraphSpacingEm: 1.5,
    surface: ReadingSurface.cream,
    boldText: false,
    readAloud: true,
    highlightSpokenWord: true,
    speechRate: 1.0,
    highlightConjuncts: true,
    splitConjuncts: false,
    emphasiseMatra: false,
    syllableBreaks: false,
    highlightCurrentLine: true,
    readingRuler: true,
    highlightCurrentParagraph: false,
    hideDecorativeImages: false,
    focusMode: true,
  );

  /// Starting point for the Custom condition — the mockup's `custom` config.
  /// It is only a seed; the moment a participant touches any control their own
  /// values replace these and are what gets logged.
  static const ReadingPreset customSeed = ReadingPreset(
    fontFamily: BanglaFont.notoSansBengali,
    fontSize: 28,
    letterSpacingEm: 0.04,
    wordSpacingEm: 0.24,
    lineHeight: 2.1,
    paragraphSpacingEm: 1.8,
    surface: ReadingSurface.lightYellow,
    boldText: false,
    readAloud: true,
    highlightSpokenWord: true,
    speechRate: 1.0,
    highlightConjuncts: true,
    splitConjuncts: true,
    emphasiseMatra: false,
    syllableBreaks: false,
    highlightCurrentLine: true,
    readingRuler: true,
    highlightCurrentParagraph: false,
    hideDecorativeImages: false,
    focusMode: true,
  );

  static ReadingPreset of(ReadingProfile profile) => switch (profile) {
        ReadingProfile.standard => standard,
        ReadingProfile.recommended => recommended,
        ReadingProfile.custom => customSeed,
      };
}

/// Live reading configuration.
///
/// Everything the participant can change about how a passage looks or sounds
/// lives here, and every mutation is announced to [SettingsChangeListener]s so
/// the session logger can persist it. Widgets must read from this object rather
/// than hard-coding sizes — that is the difference between a prototype that
/// demonstrates the idea and one that can be used to collect data.
class ReadingSettings extends ChangeNotifier {
  ReadingSettings({ReadingProfile initialProfile = ReadingProfile.standard}) {
    _profile = initialProfile;
    _assign(ReadingPreset.of(initialProfile));
  }

  // ---- Bounds (the Reading Settings screen must not exceed these) --------
  static const double minFontSize = 12;

  /// The design's slider went to 72 px, which no reading UI survives: at that
  /// size a single Bangla word fills the width and the app chrome around it
  /// breaks. 48 px is still far above the 22 px Recommended and 28 px Custom
  /// presets, and comfortably past the 40 px a low-vision reader asks for.
  static const double maxFontSize = 48;
  static const double minLetterSpacingEm = 0;
  static const double maxLetterSpacingEm = 0.20;
  static const double minWordSpacingEm = 0;
  static const double maxWordSpacingEm = 0.50;
  static const double minLineHeight = 1.0;
  static const double maxLineHeight = 3.0;
  static const double minParagraphSpacingEm = 0.5;
  static const double maxParagraphSpacingEm = 3.0;
  static const List<double> speechRates = [0.75, 1.0, 1.25];

  // ---- Typography -------------------------------------------------------
  late BanglaFont _fontFamily;
  late double _fontSize;
  late double _letterSpacingEm;
  late double _wordSpacingEm;
  late double _lineHeight;
  late double _paragraphSpacingEm;
  late ReadingSurface _surface;
  late bool _boldText;

  // ---- Read aloud -------------------------------------------------------
  late bool _readAloud;
  late bool _highlightSpokenWord;
  late double _speechRate;
  String _voiceLocale = 'bn-BD';

  // ---- Bangla reading support ------------------------------------------
  late bool _highlightConjuncts;
  late bool _splitConjuncts;
  late bool _emphasiseMatra;
  late bool _syllableBreaks;

  // ---- Reading focus ----------------------------------------------------
  late bool _highlightCurrentLine;
  late bool _readingRuler;
  late bool _highlightCurrentParagraph;
  late bool _hideDecorativeImages;
  late bool _focusMode;

  // ---- Condition --------------------------------------------------------
  late ReadingProfile _profile;

  /// Set while a preset is being applied, so the bulk assignment does not
  /// bounce the profile to Custom on its own first field.
  bool _applyingPreset = false;

  /// Participant's own configuration, kept alive while they are temporarily
  /// switched to Default or Recommended for the comparison task.
  ReadingPreset? _customSnapshot;

  final List<SettingsChangeListener> _observers = [];

  // ---- Getters ----------------------------------------------------------
  BanglaFont get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  double get letterSpacingEm => _letterSpacingEm;
  double get wordSpacingEm => _wordSpacingEm;
  double get lineHeight => _lineHeight;
  double get paragraphSpacingEm => _paragraphSpacingEm;
  ReadingSurface get surface => _surface;
  bool get boldText => _boldText;

  bool get readAloud => _readAloud;
  bool get highlightSpokenWord => _highlightSpokenWord;
  double get speechRate => _speechRate;
  String get voiceLocale => _voiceLocale;

  bool get highlightConjuncts => _highlightConjuncts;
  bool get splitConjuncts => _splitConjuncts;
  bool get emphasiseMatra => _emphasiseMatra;
  bool get syllableBreaks => _syllableBreaks;

  bool get highlightCurrentLine => _highlightCurrentLine;
  bool get readingRuler => _readingRuler;
  bool get highlightCurrentParagraph => _highlightCurrentParagraph;
  bool get hideDecorativeImages => _hideDecorativeImages;
  bool get focusMode => _focusMode;

  ReadingProfile get profile => _profile;

  // ---- Derived values used by the reading UI ----------------------------

  /// CSS `em` values from the design converted to the logical pixels Flutter
  /// wants. Storing em keeps spacing proportional when font size changes,
  /// which is what the mockup's sliders imply.
  double get letterSpacingPx => _letterSpacingEm * _fontSize;
  double get wordSpacingPx => _wordSpacingEm * _fontSize;
  double get paragraphSpacingPx => _paragraphSpacingEm * _fontSize;

  /// Height of a single line box, in logical pixels.
  double get lineHeightPx => _fontSize * _lineHeight;

  FontWeight get fontWeight => _boldText ? FontWeight.w700 : FontWeight.w400;

  /// The style every passage must be rendered with.
  TextStyle passageStyle({Color? color}) => TextStyle(
        fontFamily: _fontFamily.family,
        fontSize: _fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacingPx,
        wordSpacing: wordSpacingPx,
        height: _lineHeight,
        color: color ?? _surface.text,
      );

  // Display transforms (conjunct splitting, syllable breaks) live in
  // PassageTransform, not here: they have to return an offset map alongside the
  // transformed string, and this class must stay a plain settings holder.

  // ---- Observers --------------------------------------------------------
  void addChangeObserver(SettingsChangeListener listener) =>
      _observers.add(listener);

  void removeChangeObserver(SettingsChangeListener listener) =>
      _observers.remove(listener);

  void _record(String key, Object? from, Object? to) {
    if (_observers.isEmpty) return;
    final change = SettingsChange(
      key: key,
      from: from,
      to: to,
      profile: _profile,
      at: DateTime.now(),
    );
    for (final o in List.of(_observers)) {
      o(change);
    }
  }

  /// Every individual setter funnels through here: no change is silently
  /// applied, and touching anything by hand moves the participant into the
  /// Custom condition so the log never mislabels their data.
  void _change<T>(String key, T from, T to, void Function() assign) {
    if (from == to) return;
    assign();
    if (!_applyingPreset && _profile != ReadingProfile.custom) {
      final was = _profile;
      _profile = ReadingProfile.custom;
      _record('profile', was.id, ReadingProfile.custom.id);
    }
    _record(key, from, to);
    notifyListeners();
  }

  // ---- Typography setters ----------------------------------------------
  set fontFamily(BanglaFont value) => _change(
        'font_family',
        _fontFamily.id,
        value.id,
        () => _fontFamily = value,
      );

  set fontSize(double value) {
    final v = value.clamp(minFontSize, maxFontSize).toDouble();
    _change('font_size', _fontSize, v, () => _fontSize = v);
  }

  set letterSpacingEm(double value) {
    final v =
        value.clamp(minLetterSpacingEm, maxLetterSpacingEm).toDouble();
    _change('letter_spacing_em', _letterSpacingEm, v,
        () => _letterSpacingEm = v);
  }

  set wordSpacingEm(double value) {
    final v = value.clamp(minWordSpacingEm, maxWordSpacingEm).toDouble();
    _change('word_spacing_em', _wordSpacingEm, v, () => _wordSpacingEm = v);
  }

  set lineHeight(double value) {
    final v = value.clamp(minLineHeight, maxLineHeight).toDouble();
    _change('line_height', _lineHeight, v, () => _lineHeight = v);
  }

  set paragraphSpacingEm(double value) {
    final v = value
        .clamp(minParagraphSpacingEm, maxParagraphSpacingEm)
        .toDouble();
    _change('paragraph_spacing_em', _paragraphSpacingEm, v,
        () => _paragraphSpacingEm = v);
  }

  set surface(ReadingSurface value) =>
      _change('surface', _surface.id, value.id, () => _surface = value);

  set boldText(bool value) =>
      _change('bold_text', _boldText, value, () => _boldText = value);

  // ---- Read aloud setters ----------------------------------------------
  set readAloud(bool value) =>
      _change('read_aloud', _readAloud, value, () => _readAloud = value);

  set highlightSpokenWord(bool value) => _change(
        'highlight_spoken_word',
        _highlightSpokenWord,
        value,
        () => _highlightSpokenWord = value,
      );

  set speechRate(double value) =>
      _change('speech_rate', _speechRate, value, () => _speechRate = value);

  set voiceLocale(String value) =>
      _change('voice_locale', _voiceLocale, value, () => _voiceLocale = value);

  // ---- Bangla support setters ------------------------------------------
  set highlightConjuncts(bool value) => _change(
        'highlight_conjuncts',
        _highlightConjuncts,
        value,
        () => _highlightConjuncts = value,
      );

  set splitConjuncts(bool value) => _change(
        'split_conjuncts',
        _splitConjuncts,
        value,
        () => _splitConjuncts = value,
      );

  set emphasiseMatra(bool value) => _change(
        'emphasise_matra',
        _emphasiseMatra,
        value,
        () => _emphasiseMatra = value,
      );

  set syllableBreaks(bool value) => _change(
        'syllable_breaks',
        _syllableBreaks,
        value,
        () => _syllableBreaks = value,
      );

  // ---- Focus setters ----------------------------------------------------
  set highlightCurrentLine(bool value) => _change(
        'highlight_current_line',
        _highlightCurrentLine,
        value,
        () => _highlightCurrentLine = value,
      );

  set readingRuler(bool value) => _change(
        'reading_ruler',
        _readingRuler,
        value,
        () => _readingRuler = value,
      );

  set highlightCurrentParagraph(bool value) => _change(
        'highlight_current_paragraph',
        _highlightCurrentParagraph,
        value,
        () => _highlightCurrentParagraph = value,
      );

  set hideDecorativeImages(bool value) => _change(
        'hide_decorative_images',
        _hideDecorativeImages,
        value,
        () => _hideDecorativeImages = value,
      );

  set focusMode(bool value) =>
      _change('focus_mode', _focusMode, value, () => _focusMode = value);

  // ---- Profile switching ------------------------------------------------

  /// Switches research condition and applies its preset wholesale.
  ///
  /// Leaving Custom snapshots the participant's values; returning to Custom
  /// restores them, so a researcher can flip between conditions during a
  /// session without destroying the reader's own configuration.
  void applyProfile(ReadingProfile profile) {
    if (profile == _profile) return;

    if (_profile == ReadingProfile.custom) {
      _customSnapshot = snapshot();
    }

    final was = _profile;
    _applyingPreset = true;
    _profile = profile;
    _assign(
      profile == ReadingProfile.custom
          ? (_customSnapshot ?? ReadingPreset.customSeed)
          : ReadingPreset.of(profile),
    );
    _applyingPreset = false;

    _record('profile', was.id, profile.id);
    notifyListeners();
  }

  /// Back to the control condition, discarding the custom snapshot. Wired to
  /// "Reset all settings" on the Settings screen.
  void resetAll() {
    final was = _profile;
    _customSnapshot = null;
    _applyingPreset = true;
    _profile = ReadingProfile.standard;
    _assign(ReadingPreset.standard);
    _voiceLocale = 'bn-BD';
    _applyingPreset = false;
    _record('reset_all', was.id, ReadingProfile.standard.id);
    notifyListeners();
  }

  void _assign(ReadingPreset p) {
    _fontFamily = p.fontFamily;
    _fontSize = p.fontSize;
    _letterSpacingEm = p.letterSpacingEm;
    _wordSpacingEm = p.wordSpacingEm;
    _lineHeight = p.lineHeight;
    _paragraphSpacingEm = p.paragraphSpacingEm;
    _surface = p.surface;
    _boldText = p.boldText;
    _readAloud = p.readAloud;
    _highlightSpokenWord = p.highlightSpokenWord;
    _speechRate = p.speechRate;
    _highlightConjuncts = p.highlightConjuncts;
    _splitConjuncts = p.splitConjuncts;
    _emphasiseMatra = p.emphasiseMatra;
    _syllableBreaks = p.syllableBreaks;
    _highlightCurrentLine = p.highlightCurrentLine;
    _readingRuler = p.readingRuler;
    _highlightCurrentParagraph = p.highlightCurrentParagraph;
    _hideDecorativeImages = p.hideDecorativeImages;
    _focusMode = p.focusMode;
  }

  /// The current values as an immutable preset.
  ReadingPreset snapshot() => ReadingPreset(
        fontFamily: _fontFamily,
        fontSize: _fontSize,
        letterSpacingEm: _letterSpacingEm,
        wordSpacingEm: _wordSpacingEm,
        lineHeight: _lineHeight,
        paragraphSpacingEm: _paragraphSpacingEm,
        surface: _surface,
        boldText: _boldText,
        readAloud: _readAloud,
        highlightSpokenWord: _highlightSpokenWord,
        speechRate: _speechRate,
        highlightConjuncts: _highlightConjuncts,
        splitConjuncts: _splitConjuncts,
        emphasiseMatra: _emphasiseMatra,
        syllableBreaks: _syllableBreaks,
        highlightCurrentLine: _highlightCurrentLine,
        readingRuler: _readingRuler,
        highlightCurrentParagraph: _highlightCurrentParagraph,
        hideDecorativeImages: _hideDecorativeImages,
        focusMode: _focusMode,
      );

  /// Flat map for persistence and for the per-session CSV export. Keys match
  /// the [SettingsChange.key] strings so a log row and a settings column line
  /// up in analysis.
  Map<String, Object?> toMap() => {
        'profile': _profile.id,
        'font_family': _fontFamily.id,
        'font_size': _fontSize,
        'letter_spacing_em': _letterSpacingEm,
        'word_spacing_em': _wordSpacingEm,
        'line_height': _lineHeight,
        'paragraph_spacing_em': _paragraphSpacingEm,
        'surface': _surface.id,
        'bold_text': _boldText,
        'read_aloud': _readAloud,
        'highlight_spoken_word': _highlightSpokenWord,
        'speech_rate': _speechRate,
        'voice_locale': _voiceLocale,
        'highlight_conjuncts': _highlightConjuncts,
        'split_conjuncts': _splitConjuncts,
        'emphasise_matra': _emphasiseMatra,
        'syllable_breaks': _syllableBreaks,
        'highlight_current_line': _highlightCurrentLine,
        'reading_ruler': _readingRuler,
        'highlight_current_paragraph': _highlightCurrentParagraph,
        'hide_decorative_images': _hideDecorativeImages,
        'focus_mode': _focusMode,
      };

  /// Restores a persisted map without emitting change events — used at startup
  /// so resuming the app does not pollute the session log.
  void restoreFromMap(Map<String, Object?> map) {
    double d(String k, double fallback) =>
        (map[k] as num?)?.toDouble() ?? fallback;
    bool b(String k, bool fallback) => map[k] as bool? ?? fallback;

    _applyingPreset = true;
    _profile = ReadingProfile.fromId(map['profile'] as String?);
    _fontFamily = BanglaFont.fromId(map['font_family'] as String?);
    _fontSize = d('font_size', _fontSize).clamp(minFontSize, maxFontSize);
    _letterSpacingEm = d('letter_spacing_em', _letterSpacingEm)
        .clamp(minLetterSpacingEm, maxLetterSpacingEm);
    _wordSpacingEm = d('word_spacing_em', _wordSpacingEm)
        .clamp(minWordSpacingEm, maxWordSpacingEm);
    _lineHeight =
        d('line_height', _lineHeight).clamp(minLineHeight, maxLineHeight);
    _paragraphSpacingEm = d('paragraph_spacing_em', _paragraphSpacingEm)
        .clamp(minParagraphSpacingEm, maxParagraphSpacingEm);
    _surface = ReadingSurface.fromId(map['surface'] as String?);
    _boldText = b('bold_text', _boldText);
    _readAloud = b('read_aloud', _readAloud);
    _highlightSpokenWord = b('highlight_spoken_word', _highlightSpokenWord);
    _speechRate = d('speech_rate', _speechRate);
    _voiceLocale = map['voice_locale'] as String? ?? _voiceLocale;
    _highlightConjuncts = b('highlight_conjuncts', _highlightConjuncts);
    _splitConjuncts = b('split_conjuncts', _splitConjuncts);
    _emphasiseMatra = b('emphasise_matra', _emphasiseMatra);
    _syllableBreaks = b('syllable_breaks', _syllableBreaks);
    _highlightCurrentLine =
        b('highlight_current_line', _highlightCurrentLine);
    _readingRuler = b('reading_ruler', _readingRuler);
    _highlightCurrentParagraph =
        b('highlight_current_paragraph', _highlightCurrentParagraph);
    _hideDecorativeImages =
        b('hide_decorative_images', _hideDecorativeImages);
    _focusMode = b('focus_mode', _focusMode);
    _applyingPreset = false;

    notifyListeners();
  }
}
