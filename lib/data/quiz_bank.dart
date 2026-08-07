import '../models/quiz_question.dart';

/// Comprehension questions per passage, keyed by [Passage.id].
///
/// SWAP THIS OUT alongside the passages in `data/passages.dart` — questions
/// have to stay matched to whichever story is actually being read.
abstract final class QuizBank {
  static const List<QuizQuestion> _bristirDineMitu = [
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'মিতু জানালার পাশে বসে কী দেখেছিল?',
      options: [
        'একটা ভেজা পাখি',
        'একটা রঙিন ছাতা',
        'একটা নৌকা',
        'একটা বই',
      ],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.trueFalse,
      prompt: 'পাখিটা প্রথমেই উড়ে পালিয়ে গিয়েছিল।',
      options: ['সত্য (True)', 'মিথ্যা (False)'],
      correctIndex: 1,
    ),
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'মিতু পাখিটাকে কী দিয়ে সাবধানে রাখল?',
      options: [
        'একটা শুকনো কাপড় ও বাক্স',
        'একটা কাচের বয়াম',
        'একটা কাগজের ঠোঙা',
        'একটা বালিশ',
      ],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.trueFalse,
      prompt: 'বিকেলের দিকে বৃষ্টি থামল।',
      options: ['সত্য (True)', 'মিথ্যা (False)'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'গল্পের শেষে পাখিটা কী করল?',
      options: [
        'আকাশে উড়ে গেল',
        'ঘরে থেকে গেল',
        'আবার ভিজে গেল',
        'ঘুমিয়ে পড়ল',
      ],
      correctIndex: 0,
    ),
  ];

  static const List<QuizQuestion> _amaderGram = [
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'আমাদের গ্রামের নাম কী?',
      options: ['শিমুলতলী', 'রায়পুর', 'নবীনগর', 'কাশিমপুর'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.trueFalse,
      prompt: 'গ্রামের বেশিরভাগ মানুষ কৃষক।',
      options: ['সত্য (True)', 'মিথ্যা (False)'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'জেলেরা নদী থেকে কী ধরেন?',
      options: ['মাছ', 'কাঠ', 'ফুল', 'পাথর'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.trueFalse,
      prompt: 'গ্রামে প্রতিদিন হাট বসে।',
      options: ['সত্য (True)', 'মিথ্যা (False)'],
      correctIndex: 1,
    ),
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'স্কুলের ছুটির পর ছেলেমেয়েরা কী করে?',
      options: ['খেলাধুলা করে', 'ঘুমিয়ে পড়ে', 'বাজারে যায়', 'মাছ ধরে'],
      correctIndex: 0,
    ),
  ];

  static const List<QuizQuestion> _nodirGolpo = [
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'রাজু আর তানভীর সন্ধ্যায় কার কাছে গল্প শুনতে যেত?',
      options: ['দাদুর কাছে', 'শিক্ষকের কাছে', 'করিমের কাছে', 'মায়ের কাছে'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.trueFalse,
      prompt: 'সেই বছর প্রবল বৃষ্টিতে নদীর জল ফুলেফেঁপে উঠেছিল।',
      options: ['সত্য (True)', 'মিথ্যা (False)'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'স্রোতে কোন প্রাণীটা ভেসে যাচ্ছিল?',
      options: ['একটা বাছুর', 'একটা ছাগল', 'একটা কুকুর', 'একটা মুরগি'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.trueFalse,
      prompt: 'করিম দড়ি ছাড়াই জলে ঝাঁপ দিয়েছিল।',
      options: ['সত্য (True)', 'মিথ্যা (False)'],
      correctIndex: 1,
    ),
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'দাদুর গল্পের শিক্ষা কী ছিল?',
      options: [
        'সাহস ও ঐক্য দিয়ে বিপদ জয় করা যায়',
        'নদীতে কখনো নামা উচিত নয়',
        'বৃষ্টি হলে ঘরে থাকা উচিত',
        'বাছুর পোষা উচিত নয়',
      ],
      correctIndex: 0,
    ),
  ];

  static const List<QuizQuestion> _ajkerKhobor = [
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'শিমুলতলীতে নতুন কী উদ্বোধন হয়েছে?',
      options: ['একটা সেতু', 'একটা হাসপাতাল', 'একটা বাজার', 'একটা মসজিদ'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.trueFalse,
      prompt: 'শিমুলতলী বিদ্যালয় জেলা কুইজ প্রতিযোগিতায় প্রথম হয়েছে।',
      options: ['সত্য (True)', 'মিথ্যা (False)'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'আবহাওয়া অধিদপ্তর কী পূর্বাভাস দিয়েছে?',
      options: ['ভারী বৃষ্টি', 'প্রচণ্ড গরম', 'ঘন কুয়াশা', 'ঝড়ো বাতাস'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.trueFalse,
      prompt: 'জেলা ফুটবল টুর্নামেন্টে শিমুলতলী একাদশ হেরে গেছে।',
      options: ['সত্য (True)', 'মিথ্যা (False)'],
      correctIndex: 1,
    ),
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'কৃষি কর্মকর্তারা কৃষকদের কী পরামর্শ দিয়েছেন?',
      options: [
        'পাকা ধান দ্রুত কেটে ফেলতে',
        'নতুন করে ধান বুনতে',
        'জমিতে সেচ বন্ধ করতে',
        'বাজারে ধান বিক্রি বন্ধ রাখতে',
      ],
      correctIndex: 0,
    ),
  ];

  static const List<QuizQuestion> _bigganOAmra = [
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'লেখা অনুযায়ী বিজ্ঞান কোথায় সীমাবদ্ধ নয়?',
      options: [
        'শুধু গবেষণাগার বা বইয়ে',
        'শুধু স্কুলে',
        'শুধু শহরে',
        'শুধু হাসপাতালে',
      ],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.trueFalse,
      prompt: 'জলচক্রে সূর্যের তাপে জল বাষ্পীভূত হয়ে আকাশে ওঠে।',
      options: ['সত্য (True)', 'মিথ্যা (False)'],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'কপিকল ব্যবহারের প্রধান সুবিধা কী?',
      options: [
        'অল্প শক্তিতে ভারী জিনিস তোলা যায়',
        'জল পরিষ্কার হয়',
        'বিদ্যুৎ সাশ্রয় হয়',
        'ফসল দ্রুত পাকে',
      ],
      correctIndex: 0,
    ),
    QuizQuestion(
      type: QuestionType.trueFalse,
      prompt: 'হাত ধোয়ার সঙ্গে জীবাণু ছড়ানো রোধের কোনো সম্পর্ক নেই।',
      options: ['সত্য (True)', 'মিথ্যা (False)'],
      correctIndex: 1,
    ),
    QuizQuestion(
      type: QuestionType.multipleChoice,
      prompt: 'লেখাটির শেষে বিজ্ঞান বলতে কী বোঝানো হয়েছে?',
      options: [
        'প্রশ্ন করা ও উত্তর যাচাই করার পদ্ধতি',
        'শুধু বিজ্ঞানীদের কাজ',
        'শুধু পরীক্ষার জন্য মুখস্থ করা তথ্য',
        'শুধু যন্ত্রপাতি তৈরির কৌশল',
      ],
      correctIndex: 0,
    ),
  ];

  static const Map<String, List<QuizQuestion>> _byPassageId = {
    'bristir_dine_mitu': _bristirDineMitu,
    'amader_gram': _amaderGram,
    'nodir_golpo': _nodirGolpo,
    'ajker_khobor': _ajkerKhobor,
    'biggan_o_amra': _bigganOAmra,
  };

  static List<QuizQuestion> forPassage(String passageId) =>
      _byPassageId[passageId] ?? const [];
}
