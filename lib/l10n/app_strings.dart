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
  String minutesToday(int n) => _s('আজ $n মিনিট', '$n min today');
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
      _s('এই গল্পে পড়ে শোনানো চালু ছিল', 'Audio support: ON during this passage');
  String get audioOff =>
      _s('এই গল্পে পড়ে শোনানো বন্ধ ছিল', 'Audio support: OFF during this passage');

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
  String get readAloudUsed => _s('পড়ে শোনানো ব্যবহার', 'Read aloud used');
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

  // ---- Home cards ---------------------------------------------------------

  String get assignedByTherapistPlain =>
      _s('আপনার থেরাপিস্ট দিয়েছেন', 'Assigned by your therapist');
  String get startHere => _s('এখান থেকে শুরু করুন', 'START HERE');
  String get lastRead => _s('শেষ যা পড়েছেন', 'LAST READ');
  String get noReadingYetShort => _s('এখনও পড়া হয়নি', 'No reading yet');
  String get pickAPassage => _s(
        'শুরু করতে পাঠাগার থেকে একটি গল্প বেছে নিন। আপনার অগ্রগতি এখানে '
            'দেখা যাবে।',
        'Pick a passage from the Library to begin. Your progress will appear '
            'here.',
      );
  String get passageRetired => _s(
        'গল্পটি আর পাঠাগারে নেই',
        'That passage is no longer in the library',
      );
  String get passageRetiredBody => _s(
        'আপনার পড়া তবু সংরক্ষিত আছে। পাঠাগার থেকে নতুন কিছু বেছে নিন।',
        'Your reading is still recorded. Pick something new from the Library.',
      );
  String get nothingToday => _s('আজ কিছু নেই', 'Nothing today');
  String get passageHasNoPages =>
      _s('এই গল্পে এখনও কোনো পৃষ্ঠা নেই।', 'That passage has no pages yet.');
  String get passageHasNoPagesAdmin => _s(
        'এই গল্পে এখনও কোনো পৃষ্ঠা নেই। অ্যাডমিন থেকে যোগ করুন।',
        'That passage has no pages yet. Add them in the admin.',
      );

  // ---- Library extras -----------------------------------------------------

  String get difficulty => _s('কঠিনতা', 'DIFFICULTY');

  // ---- Bookmarks extras ---------------------------------------------------

  String pageNumber(int page) => _s('পৃষ্ঠা $page', 'Page $page');
  String get opening => _s('খুলছে…', 'Opening…');
  String get continueLabel => _s('চালিয়ে যান', 'Continue');

  // ---- Auth ---------------------------------------------------------------

  String get welcomeBack => _s('আবার স্বাগতম', 'Welcome back');
  String get signInBlurb => _s(
        'সাইন ইন করলে আপনার পড়ার সেটিংস আর অগ্রগতি সব ডিভাইসে জমা থাকবে।',
        'Sign in to save your reading settings and progress across devices.',
      );
  String get logIn => _s('লগ ইন', 'Log in');
  String get signingIn => _s('সাইন ইন হচ্ছে…', 'Signing in…');
  String get creatingAccount => _s('অ্যাকাউন্ট তৈরি হচ্ছে…', 'Creating account…');
  String get showPassword => _s('পাসওয়ার্ড দেখান', 'Show password');
  String get hidePassword => _s('পাসওয়ার্ড লুকান', 'Hide password');
  String get continueAsGuest => _s('অতিথি হিসেবে চালিয়ে যান', 'Continue as Guest');
  String get guestBlurb => _s(
        'অতিথি হিসেবে পড়লে সব কিছু শুধু এই ফোনেই থাকে — কিছুই পাঠানো হয় না।',
        'Guest reading stays on this device only — nothing is uploaded.',
      );
  String get newHere => _s('নতুন এসেছেন? ', 'New here? ');
  String get guest => _s('অতিথি', 'Guest');
  String get guestReader => _s('অতিথি পাঠক', 'Guest reader');
  String get enterYourEmail => _s('আপনার ইমেইল লিখুন।', 'Please enter your email.');
  String get enterYourPassword =>
      _s('আপনার পাসওয়ার্ড লিখুন।', 'Please enter your password.');
  String get enterAName => _s('একটি নাম লিখুন।', 'Please enter a name.');
  String get enterAnEmail =>
      _s('একটি ইমেইল ঠিকানা লিখুন।', 'Please enter an email address.');
  String get notAnEmail => _s(
        'এটি ইমেইল ঠিকানার মতো মনে হচ্ছে না।',
        'That does not look like an email address.',
      );
  String get noAccount => _s('অ্যাকাউন্ট নেই', 'No account');

  // ---- Profile ------------------------------------------------------------

  String get logOutQuestion => _s('লগ আউট করবেন?', 'Log out?');
  String get logOutBody => _s(
        'আপনার পড়ার সেটিংস আর অগ্রগতি এই ফোনে জমা থাকবে। আবার পড়তে হলে '
            'আবার সাইন ইন করতে হবে।',
        'Your reading settings and progress stay saved on this device. You '
            'will need to sign in again to continue reading.',
      );
  String get therapistPasswordToLogOut => _s(
        'এই সেশনটি একজন থেরাপিস্ট শুরু করেছেন। লগ আউট করতে থেরাপিস্টের '
            'পাসওয়ার্ড দিন।',
        "This session was started by a therapist. Enter the therapist's "
            'password to log out.',
      );
  String get myStatistics => _s('আমার পরিসংখ্যান', 'My statistics');
  String get appSettings => _s('অ্যাপ সেটিংস', 'App settings');
  String get classLabel => _s('শ্রেণি', 'Class');

  // ---- Reading profiles & surfaces ---------------------------------------

  String get profileDefault => _s('ডিফল্ট', 'Default');
  String get profileRecommended => _s('সুপারিশকৃত', 'Recommended');
  String get profileCustom => _s('নিজের মতো', 'Custom');
  String get surfaceWhite => _s('সাদা', 'White');
  String get surfaceCream => _s('ক্রিম', 'Cream');
  String get surfaceYellow => _s('হলুদ', 'Yellow');
  String get surfaceDark => _s('গাঢ়', 'Dark');
  String get surfaceContrast => _s('উচ্চ বৈসাদৃশ্য', 'Contrast');

  // ---- History ------------------------------------------------------------

  String get readingHistoryTitle => _s('পড়ার ইতিহাস', 'Reading History');
  String get noSessionsYet => _s('এখনও কোনো পড়া নেই', 'No sessions yet');
  String get noSessionsBody => _s(
        'পড়া শেষ হয়ে সিঙ্ক হলে এখানে দেখা যাবে।',
        'Finished readings appear here once they have synced.',
      );
  String get readerNoSessions => _s(
        'এই পাঠক এখনও কোনো পড়া শেষ করেননি।',
        'This reader has not completed a session yet.',
      );
  String get readAloudLabel => _s('পড়ে শোনানো', 'Read aloud');
  String get noAudio => _s('পড়ে শোনানো হয়নি', 'No audio');
  String get readAgain => _s('আবার পড়ুন', 'Read again');
  String get today => _s('আজ', 'Today');
  String get yesterday => _s('গতকাল', 'Yesterday');
  String daysAgo(int n) => _s('$n দিন আগে', '$n days ago');
  String get justNow => _s('এইমাত্র', 'Just now');
  String conditionLabel(String profile) =>
      _s('$profile অবস্থা', '$profile condition');

  // ---- Feedback, SUS, TLX -------------------------------------------------

  String get yourFeedback => _s('আপনার মতামত', 'Your Feedback');
  String quizScoreLine(int score, int total) =>
      _s('কুইজ ফল: $score / $total', 'Quiz score: $score / $total');
  String get wasReadingEasy => _s('পড়তে কি সহজ লেগেছে?', 'Was the reading easy?');
  String get didReadAloudHelp =>
      _s('পড়ে শোনানো কি কাজে লেগেছে?', 'Did read aloud help?');
  String get whichSettingsHelped =>
      _s('কোন সেটিংস সবচেয়ে বেশি কাজে লেগেছে?', 'Which settings helped most?');
  String get anySuggestions => _s('কিছু বলার আছে?', 'Any suggestions?');
  String get suggestionsHint => _s(
        'পড়া আরও সহজ করতে কী করা যায় লিখুন…',
        'Tell us what would make reading easier…',
      );
  String get continueToSus => _s('পরবর্তী ধাপে যান', 'Continue to SUS');
  String get continueToTlx => _s('পরবর্তী ধাপে যান', 'Continue to NASA-TLX');
  String get submitSession => _s('জমা দিন', 'Submit session');
  String get thankYou => _s('ধন্যবাদ!', 'Thank you!');
  String get thankYouBody => _s(
        'আপনার সেশন জমা হয়েছে। আপনার উত্তর আমাদের আরও ভালো পড়ার অ্যাপ '
            'বানাতে সাহায্য করবে।',
        'Your session has been recorded. Your responses help us design better '
            'reading support.',
      );
  String get readingTime => _s('পড়ার সময়', 'Reading time');
  String get susScore => _s('SUS স্কোর', 'SUS score');
  String get backToHome => _s('হোমে ফিরুন', 'Back to Home');
  String get veryLow => _s('খুব কম', 'Very low');
  String get veryHigh => _s('খুব বেশি', 'Very high');
  String get optionalWorkload =>
      _s('ঐচ্ছিক · কাজের চাপ', 'Optional · workload rating');

  // ---- Notifications ------------------------------------------------------

  String get notifications => _s('বার্তা', 'Notifications');
  String get markAllRead => _s('সব পড়া হয়েছে', 'Mark all read');
  String get noMessages => _s('কোনো বার্তা নেই', 'No messages');
  String get tapToMarkRead =>
      _s('পড়া হয়েছে বলে চিহ্নিত করুন', 'Tap to mark as read');

  // ---- Splash / About / Help ---------------------------------------------

  String get loadingPreferences =>
      _s('আপনার সেটিংস আনা হচ্ছে…', 'Loading your preferences…');
  String get getStarted => _s('শুরু করুন', 'Get Started');
  String get versionLine =>
      _s('সংস্করণ ১.০ · গবেষণা সংস্করণ', 'Version 1.0 · Research Prototype');
  String get researchTitle => _s('গবেষণার শিরোনাম', 'RESEARCH TITLE');
  String get accessibilitySummary => _s('প্রবেশগম্যতা', 'Accessibility summary');
  String get disclaimer => _s('দ্রষ্টব্য', 'Disclaimer');
  String get howToUse =>
      _s('সহজপাঠ যেভাবে ব্যবহার করবেন', 'How to use Shohojpath');
  String get accessibilityFeatures => _s('সহায়ক সুবিধা', 'Accessibility features');
  String get contactResearchTeam =>
      _s('গবেষক দলের সাথে যোগাযোগ', 'Contact the research team');

  // ---- Reading screen -----------------------------------------------------

  String get tapUnderlinedConjunct => _s(
        'যেকোনো দাগ দেওয়া যুক্তাক্ষরে চাপ দিন — দেখা ও শোনা যাবে',
        'Tap any underlined conjunct to see and hear it',
      );
  String get tapAnyConjunct => _s(
        'যেকোনো যুক্তাক্ষরে চাপ দিন — দেখা ও শোনা যাবে',
        'Tap any conjunct to see and hear it',
      );
  String readingModeLine(String profile) =>
      _s('পড়ার ধরন · $profile', 'READING MODE · $profile');
  String get pauseReadAloud => _s('পড়া থামান', 'Pause read aloud');
  String get resumeReadAloud => _s('আবার শুরু করুন', 'Resume read aloud');
  String get playReadAloud => _s('পড়ে শোনান', 'Play read aloud');
  String get stopReadAloud => _s('বন্ধ করুন', 'Stop read aloud');
  String get wordHighlightOn =>
      _s('শব্দ চিহ্নিত করা চালু', 'Word highlighting on');
  String get wordHighlightOff =>
      _s('শব্দ চিহ্নিত করা বন্ধ', 'Word highlighting off');
  String get noBanglaVoiceShort =>
      _s('বাংলা কণ্ঠ পাওয়া যায়নি', 'No Bangla voice found');
  String get androidTtsSettings =>
      _s('অ্যান্ড্রয়েড TTS সেটিংস', 'Android TTS settings');
  String get noBanglaVoiceInline => _s(
        'এই ফোনে বাংলা কণ্ঠ নেই — যোগ করুন ',
        'No Bangla voice on this device — install one in ',
      );
  String get noBanglaVoiceBody => _s(
        'এই ফোনে বাংলা টেক্সট-টু-স্পিচ কণ্ঠ নেই, তাই পড়ে শোনানো যাবে না।',
        'This device has no Bengali text-to-speech voice installed, so read '
            'aloud is unavailable.',
      );
  String get noBanglaVoiceHow => _s(
        'অ্যান্ড্রয়েড সেটিংস > ভাষা ও ইনপুট > টেক্সট-টু-স্পিচ থেকে যোগ করে '
            'আবার এই গল্পে আসুন।',
        'Install one from Android Settings > Language & input > '
            'Text-to-speech, then come back to this passage.',
      );
  String get hearThisConjunct =>
      _s('যুক্তাক্ষরটি শুনুন', 'Hear this conjunct read aloud');
  String get endSession => _s('সেশন শেষ করুন', 'End session');

  // ---- Reading settings ---------------------------------------------------

  String get readingSettingsTitle => _s('পড়ার সেটিংস', 'Reading Settings');
  String get closeReadingSettings =>
      _s('সেটিংস বন্ধ করুন', 'Close reading settings');
  String get readAloudSection => _s('পড়ে শোনানো', 'Read Aloud');
  String get evidenceBased => _s('গবেষণা-ভিত্তিক', 'Evidence-based');
  String get personalPreference => _s('ব্যক্তিগত পছন্দ', 'Personal preference');
  String get researchFeature => _s('গবেষণার সুবিধা', 'Research feature');
  String get comfort => _s('আরাম', 'Comfort');
  String get highlightSpokenWord => _s(
        'যে শব্দ পড়া হচ্ছে তা চিহ্নিত করুন',
        'Highlight each word as it is spoken',
      );
  String get speed => _s('গতি', 'Speed');
  String get voice => _s('কণ্ঠ', 'Voice');
  String get banglaReadingSupport =>
      _s('বাংলা পড়ার সহায়তা', 'Bangla Reading Support');
  String get highlightConjuncts =>
      _s('যুক্তাক্ষর চিহ্নিত করুন', 'Highlight conjuncts');
  String get splitConjuncts => _s(
        'যুক্তাক্ষর আলাদা করুন: ক্ষ দেখাবে ক্‌ + ষ',
        'Split conjuncts: ক্ষ shows as ক্‌ + ষ',
      );
  String get emphasiseMatra =>
      _s('মাত্রা স্পষ্ট করুন', 'Emphasise the matra headline');
  String get syllableBreaks =>
      _s('বড় শব্দে অক্ষর ভাগ করুন', 'Syllable breaks in long words');
  String get typography => _s('অক্ষরের ধরন', 'Typography');
  String get fontSize => _s('অক্ষরের আকার', 'Font size');
  String get boldText => _s('মোটা অক্ষর', 'Bold text');
  String get spacing => _s('ফাঁক', 'Spacing');
  String get letterSpacing => _s('অক্ষরের ফাঁক', 'Letter spacing');
  String get wordSpacing => _s('শব্দের ফাঁক', 'Word spacing');
  String get lineSpacing => _s('লাইনের ফাঁক', 'Line spacing');
  String get paragraphSpacing => _s('অনুচ্ছেদের ফাঁক', 'Paragraph spacing');
  String get theme => _s('রং', 'Theme');
  String get readingFocus => _s('পড়ায় মনোযোগ', 'Reading focus');
  String get highlightCurrentLine =>
      _s('চলতি লাইন চিহ্নিত করুন', 'Highlight current line');
  String get readingRuler => _s('পড়ার রুলার', 'Reading ruler');
  String get highlightCurrentParagraph =>
      _s('চলতি অনুচ্ছেদ চিহ্নিত করুন', 'Highlight current paragraph');
  String get hideImages => _s('ছবি লুকান', 'Hide decorative images');
  String get focusMode => _s('মনোযোগ মোড', 'Focus mode');
  String get readingAssistance => _s('পড়ার সহায়তা', 'Reading assistance');
  String get returnToReading => _s('পড়ায় ফিরুন', 'Return to reading');
  String get applyAndReturn => _s('প্রয়োগ করে ফিরুন', 'Apply & return');
  String get settingsLockedForSession => _s(
        'এই সেশনে সেটিংস বন্ধ রাখা হয়েছে',
        'Settings are locked for this session',
      );
  String get unlockTherapist => _s('খুলুন (থেরাপিস্ট)', 'Unlock (therapist)');
  String get unlockSettings => _s('সেটিংস খুলুন', 'Unlock settings');
  String get unlock => _s('খুলুন', 'Unlock');
  String get readingProfileHeading => _s('পড়ার ধরন', 'READING PROFILE');
  String get bookmark => _s('বুকমার্ক', 'Bookmark');
  String get dictionary => _s('অভিধান', 'Dictionary');
  String get highlight => _s('দাগ দিন', 'Highlight');

  // ---- Statistics ---------------------------------------------------------

  String get wordsReadThisWeek =>
      _s('এই সপ্তাহে পড়া শব্দ', 'WORDS READ THIS WEEK');
  String get sameAsLastWeek => _s('গত সপ্তাহের সমান', 'Same as last week');
  String get settingsChangedMost =>
      _s('যে সেটিংস সবচেয়ে বেশি বদলেছে', 'Settings changed most');
  String get noSettingsChanged => _s(
        'এখনও কোনো সেটিংস বদলানো হয়নি।',
        'No settings have been changed yet.',
      );
  String get noStatisticsBody => _s(
        'প্রথম পড়া শেষ হয়ে সিঙ্ক হলে গতি, বোঝাপড়া আর সেটিংস ব্যবহারের হিসাব '
            'দেখা যাবে।',
        'Reading speed, comprehension and settings use are calculated once '
            'the first session has been completed and synced.',
      );

  // ---- Errors -------------------------------------------------------------

  String get errorTimeout => _s(
        'সার্ভার সাড়া দিতে অনেক সময় নিচ্ছে। একটু পরে আবার চেষ্টা করুন।',
        'The server took too long to respond. It may be waking up — try again '
            'in a moment.',
      );
  String get errorBadRequest =>
      _s('অনুরোধটি ঠিক ছিল না।', 'That request was not valid.');
  String get errorSignInAgain =>
      _s('আবার সাইন ইন করুন।', 'Please sign in again.');
  String get errorForbidden => _s(
        'এটি করার অনুমতি আপনার নেই।',
        'You do not have permission to do that.',
      );
  String get errorNotFound => _s('পাওয়া যায়নি।', 'Not found.');
  String get errorConflict => _s(
        'এটি ইতিমধ্যে অন্য কেউ করে ফেলেছেন।',
        'That has already been done by someone else.',
      );
  String get errorServer => _s(
        'সার্ভারে সমস্যা হয়েছে। একটু পরে আবার চেষ্টা করুন।',
        'The server had a problem. Try again shortly.',
      );

  // ---- Reading settings captions -----------------------------------------

  String get captionAudioSupport => _s(
        'ডিসলেক্সিয়া মূলত ধ্বনি চেনার অসুবিধা। পড়ে শোনানো সরাসরি সেখানেই '
            'কাজ করে।',
        'Dyslexia is a phonological difficulty. Audio support addresses it '
            'directly.',
      );
  String get captionConjuncts => _s(
        'বাংলা যুক্তাক্ষর ভেতরের অক্ষরগুলো ঢেকে রাখে। এই সুবিধাগুলো সেগুলো '
            'স্পষ্ট করে দেখায়।',
        'Bangla conjuncts hide the letters inside them. These options make the '
            'parts visible.',
      );
  String get captionFontChoice => _s(
        'অক্ষরের ধরন আরামের ব্যাপার। কোনো একটি ফন্ট সবার জন্য ভালো — গবেষণায় '
            'তা প্রমাণিত হয়নি।',
        'Font choice is a comfort preference. Research has not shown any '
            'single font to be better for everyone.',
      );
  String get captionFontSizeApplies => _s(
        'এটি গল্পের লেখায় প্রয়োগ হয়। বোতাম আর লেখাও একটু বড় হয়, তবে অ্যাপ '
            'যেন ব্যবহারযোগ্য থাকে সেই সীমা পর্যন্ত।',
        'Applies to the passage. Buttons and labels grow with it up to a '
            'limit, so the app stays usable.',
      );
  String get captionThemeComfort => _s(
        'পেছনের রং আরামে প্রভাব ফেলে, পড়ার সঠিকতায় নয়।',
        'Background colour affects comfort, not decoding accuracy.',
      );
  String get captionIllustrations => _s(
        'ছবি সাধারণত সাহায্য করে, তবে কারও কারও মনোযোগ সরে যায়।',
        'Illustrations often help, but can distract some readers.',
      );
  String get profileDescDefault => _s(
        'মূল অবস্থা — কোনো সহায়তা ছাড়া, গবেষণার নিয়ন্ত্রণ শর্ত।',
        'Baseline — no reading aids, the study control.',
      );
  String get profileDescRecommended => _s(
        'গবেষণা-ভিত্তিক: পড়ে শোনানো, বেশি ফাঁক, ক্রিম পটভূমি।',
        'Evidence-based: audio, spacing, cream background.',
      );
  String get profileDescCustom => _s(
        'আপনার নিজের সাজানো, তুলনার জন্য সংরক্ষিত।',
        'Your own configuration, saved for comparison.',
      );

  // ---- Therapist ----------------------------------------------------------

  String get myReaders => _s('আমার পাঠকরা', 'My Readers');
  String get therapistProfile => _s('থেরাপিস্ট প্রোফাইল', 'Therapist profile');
  String get readers => _s('পাঠক', 'Readers');
  String get sessionsThisWeek => _s('এই সপ্তাহের পড়া', 'Sessions this week');
  String get susAverage => _s('SUS গড়', 'SUS average');
  String get searchReaders => _s('পাঠক খুঁজুন', 'Search readers');
  String get activeCaseload => _s('চলমান পাঠক', 'ACTIVE CASELOAD');
  String get sortedByLastActive =>
      _s('শেষ সক্রিয়তার ক্রমে', 'Sorted by last active');
  String get noReadersYet => _s(
        'এখনও কোনো পাঠক নেই। শুরু করতে একজন যোগ করুন।',
        'No readers yet. Add one to get started.',
      );
  String get addReader => _s('পাঠক যোগ করুন', 'Add Reader');
  String get addAReader => _s('একজন পাঠক যোগ করুন', 'Add a reader');
  String get startSession => _s('সেশন শুরু করুন', 'Start session');
  String get never => _s('কখনও নয়', 'Never');
  String get active => _s('সক্রিয়', 'Active');
  String get quietLately => _s('ইদানীং কম', 'Quiet lately');
  String get inactive => _s('নিষ্ক্রিয়', 'Inactive');
  String get readingRegularly => _s('নিয়মিত পড়ছে', 'Reading regularly');
  String ageLabel(int age) => _s('বয়স $age', 'Age $age');

  String get addNote => _s('নোট যোগ করুন', 'Add note');
  String get notePrompt => _s(
        'এই সেশনে কী লক্ষ করলেন?',
        'What did you observe this session?',
      );
  String get export => _s('রপ্তানি', 'Export');
  String get sessions => _s('পড়া', 'Sessions');
  String get notes => _s('নোট', 'Notes');
  String get readingSpeedHeading => _s('পড়ার গতি', 'READING SPEED');
  String get accuracyHeading => _s('সঠিকতা', 'ACCURACY');
  String get quizScorePerPassage => _s(
        'প্রতিটি শেষ করা গল্পে কুইজের ফল',
        'Quiz score on each completed passage',
      );
  String get totalWordsRead => _s('মোট পড়া শব্দ', 'Total words read');
  String get totalReadingTime => _s('মোট পড়ার সময়', 'Total reading time');
  String get comprehensionAverage => _s('বোঝাপড়ার গড়', 'Comprehension average');
  String get readAloudUsage => _s('পড়ে শোনানো ব্যবহার', 'Read-aloud usage');
  String get assignPassages => _s('গল্প ঠিক করে দিন', 'Assign passages');
  String get assignPassagesTitle => _s('গল্প ঠিক করুন', 'Assign Passages');
  String get noSessionsLogged => _s('এখনও কোনো পড়া নেই।', 'No sessions logged yet.');
  String get noNotesYet => _s('এখনও কোনো নোট নেই।', 'No notes yet.');
  String get settingsActuallyUsed =>
      _s('আসলে যে সেটিংস ব্যবহার হয়েছে', 'Settings actually used');
  String get audioOnShort => _s('পড়ে শোনানো চালু', 'Audio on');
  String get audioOffShort => _s('পড়ে শোনানো বন্ধ', 'Audio off');
  String quizScoreShort(int score, int total) =>
      _s('কুইজ $score / $total', 'Quiz $score / $total');

  String get refresh => _s('নতুন করে আনুন', 'Refresh');
  String get searchByNameIdSchool =>
      _s('নাম, আইডি বা স্কুল দিয়ে খুঁজুন', 'Search by name, ID or school');
  String get clearSearch => _s('খোঁজা মুছুন', 'Clear search');
  String get couldNotLoadReaders =>
      _s('পাঠকদের তালিকা আনা যায়নি', 'Could not load readers');
  String get noMatch => _s('মিল পাওয়া যায়নি', 'No match');
  String get everyoneAdded => _s('সবাই যোগ করা হয়ে গেছে', 'Everyone has been added');
  String claimedFirst(String name) => _s(
        '$name-কে আগেই অন্য একজন থেরাপিস্ট যোগ করে নিয়েছেন।',
        'Another therapist added $name first.',
      );

  String get notSignedIn => _s('সাইন ইন করা নেই', 'Not signed in');
  String get speechLanguageTherapist =>
      _s('স্পিচ ও ল্যাঙ্গুয়েজ থেরাপিস্ট', 'Speech & Language Therapist');
  String get readersManaged => _s('দেখাশোনা করা পাঠক', 'Readers managed');
  String get exportAllCsv => _s('সব তথ্য CSV হিসেবে নিন', 'Export all data as CSV');
  String get helpAndSupport => _s('সহায়তা', 'Help & support');
  String get noPassagesMatch =>
      _s('এই ফিল্টারে কোনো গল্প নেই।', 'No passages match these filters.');
  String get allReaders => _s('সব পাঠক', 'All Readers');
  String get searchByName => _s('নাম দিয়ে খুঁজুন', 'Search by name');
  String get searchById => _s('আইডি দিয়ে খুঁজুন', 'Search by ID');
  String get noReadersMatch =>
      _s('আপনার খোঁজার সাথে কোনো পাঠক মিলছে না।', 'No readers match your search.');
  String get dashboard => _s('ড্যাশবোর্ড', 'Dashboard');
  String get incorrectPassword => _s('পাসওয়ার্ড ঠিক নয়।', 'Incorrect password.');

  String get researcher => _s('গবেষক', 'Researcher');
  String get readersRegistered => _s('নিবন্ধিত পাঠক', 'Readers registered');
  String get clearAllData => _s('সব তথ্য মুছুন', 'Clear all data');
  String get clearAllDataQuestion => _s('সব তথ্য মুছে ফেলবেন?', 'Clear all data?');
  String get clearEverything => _s('সব মুছে ফেলুন', 'Clear everything');
  String get allDataCleared => _s('সব সেশনের তথ্য মুছে গেছে।', 'All session data cleared.');

  // ---- Remaining chrome ---------------------------------------------------

  String get sessionSoundEffects => _s('সেশনের শব্দ', 'Session sound effects');
  String get shareAnonymisedData =>
      _s('নাম ছাড়া তথ্য শেয়ার করুন', 'Share anonymised data');
  String get exportSessionData => _s('সেশনের তথ্য নিন', 'Export session data');
  String get csvForAnalysis =>
      _s('গবেষণার বিশ্লেষণের জন্য CSV', 'CSV for research analysis');
  String get privacyAndConsent => _s('গোপনীয়তা ও সম্মতি', 'Privacy & consent');
  String get noNotificationsBody => _s(
        'কোনো থেরাপিস্ট আপনাকে যোগ করলে বা কোনো গল্প ঠিক করে দিলে সেই বার্তা '
            'এখানে আসবে।',
        'When a therapist adds you or assigns a passage, the message will '
            'appear here.',
      );
  String get schoolExampleHint => _s('শিমুলতলী উচ্চ বিদ্যালয়', 'Shimultoli High');
  String get start => _s('শুরু', 'Start');
  String get exportFailed => _s('রপ্তানি করা যায়নি', 'Export failed');
  String get signInCaptionNames => _s(
        'ডিফল্ট — ঘরে একজনের ব্যবহারের ফোনের জন্য।',
        'Default — for a single-user device at home.',
      );
  String get signInCaptionIds =>
      _s('গবেষণার শেয়ার করা ফোনের জন্য।', 'For shared study devices.');
  String get signInCaptionOff => _s(
        'পাঠক বাছাই লুকিয়ে রাখে; প্রতিটি সেশন থেরাপিস্ট ড্যাশবোর্ড থেকে শুরু হয়।',
        'Hides the reader picker; every session starts from the Therapist '
            'Dashboard.',
      );
  String get readerSignInNames => _s('নাম', 'Names');
  String get readerSignInIds => _s('শুধু আইডি', 'Participant IDs only');
  String get readerSignInOff => _s(
        'বন্ধ — থেরাপিস্টই সব সেশন শুরু করবেন',
        'Off — therapist starts all sessions',
      );

  // ---- System Usability Scale ---------------------------------------------

  /// The ten SUS statements.
  ///
  /// The English is Brooke's original wording, kept exactly: the 68-point
  /// benchmark this study compares against was established on it, and an
  /// edited item is no longer the same instrument. The Bangla is a working
  /// translation supplied by the research team — it has not been through the
  /// forward/back-translation and pilot that a validated version requires, so
  /// scores from it must be reported as coming from a non-validated
  /// translation rather than compared to 68 as though nothing changed.
  List<String> get susItems => [
        _s('আমার মনে হয় আমি এই অ্যাপটি ঘনঘন ব্যবহার করতে চাইবো।',
            'I think that I would like to use this app frequently.'),
        _s('অ্যাপটি আমার কাছে অপ্রয়োজনীয়ভাবে জটিল মনে হয়েছে।',
            'I found the app unnecessarily complex.'),
        _s('অ্যাপটি ব্যবহার করা বেশ সহজ ছিল।',
            'I thought the app was easy to use.'),
        _s(
          'এই অ্যাপটি ঠিকঠাক চালাতে আমার কোনো টেকনিক্যাল মানুষের সাহায্য লাগবে।',
          'I think that I would need the support of a technical person to be '
              'able to use this app.',
        ),
        _s('অ্যাপের বিভিন্ন ফিচার ও ফাংশনগুলো খুব চমৎকারভাবে সাজানো আছে।',
            'I found the various functions in this app were well integrated.'),
        _s('আমার মনে হয়েছে এই অ্যাপটিতে অনেক অসামঞ্জস্য আছে।',
            'I thought there was too much inconsistency in this app.'),
        _s(
          'আমার ধারণা বেশিরভাগ মানুষ খুব দ্রুত এই অ্যাপটি ব্যবহার করা শিখে যাবে।',
          'I would imagine that most people would learn to use this app very '
              'quickly.',
        ),
        _s('অ্যাপটি ব্যবহার করার সময় আমার কাছে এটি বেশ ঝামেলার মনে হয়েছে।',
            'I found the app very cumbersome to use.'),
        _s('অ্যাপটি ব্যবহার করার সময় আমি খুব আত্মবিশ্বাসী ছিলাম।',
            'I felt very confident using the app.'),
        _s(
          'এই অ্যাপটি ব্যবহার শুরু করার আগে আমাকে অনেক কিছু শিখে নিতে হয়েছে।',
          'I needed to learn a lot of things before I could get going with '
              'this app.',
        ),
      ];

  String get susTitle => _s('ব্যবহারযোগ্যতার মূল্যায়ন', 'System Usability Scale');
  String get susSubtitle => _s(
        '১০টি বাক্য · ১ = একদম দ্বিমত, ৫ = একদম একমত',
        '10 statements · 1 = strongly disagree, 5 = strongly agree',
      );
  String get susLiveScore => _s('এখনকার SUS স্কোর', 'LIVE SUS SCORE');
  String get susAboveBenchmark =>
      _s('৬৮-এর বেঞ্চমার্কের ওপরে', 'Above the 68 benchmark');
  String get susBelowBenchmark =>
      _s('৬৮-এর বেঞ্চমার্কের নিচে', 'Below the 68 benchmark');
  String get susAnswerAll =>
      _s('স্কোর দেখতে ১০টিরই উত্তর দিন', 'Answer all 10 to see the score');

  // ---- Supervision requests ----------------------------------------------

  String get askToAdd => _s('অনুরোধ পাঠান', 'Ask');
  String get requestSent => _s('অনুরোধ পাঠানো হয়েছে', 'Request sent');
  String requestSentTo(String name) => _s(
        '$name-কে অনুরোধ পাঠানো হয়েছে। তিনি রাজি হলে আপনার তালিকায় যুক্ত হবেন।',
        'Request sent to $name. They will join your list if they accept.',
      );
  String get supervisionRequestTitle =>
      _s('একজন থেরাপিস্ট আপনাকে যুক্ত করতে চান', 'A therapist wants to add you');
  String get accept => _s('রাজি', 'Accept');
  String get decline => _s('না', 'Decline');
  String acceptedTherapist(String name) => _s(
        'আপনি $name-এর সাথে যুক্ত হয়েছেন।',
        'You are now working with $name.',
      );
  String get declinedRequest => _s(
        'অনুরোধটি ফিরিয়ে দেওয়া হয়েছে।',
        'Request declined.',
      );
  String get requestAlreadyAnswered => _s(
        'এই অনুরোধের উত্তর আগেই দেওয়া হয়েছে।',
        'This request has already been answered.',
      );

  // ---- Auth screen leftovers ---------------------------------------------

  String get emailHint => _s('you@example.com', 'you@example.com');
  String get nameHintReader => _s('যেমন: মিতু রহমান', 'e.g. Mitu Rahman');
  String get nameHintTherapist => _s('যেমন: ডাঃ এ. করিম', 'e.g. Dr A. Karim');
  String get or => _s('অথবা', 'OR');
  String get alreadyHaveAccount =>
      _s('আমার অ্যাকাউন্ট আছে', 'I already have an account');
  String get signInBlurbSessions => _s(
        'সাইন ইন করলে আপনার পড়ার সেটিংস আর অগ্রগতি প্রতিবার জমা থাকবে।',
        'Sign in to save your reading settings and progress across sessions.',
      );
  String get guestBlurbFull => _s(
        'অতিথি হিসেবে পড়লে সব কিছু শুধু এই ফোনেই থাকে — কিছুই পাঠানো হয় না '
            'এবং কোনো থেরাপিস্ট তা দেখতে পান না।',
        'Guest reading stays on this device only — nothing is uploaded and a '
            'therapist cannot see it.',
      );

  // ---- Final sweep --------------------------------------------------------

  String get sessionExpired => _s(
        'আপনার সেশন শেষ হয়ে গেছে। আবার সাইন ইন করুন।',
        'Your session expired. Please sign in again.',
      );
  String get researchTitleText => _s(
        'মানব-কেন্দ্রিক ডিজাইন নীতিতে ডিসলেক্সিয়া-বান্ধব বাংলা পড়ার ইন্টারফেস '
            'তৈরি ও মূল্যায়ন',
        'Design and Evaluation of a Dyslexia-Friendly Bangla Reading Interface '
            'Using Human-Centered Design Principles',
      );
  String get disclaimerBody => _s(
        'এই অ্যাপটি পড়ায় সহায়তা করার একটি সরঞ্জাম। এটি রোগ নির্ণয় বা '
            'চিকিৎসার যন্ত্র নয়, এবং যোগ্য পেশাদারের মূল্যায়ন বা শিক্ষার '
            'বিকল্প নয়।',
        'This application is a reading support tool. It is not a diagnostic or '
            'therapeutic instrument and does not replace assessment or '
            'instruction by qualified professionals.',
      );
  String get readerSignInHeading =>
      _s('পাঠক সাইন-ইন দেখানো', 'READER SIGN-IN DISPLAY');
  String get resetAllSettingsAction => _s('সব সেটিংস রিসেট করুন', 'Reset all settings');
  String get howToUseBody => _s(
        'পাঠাগার থেকে একটি গল্প বেছে নিন, তারপর পড়ার সময় সেটিংস বোতামে চাপ '
            'দিন। প্রথমে পড়ে শোনানো চালু করে দেখুন — এটিই সবচেয়ে বেশি কাজে '
            'লাগে। এরপর ফাঁক আর রং এমনভাবে ঠিক করুন যাতে পড়তে আরাম লাগে। '
            'আপনার পছন্দ জমা থাকবে।',
        'Pick a passage from the Library, then tap the settings button while '
            'reading. Start with Read Aloud — it helps most. Adjust spacing '
            'and theme until the text feels comfortable. Your choices are '
            'saved.',
      );
  String get contactPlaceholder => _s(
        'research-team@example.edu (অস্থায়ী ঠিকানা)',
        'research-team@example.edu (placeholder contact address)',
      );

  // Feedback screen: which settings helped. These name controls the reader
  // has just used, so they must match the settings panel word for word.
  String get settingReadAloud => _s('পড়ে শোনানো', 'Read aloud');
  String get settingConjunctHighlight =>
      _s('যুক্তাক্ষর চিহ্নিত করা', 'Conjunct highlight');
  String get settingLineSpacing => _s('লাইনের ফাঁক', 'Line spacing');
  String get settingCreamTheme => _s('ক্রিম রং', 'Cream theme');
  String get settingReadingRuler => _s('পড়ার রুলার', 'Reading ruler');

  // ---- NASA-TLX -----------------------------------------------------------

  /// The six TLX subscales. Like the SUS, the English is the published
  /// wording and the Bangla is a working translation the research team has
  /// not validated — report it as such.
  String get tlxMentalDemand => _s('মানসিক পরিশ্রম', 'Mental demand');
  String get tlxMentalDemandQ =>
      _s('কতটা ভাবতে হয়েছে?', 'How much thinking was required?');
  String get tlxPhysicalDemand => _s('শারীরিক পরিশ্রম', 'Physical demand');
  String get tlxPhysicalDemandQ => _s(
        'কাজটি শরীরের দিক থেকে কতটা কষ্টকর ছিল?',
        'How physically demanding was the task?',
      );
  String get tlxTemporalDemand => _s('সময়ের চাপ', 'Temporal demand');
  String get tlxTemporalDemandQ =>
      _s('কতটা তাড়াহুড়ো লেগেছে?', 'How hurried was the pace?');
  String get tlxPerformance => _s('সাফল্য', 'Performance');
  String get tlxPerformanceQ =>
      _s('আপনি কতটা ভালো পেরেছেন?', 'How successful were you?');
  String get tlxEffort => _s('চেষ্টা', 'Effort');
  String get tlxEffortQ =>
      _s('কতটা খাটতে হয়েছে?', 'How hard did you have to work?');
  String get tlxFrustration => _s('বিরক্তি', 'Frustration');
  String get tlxFrustrationQ => _s(
        'কতটা বিরক্ত বা চাপে ছিলেন?',
        'How irritated or stressed did you feel?',
      );

  // ---- Final leftovers ----------------------------------------------------

  String get therapistPasswordToUnlock => _s(
        'এই সেশনের বাকি সময় পাঠক যেন সেটিংস বদলাতে পারে, তার জন্য থেরাপিস্টের '
            'পাসওয়ার্ড দিন।',
        "Enter the therapist's password to let this reader change settings for "
            'the rest of the session.',
      );
  String get letterSpacingWarning => _s(
        'বাংলায় বেশি অক্ষর-ফাঁক মাত্রা ভেঙে দেয় — সাবধানে ব্যবহার করুন। '
            'বাংলার জন্য শব্দের ফাঁক নিরাপদ।',
        'Too much letter spacing breaks the মাত্রা in Bangla — use it '
            'carefully. Word spacing is safer for Bangla.',
      );
  String get profileDescDefaultLong => _s(
        'ডিফল্ট — কোনো সহায়তা ছাড়া মূল ইন্টারফেস, গবেষণার নিয়ন্ত্রণ শর্ত।',
        'Default — the baseline interface used as the control condition in '
            'the study.',
      );
  String get profileDescRecommendedLong => _s(
        'গবেষণা-ভিত্তিক সেটিংস: পড়ে শোনানো, বেশি লাইন-ফাঁক, ক্রিম পটভূমি, আর '
            'অক্ষর-ফাঁক নেই যাতে মাত্রা অটুট থাকে।',
        'Evidence-based settings: audio support, wide line spacing, cream '
            'background, and no letter spacing so the মাত্রা stays intact.',
      );
  String get profileDescCustomLong => _s(
        'নিজের মতো — পাঠকের নিজের সাজানো, ডিফল্ট ও সুপারিশকৃতর সাথে তুলনার '
            'জন্য সংরক্ষিত।',
        'Custom — the reader\u2019s own configuration, logged for comparison '
            'against Default and Recommended.',
      );
  String get clearAllDataBody => _s(
        'প্রতিটি অংশগ্রহণকারীর সব সেশন, সেটিংস বদলের হিসাব, কুইজের উত্তর, SUS '
            'ও NASA-TLX সব মুছে যাবে। এটি ফেরানো যাবে না — দরকার হলে আগে '
            'রপ্তানি করে নিন।',
        'Deletes every session, settings-change log, quiz answer, SUS response '
            'and NASA-TLX rating for every participant. This cannot be undone '
            '— export first if you need a copy.',
      );
  String get clearAllDataNote => _s(
        'দুই অংশগ্রহণকারীর মাঝে ব্যবহারের জন্য। তথ্য এখনও ফোন থেকে নেওয়া না '
            'হলে আগে রপ্তানি করুন।',
        'For use between participants. Export before clearing if the data has '
            'not been pulled off the device yet.',
      );

  // ---- Remaining screens --------------------------------------------------

  String get appTagline => _s(
        'ডিসলেক্সিয়া-বান্ধব বাংলা পড়ার অ্যাপ',
        'A dyslexia-friendly Bangla reading interface',
      );
  String get speedWithAccuracy => _s(
        'গতি সঠিকতার সাথে মিলিয়ে দেখতে হয়।',
        'Speed is read alongside accuracy.',
      );
  String get noQuizYet => _s('এখনও কোনো কুইজ হয়নি।', 'No quiz completed yet.');
  String get acrossAllQuizzes =>
      _s('সব কুইজ মিলিয়ে।', 'Across all quizzes taken.');
  String get readAloudPercentNote => _s(
        'যত শতাংশ পড়ায় পড়ে শোনানো চালু ছিল।',
        'Percentage of sessions where audio support was switched on.',
      );
  String get settingsChangedNote => _s(
        'এই পাঠক আসলে কোন সুবিধাগুলো ব্যবহার করেন — সেটিংস বদলের হিসাব থেকে।',
        'Which controls this reader actually reaches for, straight from the '
            'settings-change log.',
      );
  String noMatchBody(String query) => _s(
        '“$query” নামে যুক্ত হননি এমন কোনো পাঠক পাওয়া যায়নি। তিনি হয়তো '
            'ইতিমধ্যে অন্য কোনো থেরাপিস্টের তালিকায় আছেন।',
        'No unassigned reader matches “$query”. They may already be on '
            "another therapist's list.",
      );
  String get everyoneAddedBody => _s(
        'যারা সাইন আপ করেছেন সবাই ইতিমধ্যে কোনো থেরাপিস্টের সাথে আছেন। নতুন '
            'কেউ সাইন আপ করলে এখানে দেখা যাবে।',
        'Every reader who has signed up is already working with a therapist. '
            'New sign-ups will appear here.',
      );
  String get readingConditionHeading =>
      _s('পড়ার অবস্থা', 'READING CONDITION');
  String get conditionStandardNote =>
      _s('সাধারণ গঠন। সেটিংস বন্ধ।', 'Standard formatting. Settings locked.');
  String get conditionRecommendedNote => _s(
        'গবেষণা-ভিত্তিক সেটিংস। সেটিংস বন্ধ।',
        'Evidence-based settings. Settings locked.',
      );
  String get conditionCustomNote => _s(
        'পাঠক নিজের সেটিংস বেছে নেবেন।',
        'Reader chooses their own settings.',
      );
  String get dashboardMarkerNote => _s(
        'হলুদ আর ধূসর চিহ্ন সেই পাঠকদের বোঝায় যাদের সঠিকতা কমছে বা যারা এক '
            'সপ্তাহের বেশি পড়েননি।',
        'Amber and grey markers flag readers whose accuracy is falling or who '
            'have not read in over a week.',
      );
  String profileNamed(String profile) => _s('$profile ধরন', '$profile profile');
  String get needsTwoSessions =>
      _s('অন্তত দুইবার পড়া দরকার', 'Needs at least two sessions');
}

/// `context.t.startReading` at the call site.
extension AppStringsX on BuildContext {
  /// For use inside `build`. Watches the language, so switching it rebuilds
  /// the widget rather than leaving it in the language it was born in.
  AppStrings get t => AppStrings.of(this);

  /// For use outside `build` — button handlers, async callbacks, anywhere
  /// reached after the frame. Reading a watched value there throws
  /// ("Tried to listen to a value exposed with provider, from outside of the
  /// widget tree"), and nothing is being built to rebuild anyway.
  AppStrings get tOnce => AppStrings(read<LanguageState>().language);
}
