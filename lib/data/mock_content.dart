import 'package:flutter/foundation.dart';

import '../models/passage.dart';
import 'passages.dart';

/// One row on the Reading Library screen. [passage] is null for the sample
/// titles carried over from the design mockup that have no real study text
/// behind them yet — tapping one of those says so rather than opening a
/// passage that does not exist.
@immutable
class LibraryEntry {
  const LibraryEntry({
    required this.title,
    required this.category,
    required this.time,
    required this.level,
    this.passage,
  });

  final String title;
  final String category;
  final String time;
  final String level;
  final Passage? passage;
}

@immutable
class HistoryEntry {
  const HistoryEntry({
    required this.title,
    required this.date,
    required this.time,
    required this.percent,
  });

  final String title;
  final String date;
  final String time;
  final String percent;
}

@immutable
class BookmarkEntry {
  const BookmarkEntry({required this.title, required this.excerpt});

  final String title;
  final String excerpt;
}

@immutable
class KeyValue {
  const KeyValue(this.key, this.value);

  final String key;
  final String value;
}

@immutable
class HelpFeature {
  const HelpFeature({
    required this.icon,
    required this.name,
    required this.description,
  });

  final IconDataId icon;
  final String name;
  final String description;
}

/// A small stand-in for [IconData] so this file doesn't have to import
/// `material.dart` just to name six icons — the Help screen maps these to
/// real [IconData] values.
enum IconDataId { volumeUp, spellcheck, formatSize, formatLineSpacing, ruler, bookmark }

@immutable
class Faq {
  const Faq({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// Static/sample content for the screens that are not yet backed by a real
/// backend or research database — library listing, history, bookmarks,
/// statistics, help copy, and the about page. Swap in real data sources as
/// the study infrastructure comes online.
abstract final class MockContent {
  static const List<LibraryEntry> library = [
    LibraryEntry(
      title: 'বৃষ্টির দিনে মিতু',
      category: 'Children Stories',
      time: '3 min',
      level: 'Easy',
      passage: Passages.bristirDineMitu,
    ),
    LibraryEntry(
      title: 'আমাদের গ্রাম',
      category: 'School Text',
      time: '5 min',
      level: 'Easy',
      passage: Passages.amaderGram,
    ),
    LibraryEntry(
      title: 'নদীর গল্প',
      category: 'Short Stories',
      time: '7 min',
      level: 'Medium',
      passage: Passages.nodirGolpo,
    ),
    LibraryEntry(
      title: 'বিজ্ঞান ও আমরা',
      category: 'Articles',
      time: '10 min',
      level: 'Hard',
      passage: Passages.bigganOAmra,
    ),
    LibraryEntry(
      title: 'আজকের খবর',
      category: 'News',
      time: '4 min',
      level: 'Medium',
      passage: Passages.ajkerKhobor,
    ),
  ];

  static const List<String> libraryCategories = [
    'All',
    'Children',
    'School',
    'Articles',
    'News',
  ];

  static const List<String> libraryDifficulties = ['Easy', 'Medium', 'Hard'];

  static const List<HistoryEntry> history = [
    HistoryEntry(
      title: 'বৃষ্টির দিনে মিতু',
      date: 'Today',
      time: '4 min 12 s',
      percent: '64%',
    ),
    HistoryEntry(
      title: 'আমাদের গ্রাম',
      date: 'Yesterday',
      time: '6 min 03 s',
      percent: '100%',
    ),
    HistoryEntry(
      title: 'নদীর গল্প',
      date: '28 Jul',
      time: '8 min 41 s',
      percent: '82%',
    ),
    HistoryEntry(
      title: 'আজকের খবর',
      date: '26 Jul',
      time: '3 min 55 s',
      percent: '100%',
    ),
  ];

  static const List<BookmarkEntry> bookmarks = [
    BookmarkEntry(
      title: 'বৃষ্টির দিনে মিতু',
      excerpt: 'মিতু দেখল, একটা ছোট পাখি ভিজে গিয়ে…',
    ),
    BookmarkEntry(
      title: 'নদীর গল্প',
      excerpt: 'নদীর ধারে সন্ধ্যা নামলে চারদিক শান্ত হয়ে…',
    ),
    BookmarkEntry(
      title: 'আমাদের গ্রাম',
      excerpt: 'আমাদের গ্রামের নাম শিমুলতলী।',
    ),
  ];

  static const List<KeyValue> statTiles = [
    KeyValue('Average session', '5 min 20 s'),
    KeyValue('Comprehension', '86%'),
    KeyValue('Sessions logged', '12'),
    KeyValue('Passages finished', '9'),
  ];

  static const List<KeyValue> mostUsedSettings = [
    KeyValue('Read aloud', '73%'),
    KeyValue('Conjunct highlight', '68%'),
    KeyValue('Line spacing 1.8', '64%'),
    KeyValue('Cream theme', '52%'),
  ];

  static const List<KeyValue> profilePrefs = [
    KeyValue('Read aloud', 'On · 1x'),
    KeyValue('Conjunct highlight', 'On'),
    KeyValue('Preferred font', 'Noto Sans Bengali'),
    KeyValue('Preferred theme', 'Cream'),
    KeyValue('Font size', '22 px'),
    KeyValue('Reading profile', 'Recommended'),
  ];

  static const List<HelpFeature> helpFeatures = [
    HelpFeature(
      icon: IconDataId.volumeUp,
      name: 'Read aloud',
      description: 'Bangla text-to-speech with word-by-word highlighting.',
    ),
    HelpFeature(
      icon: IconDataId.spellcheck,
      name: 'Conjunct support',
      description: 'Highlight or split যুক্তাক্ষর to reveal the spelling.',
    ),
    HelpFeature(
      icon: IconDataId.formatSize,
      name: 'Font & size control',
      description: 'Four Bangla typefaces, 12–72 px.',
    ),
    HelpFeature(
      icon: IconDataId.formatLineSpacing,
      name: 'Spacing control',
      description: 'Word, line and paragraph spacing.',
    ),
    HelpFeature(
      icon: IconDataId.ruler,
      name: 'Reading ruler',
      description: 'A guide bar that follows the line you read.',
    ),
    HelpFeature(
      icon: IconDataId.bookmark,
      name: 'Bookmarks & progress',
      description: 'Resume exactly where you stopped.',
    ),
  ];

  static const List<Faq> faqs = [
    Faq(
      question: 'Why does read aloud matter more than the font?',
      answer: 'Dyslexia is primarily a phonological difficulty, not a visual '
          'one — hearing the text addresses the decoding step directly, '
          'while no single font has been shown to do the same.',
    ),
    Faq(
      question: 'Can I use the app without an account?',
      answer: 'Yes — choose "Continue as Guest" on the sign-in screen. Your '
          'settings are still saved on this device.',
    ),
    Faq(
      question: 'Where is my reading data stored?',
      answer: 'Locally on this device, unless you export it or explicitly '
          'share anonymised data from Settings.',
    ),
  ];

  static const List<String> accessibilitySummary = [
    'WCAG AA contrast on all text',
    '14 px minimum text size',
    'Screen reader support with lang="bn"',
    'Text-to-speech with word tracking',
    '12–72 px scalable typography',
    'Conjunct decomposition (যুক্তাক্ষর)',
  ];

  /// University, researcher and supervisor are left as explicit placeholders
  /// pending the real research team's details.
  static const List<KeyValue> about = [
    KeyValue('University', '[ university / department ]'),
    KeyValue('Researcher', '[ researcher name ]'),
    KeyValue('Supervisor', '[ supervisor name ]'),
    KeyValue('Version', '1.0.0 (2026)'),
  ];
}
