import 'package:flutter/foundation.dart';

import 'bangla_text.dart';

/// A pure-insertion transform from stored text to displayed text, with the
/// offset map that makes it reversible.
///
/// This exists because the display transforms (ZWNJ splitting, syllable dots)
/// change offsets, but everything *else* in the app speaks in offsets over the
/// original text: TTS progress callbacks report ranges in the string that was
/// handed to the engine, conjunct positions are found on the source, and the
/// session log records positions that must still mean something after a
/// participant changes their settings mid-passage.
///
/// The stored text is never modified. [display] is derived, and [toDisplay] /
/// [toOriginal] convert between the two coordinate systems.
@immutable
class DisplayMapping {
  const DisplayMapping._({
    required this.original,
    required this.display,
    required List<int> originalToDisplay,
    required List<int> displayToOriginal,
    required this.insertions,
  })  : _originalToDisplay = originalToDisplay,
        _displayToOriginal = displayToOriginal;

  /// An identity mapping, for when no transform is active.
  factory DisplayMapping.identity(String text) {
    final map = List<int>.generate(text.length + 1, (i) => i, growable: false);
    return DisplayMapping._(
      original: text,
      display: text,
      originalToDisplay: map,
      displayToOriginal: map,
      insertions: const [],
    );
  }

  /// The stored text. Never mutated.
  final String original;

  /// What actually gets laid out.
  final String display;

  /// Ranges of [display] that exist only for presentation and correspond to no
  /// original character — the syllable dots. Styled separately, and skipped
  /// when converting a display selection back to the source.
  final List<TextUnitRange> insertions;

  /// `_originalToDisplay[i]` is where original offset `i` starts in [display].
  /// Length is `original.length + 1` so the end offset maps too.
  final List<int> _originalToDisplay;

  /// `_displayToOriginal[i]` is the original offset that display offset `i`
  /// belongs to. Inserted characters map back to the original offset they were
  /// inserted at, so a round trip never lands outside the source.
  final List<int> _displayToOriginal;

  bool get isIdentity => insertions.isEmpty && original.length == display.length;

  int toDisplay(int originalOffset) =>
      _originalToDisplay[originalOffset.clamp(0, original.length)];

  int toOriginal(int displayOffset) =>
      _displayToOriginal[displayOffset.clamp(0, display.length)];

  TextUnitRange toDisplayRange(TextUnitRange r) =>
      TextUnitRange(toDisplay(r.start), toDisplay(r.end));

  TextUnitRange toOriginalRange(TextUnitRange r) =>
      TextUnitRange(toOriginal(r.start), toOriginal(r.end));

  /// True when [displayOffset] falls inside a presentation-only insertion.
  bool isInserted(int displayOffset) =>
      insertions.any((r) => r.contains(displayOffset));

  @override
  String toString() =>
      'DisplayMapping(${original.length} -> ${display.length} units, '
      '${insertions.length} insertions)';
}

/// Builds a [DisplayMapping] by walking the original text once and emitting
/// either a source character or an inserted one.
class DisplayMappingBuilder {
  DisplayMappingBuilder(this._original)
      : _originalToDisplay = List<int>.filled(_original.length + 1, 0);

  final String _original;
  final StringBuffer _display = StringBuffer();
  final List<int> _originalToDisplay;
  final List<int> _displayToOriginal = [];
  final List<TextUnitRange> _insertions = [];

  int _displayLength = 0;

  /// Copies original character at [index] through to the display string.
  void copy(int index) {
    _originalToDisplay[index] = _displayLength;
    _display.writeCharCode(_original.codeUnitAt(index));
    _displayToOriginal.add(index);
    _displayLength += 1;
  }

  /// Emits [text], which has no counterpart in the source.
  ///
  /// [anchor] is the original offset the insertion sits at, so a display offset
  /// inside it still converts back to a sensible place in the source.
  ///
  /// [presentational] marks the run as a visible artefact (a syllable dot) that
  /// should be styled and skipped on the way back. ZWNJ is left unmarked: it is
  /// invisible, carries no width, and behaves like part of the surrounding
  /// text for every purpose except shaping.
  void insert(String text, int anchor, {bool presentational = false}) {
    if (text.isEmpty) return;
    final start = _displayLength;
    for (var i = 0; i < text.length; i++) {
      _display.writeCharCode(text.codeUnitAt(i));
      _displayToOriginal.add(anchor);
      _displayLength += 1;
    }
    if (presentational) {
      _insertions.add(TextUnitRange(start, _displayLength));
    }
  }

  DisplayMapping build() {
    // The end-of-string offset must map too, or a range ending at the last
    // character has nowhere to land.
    _originalToDisplay[_original.length] = _displayLength;
    _displayToOriginal.add(_original.length);

    return DisplayMapping._(
      original: _original,
      display: _display.toString(),
      originalToDisplay: List<int>.unmodifiable(_originalToDisplay),
      displayToOriginal: List<int>.unmodifiable(_displayToOriginal),
      insertions: List<TextUnitRange>.unmodifiable(_insertions),
    );
  }
}
