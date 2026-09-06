class Verse {
  final String reference;
  final String text;
  final String book;
  final int chapter;
  final int verseNumber;

  const Verse({
    required this.reference,
    required this.text,
    required this.book,
    required this.chapter,
    required this.verseNumber,
  });
}

class DailyContent {
  final Verse verse;
  final String? aiReflection;
  final String date;

  const DailyContent({
    required this.verse,
    this.aiReflection,
    required this.date,
  });
}

class BibleChapter {
  final String book;
  final int chapter;
  final List<String> verses;
  final String translation;

  const BibleChapter({
    required this.book,
    required this.chapter,
    required this.verses,
    required this.translation,
  });

  String get fullText => verses
      .asMap()
      .entries
      .map((e) => '${e.key + 1} ${e.value}')
      .join('\n');
}

class AIProvider {
  final String id;
  final String name;
  final String model;
  final String baseUrl;
  final String apiKeyHint;

  const AIProvider({
    required this.id,
    required this.name,
    required this.model,
    required this.baseUrl,
    required this.apiKeyHint,
  });

  static const List<AIProvider> available = [
    AIProvider(
      id: 'anthropic',
      name: 'Claude (Anthropic)',
      model: 'claude-haiku-4-5-20251001',
      baseUrl: 'https://api.anthropic.com/v1/messages',
      apiKeyHint: 'sk-ant-...',
    ),
  ];
}
