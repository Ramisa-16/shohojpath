import '../models/passage.dart';

/// Sample study material.
///
/// The mockup shipped one paragraph of placeholder text; this is a complete
/// children's story so the renderer can be judged on real running text —
/// wrapping, line spacing and the reading ruler all behave differently across
/// six pages than they do across four sentences.
///
/// It is deliberately dense in যুক্তাক্ষর of different shapes: fully fused
/// stacks (ক্ষ, ষ্ট, ন্দ, ন্ধ, জ্ঞ), doubled consonants (ট্ট, ন্ন), ya-phala
/// (দ্য, ধ্য, ক্ষ্য) and ra-phala (দ্র, ক্র) — the four categories that behave
/// differently under ZWNJ splitting.
///
/// SWAP THIS OUT before the real study: replace with your own passages at
/// matched difficulty and conjunct density, and keep [Passage.wordCount] and
/// [Passage.distinctConjuncts] comparable across conditions.
abstract final class Passages {
  static const Passage bristirDineMitu = Passage(
    id: 'bristir_dine_mitu',
    title: 'বৃষ্টির দিনে মিতু',
    category: 'Children Stories',
    difficulty: PassageDifficulty.easy,
    estimatedMinutes: 3,
    pages: [
      PassagePage([
        'একদিন সকালে ছোট্ট মেয়ে মিতু জানালার পাশে বসে ছিল। বাইরে ঝিরিঝিরি '
            'বৃষ্টি পড়ছিল। গাছের পাতাগুলো বৃষ্টির জলে ধুয়ে ঝকঝক করছিল।',
        'হঠাৎ মিতু দেখল, একটা ছোট পাখি ভিজে গিয়ে বারান্দার কোণে বসে আছে। '
            'পাখিটা একটুও নড়ছে না।',
      ]),
      PassagePage([
        'পাখিটার ডানা দুটো ভিজে ভারী হয়ে গেছে। সে উড়তে পারছে না। মিতুর খুব '
            'মায়া হলো।',
        'সে ধীরে ধীরে বারান্দায় গেল, যাতে পাখিটা ভয় না পায়। প্রতিটা পা ফেলার '
            'আগে সে এক মুহূর্ত থামল।',
      ]),
      PassagePage([
        'ভয় পেয়ো না, মিতু নরম গলায় বলল। আমি তোমার কোনো ক্ষতি করব না।',
        'পাখিটা মাথা তুলে তাকাল। তার চোখ দুটো ছোট্ট কালো পুঁতির মতো চকচক '
            'করছিল। মিতু বুঝল, পাখিটা আর ভয় পাচ্ছে না।',
      ]),
      PassagePage([
        'মিতু ঘর থেকে একটা শুকনো কাপড় আর একটা ছোট বাক্স নিয়ে এল। বাক্সের '
            'ভিতরে কাপড়টা বিছিয়ে সে পাখিটাকে সাবধানে তুলে রাখল।',
        'তারপর রান্নাঘর থেকে কয়েকটা ভাতের দানা এনে সামনে ছড়িয়ে দিল। পাখিটা '
            'প্রথমে চুপ করে তাকিয়ে রইল, তারপর ঠোঁট দিয়ে একটা দানা তুলে নিল।',
      ]),
      PassagePage([
        'বিকেলের দিকে বৃষ্টি থামল। মেঘ সরে গিয়ে আকাশে হালকা রোদ উঠল। বারান্দার '
            'মেঝেতে রোদের একটা লম্বা দাগ পড়ল।',
        'হঠাৎ বিদ্যুতের ঝিলিকের মতো দ্রুত পাখিটা ডানা ঝাপটাল। তার পালক ততক্ষণে '
            'শুকিয়ে গেছে।',
      ]),
      PassagePage([
        'মিতু বাক্সটা খুলে দিল। পাখিটা এক লাফে বারান্দার রেলিংয়ে উঠল, তারপর '
            'আকাশের দিকে উড়ে গেল। মিতু হাত নাড়ল। তার লক্ষ্য ছিল একটাই — '
            'পাখিটা যেন ভালো থাকে।',
        'সন্ধ্যায় মা জিজ্ঞেস করলেন, আজ সারাদিন কী করলি? মিতু হেসে বলল, আজ আমি '
            'একটা নতুন বন্ধু বানিয়েছি।',
      ]),
    ],
  );

  static const List<Passage> all = [bristirDineMitu];
}
