import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app_language.dart';

/// Every piece of interface text, in both languages.
///
/// Written as one getter per string with both languages on the same line
/// rather than two files of key/value pairs: a translation that sits beside
/// its original cannot silently drift out of step with it, and a missing key
/// is a compile error instead of a screen that says `home.greeting`.
///
/// Passage text, questions and story titles are NOT here — those come from the
/// server and are Bangla in both modes, because they are the study material
/// rather than the interface around it.
///
/// The Bangla is machine-authored and needs a native speaker's eye before the
/// study runs. Wording that a child reads under pressure — the quiz feedback,
/// the error messages — matters most.
class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  static AppStrings of(BuildContext context) =>
      AppStrings(context.watch<LanguageState>().language);

  String _s(String bn, String en) =>
      language == AppLanguage.bangla ? bn : en;

  // ---- Shared -------------------------------------------------------------

  String get appName => _s('সহজপাঠ', 'Shohojpath');
  String get cancel => _s('বাতিল', 'Cancel');
  String get save => _s('সংরক্ষণ', 'Save');
  String get close => _s('বন্ধ করুন', 'Close');
  String get back => _s('পেছনে', 'Back');
  String get next => _s('পরের', 'Next');
  String get previous => _s('আগের', 'Previous');
  String get finish => _s('শেষ', 'Finish');
  String get tryAgain => _s('আবার চেষ্টা করুন', 'Try again');
  String get search => _s('খুঁজুন', 'Search');
  String get done => _s('হয়ে গেছে', 'Done');
  String get notAssignedYet => _s('এখনও দেওয়া হয়নি', 'Not assigned yet');

  // ---- Tabs ---------------------------------------------------------------

  String get tabHome => _s('হোম', 'Home');
  String get tabLibrary => _s('পাঠাগার', 'Library');
  String get tabProgress => _s('অগ্রগতি', 'Progress');
  String get tabProfile => _s('প্রোফাইল', 'Profile');

  // ---- Home ---------------------------------------------------------------

  String get goodMorning => _s('শুভ সকাল', 'Good morning');
  String get goodAfternoon => _s('শুভ অপরাহ্ন', 'Good afternoon');
  String get goodEvening => _s('শুভ সন্ধ্যা', 'Good evening');
  String get searchPassages => _s('গল্প খুঁজুন…', 'Search passages…');
  String get continueReading => _s('পড়া চালিয়ে যান', 'CONTINUE READING');
  String get startReading => _s('পড়া শুরু করুন', 'Start Reading');
  String get assignedByTherapist =>
      _s('আপনার থেরাপিস্ট যা দিয়েছেন', 'ASSIGNED BY YOUR THERAPIST');
  String get bookmarksTile => _s('বুকমার্ক', 'Bookmarks');
  String get historyTile => _s('পড়ার ইতিহাস', 'History');
  String get myProgress => _s('আমার অগ্রগতি', 'My Progress');
  String get settings => _s('সেটিংস', 'Settings');
  String get help => _s('সহায়তা', 'Help');
  String get about => _s('অ্যাপ সম্পর্কে', 'About');
  String get underAMinute => _s('এক মিনিটের কম', 'Under a minute');

  String passageCount(int n) => _s('$n টি গল্প', '$n passages');
  String savedCount(int n) => _s('$n টি রাখা আছে', '$n saved');
  String sessionCount(int n) => _s('$n বার পড়া', '$n sessions');
  String pageOf(int page, int total) =>
      _s('পৃষ্ঠা $page / $total', 'Page $page of $total');

  // ---- Library ------------------------------------------------------------

  String get readingLibrary => _s('পাঠাগার', 'Reading Library');
  String get searchByTitle =>
      _s('নাম বা বিষয় দিয়ে খুঁজুন', 'Search by title or topic');
  String get all => _s('সব', 'All');
  String get easy => _s('সহজ', 'Easy');
  String get medium => _s('মাঝারি', 'Medium');
  String get hard => _s('কঠিন', 'Hard');
  String get noPassagesFound => _s('কোনো গল্প পাওয়া যায়নি', 'No passages found');
  String get noPassagesBody => _s(
        'অন্য কিছু খুঁজে দেখুন বা ফিল্টার বদলান।',
        'Try a different search or filter. Passages are added by the research '
            'team in the admin.',
      );
  String get offlineLibraryNotice => _s(
        'ইন্টারনেট নেই — অ্যাপের সাথে থাকা গল্পটি দেখানো হচ্ছে। সব গল্প দেখতে '
            'ইন্টারনেটে যুক্ত হোন।',
        'Offline — showing the passage bundled with the app. Connect to see '
            'the full library.',
      );

  // ---- Reading ------------------------------------------------------------

  String get backToLibrary => _s('পাঠাগারে ফিরুন', 'Back to library');
  String get bookmarkThisPage => _s('এই পৃষ্ঠা বুকমার্ক করুন', 'Bookmark this page');
  String get removeBookmark => _s('বুকমার্ক সরান', 'Remove bookmark');
  String get openReadingSettings => _s('পড়ার সেটিংস', 'Open reading settings');
  String get settingsLocked =>
      _s('পড়ার সেটিংস (এই সেশনে বন্ধ)', 'Reading settings (locked for this session)');
  String get signInToBookmark =>
      _s('বুকমার্ক রাখতে সাইন ইন করুন।', 'Sign in to save bookmarks.');
  String get bookmarkRemoved => _s('বুকমার্ক সরানো হয়েছে।', 'Bookmark removed.');
  String bookmarkedPage(int page) =>
      _s('পৃষ্ঠা $page বুকমার্ক করা হয়েছে।', 'Bookmarked page $page.');

  // ---- Quiz ---------------------------------------------------------------

  String get comprehension => _s('বোঝাপড়া', 'Comprehension');
  String get multipleChoice => _s('বহু নির্বাচনী', 'MULTIPLE CHOICE');
  String get trueFalse => _s('সত্য / মিথ্যা', 'TRUE / FALSE');
  String get nextQuestion => _s('পরের প্রশ্ন', 'Next question');
  String get finishQuiz => _s('শেষ করুন', 'Finish quiz');
  String get readingTimeRecorded =>
      _s('পড়ার সময় নেওয়া হয়েছে', 'Reading time recorded');
  String get readingCondition => _s('পড়ার অবস্থা', 'Reading condition');
  String get audioOn =>
      _s('শব্দ সহায়তা: এই গল্পে চালু ছিল', 'Audio support: ON during this passage');
  String get audioOff =>
      _s('শব্দ সহায়তা: এই গল্পে বন্ধ ছিল', 'Audio support: OFF during this passage');

  /// Read by a child at the moment they find out they were wrong, so it says
  /// what to look at rather than scolding — and never names a colour, which
  /// tells a colour-blind child nothing.
  String get noQuestionsForPassage => _s(
        'এই গল্পের জন্য এখনও কোনো প্রশ্ন যোগ করা হয়নি।',
        'No comprehension questions are wired up for this passage yet.',
      );

  String get answerCorrect => _s('ঠিক হয়েছে!', 'Correct!');
  String get answerRevealed => _s(
        'সঠিক উত্তরটি চিহ্নিত করা হয়েছে।',
        'The correct answer is marked.',
      );

  // ---- Progress & statistics ---------------------------------------------

  String get timeToday => _s('আজকের সময়', 'Time today');
  String get pagesRead => _s('পড়া পৃষ্ঠা', 'Pages read');
  String get currentPassage => _s('এখন যে গল্প', 'Current passage');
  String get thisWeek => _s('এই সপ্তাহ', 'This week');
  String get detailedStatistics =>
      _s('বিস্তারিত পরিসংখ্যান', 'Detailed reading statistics');
  String get noReadingYet => _s('এখনও কিছু পড়া হয়নি', 'No reading recorded yet');
  String get noReadingYetBody => _s(
        'একটি গল্প শেষ করলে এখানে সময়, পৃষ্ঠা আর অগ্রগতি দেখা যাবে।',
        'Finish a passage and your time, pages and progress will appear here.',
      );
  String get readingStatistics => _s('পড়ার পরিসংখ্যান', 'Reading Statistics');
  String get readingSpeed => _s('পড়ার গতি', 'Reading speed');
  String get comprehensionPercent => _s('বোঝাপড়া', 'Comprehension');
  String get readAloudUsed => _s('শব্দ সহায়তা ব্যবহার', 'Read aloud used');
  String get averageSession => _s('গড় সময়', 'Average session');
  String get sessionsLogged => _s('মোট পড়া', 'Sessions logged');
  String get passagesRead => _s('পড়া গল্প', 'Passages read');
  String get wordsPerMinute => _s('মিনিটে শব্দ', 'Words per minute');
  String get noStatisticsYet => _s('এখনও পরিসংখ্যান নেই', 'No statistics yet');
  String get minutesShort => _s('মিনিট', 'min');
  String get pageWord => _s('পৃষ্ঠা', 'page');
  String get pagesWord => _s('পৃষ্ঠা', 'pages');
  String get passageNoLongerAvailable => _s(
        'গল্পটি আর পাঠাগারে নেই — আপনার পড়া তবু সংরক্ষিত আছে।',
        'No longer in the library — your reading is still recorded.',
      );

  // ---- Bookmarks & history ------------------------------------------------

  String get bookmarks => _s('বুকমার্ক', 'Bookmarks');
  String get noBookmarksYet => _s('এখনও কোনো বুকমার্ক নেই', 'No bookmarks yet');
  String get noBookmarksBody => _s(
        'পড়ার সময় বুকমার্ক আইকনে চাপ দিলে জায়গাটি এখানে জমা থাকবে।',
        'Tap the bookmark icon while reading to save your place.',
      );
  String get deleteBookmark => _s('বুকমার্ক মুছুন', 'Delete bookmark');
  String get readingHistory => _s('পড়ার ইতিহাস', 'Reading history');
  String get noHistoryYet => _s('এখনও কিছু নেই', 'Nothing here yet');

  // ---- Profile ------------------------------------------------------------

  String get profile => _s('প্রোফাইল', 'Profile');
  String get participantId => _s('অংশগ্রহণকারী আইডি', 'Participant ID');
  String get email => _s('ইমেইল', 'Email');
  String get age => _s('বয়স', 'Age');
  String get school => _s('স্কুল', 'School');
  String get readingProfile => _s('পড়ার ধরন', 'Reading profile');
  String get therapist => _s('থেরাপিস্ট', 'Therapist');
  String get changePassword => _s('পাসওয়ার্ড বদলান', 'Change password');
  String get logOut => _s('লগ আউট', 'Log out');

  // ---- Change password ----------------------------------------------------

  String get currentPassword => _s('বর্তমান পাসওয়ার্ড', 'Current password');
  String get newPassword => _s('নতুন পাসওয়ার্ড', 'New password');
  String get confirmNewPassword => _s('নতুন পাসওয়ার্ড আবার লিখুন', 'Confirm new password');
  String get atLeast8Characters => _s('অন্তত ৮টি অক্ষর', 'At least 8 characters');
  String get enterCurrentPassword =>
      _s('আপনার বর্তমান পাসওয়ার্ড লিখুন।', 'Enter your current password.');
  String get useAtLeast8 =>
      _s('অন্তত ৮টি অক্ষর ব্যবহার করুন।', 'Use at least 8 characters.');
  String get passwordsDoNotMatch => _s(
        'দুটি নতুন পাসওয়ার্ড মিলছে না।',
        'The two new passwords do not match.',
      );
  String get passwordChanged => _s('পাসওয়ার্ড বদলে গেছে।', 'Password changed.');
  String get saving => _s('সংরক্ষণ হচ্ছে…', 'Saving…');

  // ---- Auth ---------------------------------------------------------------

  String get createAnAccount => _s('অ্যাকাউন্ট তৈরি করুন', 'Create an account');
  String get signIn => _s('সাইন ইন', 'Sign in');
  String get signUp => _s('অ্যাকাউন্ট তৈরি', 'Create account');
  String get fullName => _s('পুরো নাম', 'Full name');
  String get password => _s('পাসওয়ার্ড', 'Password');
  String get iAmA => _s('আমি একজন…', 'I am a…');
  String get reader => _s('পাঠক', 'Reader');
  String get therapistRole => _s('থেরাপিস্ট', 'Therapist');
  String get schoolOptional => _s('স্কুল (ঐচ্ছিক)', 'School (optional)');
  String get signupHelpNote => _s(
        'আপনার নাম আর স্কুল থাকলে থেরাপিস্ট আপনাকে খুঁজে পেতে সহজ হয়।',
        'Your name and school help your therapist find you when they add you '
            'as their reader.',
      );

  // ---- Settings -----------------------------------------------------------

  String get languageHeading => _s('ভাষা', 'LANGUAGE');
  String get readingReminders => _s('পড়ার কথা মনে করানো', 'Reading reminders');
  String get resetAllSettings => _s('সব সেটিংস রিসেট করবেন?', 'Reset all settings?');
  String get resetAllSettingsBody => _s(
        'এতে পড়ার সব সেটিংস আবার ডিফল্ট অবস্থায় ফিরে যাবে। আপনার নিজের '
            'সাজানো সেটিংস মুছে যাবে।',
        'This returns every reading setting to the Default condition. Your '
            'custom configuration will be lost.',
      );
  String get reset => _s('রিসেট', 'Reset');
  String get settingsReset => _s(
        'পড়ার সব সেটিংস ডিফল্টে ফিরে গেছে।',
        'All reading settings reset to Default.',
      );

  // ---- Network & errors ---------------------------------------------------

  String get couldNotLoad => _s('এটি আনা যায়নি', 'Could not load this');
  String get offlineBanner => _s(
        'সার্ভারের সাথে যোগাযোগ নেই। আপনার কাজ এই ফোনে জমা আছে, ইন্টারনেট '
            'এলে পাঠিয়ে দেওয়া হবে।',
        'No connection to the server. Your work is saved on this device and '
            'will sync when you are back online.',
      );
  String get staleBanner => _s(
        'জমা থাকা তথ্য দেখানো হচ্ছে — সার্ভারে পৌঁছানো যায়নি।',
        'Showing saved data — could not reach the server.',
      );
  String get nothingHereYet => _s('এখানে এখনও কিছু নেই', 'Nothing here yet');
}

/// `context.t.startReading` at the call site.
extension AppStringsX on BuildContext {
  AppStrings get t => AppStrings.of(this);
}
