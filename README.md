# সহজপাঠ · shohojpath

A dyslexia-friendly Bangla reading interface, built as an HCD research
prototype for a controlled user study.

> Design and Evaluation of a Dyslexia-Friendly Bangla Reading Interface Using
> Human-Centered Design Principles

Flutter, Android only. The reading settings genuinely drive the renderer, and
every settings change is announced with a timestamp and the active research
condition so sessions can be logged for the independent-variable analysis.

## Running it

```bash
flutter pub get
flutter run
```

**The project path must stay ASCII.** The Android native toolchain (cmake /
ninja) cannot handle non-ASCII directory names on Windows, so this cannot live
under a Bangla folder name. The Bengali title lives in `android:label` and the
`MaterialApp` title instead.

## What is here

| Area | Files |
| --- | --- |
| Bangla script analysis | `lib/utils/bangla_text.dart` |
| Display transform + offset map | `lib/utils/display_mapping.dart`, `lib/utils/passage_transform.dart` |
| Reading settings + research profiles | `lib/models/reading_settings.dart` |
| Passage renderer | `lib/widgets/bangla_passage.dart`, `lib/widgets/reading_aids_painter.dart` |
| Reading Interface screen | `lib/screens/reading_screen.dart` |
| Study material | `lib/data/passages.dart` |
| Original design mockup | `design/` |

### Conjunct handling

বাংলা যুক্তাক্ষর fuse their constituent letters into one glyph (ক + ্ + ষ
renders as ক্ষ), which is the decoding step readers with dyslexia struggle
with. Inserting U+200C ZWNJ after the hasant forces the explicit-halant form
(ক্‌ষ) and makes the spelling visible.

Splitting and syllable breaks are **display transforms only** — the stored text
is never modified. Because they are pure insertions, `DisplayMapping` can
convert offsets both ways, which matters because TTS reports progress in
offsets over the original string.

### Research conditions

Three profiles: **Default** (bare control condition), **Recommended**
(evidence-based preset) and **Custom** (the reader's own configuration).
Editing any control by hand moves the participant into Custom and logs the
flip, so a session is never mislabelled. Switching away from Custom snapshots
their values and switching back restores them.

## Tests

```bash
flutter test
```

The offset map is covered hardest: every offset in every paragraph of the
sample story is round-tripped with both transforms active.

## Status

Built so far: theme and design tokens, the reading settings model, the passage
renderer with conjunct handling and reading aids, and the Reading Interface
screen. An interim quick-settings sheet stands in for the full Reading Settings
screen.

Still to build: the remaining screens from the design, read-aloud word
tracking, sqflite session logging and CSV export.

## Disclaimer

This application is a reading support tool. It is not a diagnostic or
therapeutic instrument and does not replace assessment or instruction by
qualified professionals.
