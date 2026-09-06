import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/verse.dart';
import '../screens/study/map_screen.dart';

class StudySection {
  final String title;
  final String content;
  final String icon;

  const StudySection({
    required this.title,
    required this.content,
    required this.icon,
  });
}

class StudyQuestion {
  final String question;
  final String answer;

  const StudyQuestion({required this.question, required this.answer});
}

class StructuredStudy {
  final String? context;
  final String? summary;
  final List<String>? keyVerses;
  final List<StudyQuestion>? questions;
  final String? application;

  const StructuredStudy({
    this.context,
    this.summary,
    this.keyVerses,
    this.questions,
    this.application,
  });
}

class AIService {
  final AIProvider provider;
  final String apiKey;

  AIService({required this.provider, required this.apiKey});

  Future<String?> getVerseReflection(Verse verse, String language) async {
    final lang = language == 'cs' ? 'češtině' : 'English';
    final prompt = language == 'cs'
        ? 'Napiš krátké duchovní zamyšlení (4-6 vět) k tomuto biblickému verši v $lang. Buď hluboký, osobní a povzbudivý. Piš prostý text bez nadpisů, bez hvězdiček, bez markdownu.\n\nVerš: ${verse.reference} - "${verse.text}"'
        : 'Write a short spiritual reflection (4-6 sentences) on this Bible verse in $lang. Be deep, personal and encouraging. Plain text only, no headings, no markdown.\n\nVerse: ${verse.reference} - "${verse.text}"';
    return _sendRequest(prompt);
  }

  Future<String?> getChapterSummary(BibleChapter chapter, String language) async {
    final lang = language == 'cs' ? 'češtině' : 'English';
    final prompt = language == 'cs'
        ? 'Napiš shrnutí a zamyšlení k této biblické kapitole v $lang. Piš prostý text bez nadpisů, bez hvězdiček, bez markdownu.\n\nKapitola: ${chapter.book} ${chapter.chapter}\n\n${chapter.fullText.substring(0, chapter.fullText.length.clamp(0, 3000))}'
        : 'Write a summary and reflection on this Bible chapter in $lang. Plain text only, no headings, no markdown.\n\nChapter: ${chapter.book} ${chapter.chapter}\n\n${chapter.fullText.substring(0, chapter.fullText.length.clamp(0, 3000))}';
    return _sendRequest(prompt);
  }

  Future<StructuredStudy?> getStructuredStudy(BibleChapter chapter, String language) async {
    final isCs = language == 'cs';
    final chapterText = chapter.fullText.substring(0, chapter.fullText.length.clamp(0, 4000));

    final prompt = isCs
        ? '''Analyzuj tuto biblickou kapitolu a vytvoř strukturované studium. Odpověz POUZE validním JSON objektem bez jakéhokoliv textu před nebo za ním.

Pravidla:
- Piš česky, prostý text bez markdownu a bez hvězdiček
- Shrnutí rozděl na části podle toku kapitoly (např. "v. 1-4: Popis soudu. v. 5-9: Hospodinův den.")
- Klíčové verše: maximálně 1-2 nejdůležitější
- Otázky: 2-3 otázky, každá s odpovědí
- Aplikaci vynech pokud přirozeně nevyplývá z textu

JSON struktura:
{
  "context": "Historické a literární pozadí (2-3 věty). Kdo psal, komu, v jaké situaci. Nebo null.",
  "summary": "Shrnutí kapitoly po částech. Popiš co se děje v každé části. Uveď čísla veršů.",
  "keyVerses": ["číslo verše: text verše"],
  "questions": [
    {"question": "Otázka k zamyšlení?", "answer": "Odpověď (2-4 věty)."}
  ],
  "application": "Praktická aplikace pro dnešní život. Nebo null."
}

Kapitola: ${chapter.book} ${chapter.chapter}

$chapterText'''
        : '''Analyze this Bible chapter and create a structured study. Respond ONLY with a valid JSON object, no text before or after.

Rules:
- Plain text, no markdown, no asterisks
- Summary: divide by sections with verse numbers
- Key verses: maximum 1-2 most important
- Questions: 2-3 questions each with answer
- Skip application if it doesn't naturally flow from the text

JSON structure:
{
  "context": "Historical and literary background (2-3 sentences). Or null.",
  "summary": "Chapter summary by sections with verse numbers.",
  "keyVerses": ["verse number: verse text"],
  "questions": [
    {"question": "Reflection question?", "answer": "Answer (2-4 sentences)."}
  ],
  "application": "Practical application for today. Or null."
}

Chapter: ${chapter.book} ${chapter.chapter}

$chapterText''';

    try {
      final result = await _sendRequestRaw(prompt, maxTokens: 3000);
      if (result == null) return null;

      String cleaned = result.trim();
      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
      }

      final data = jsonDecode(cleaned);

      List<StudyQuestion>? questions;
      if (data['questions'] != null) {
        questions = (data['questions'] as List).map((q) => StudyQuestion(
          question: q['question'] as String? ?? '',
          answer: q['answer'] as String? ?? '',
        )).toList();
      }

      return StructuredStudy(
        context: data['context'] as String?,
        summary: data['summary'] as String?,
        keyVerses: data['keyVerses'] != null
            ? List<String>.from(data['keyVerses'])
            : null,
        questions: questions,
        application: data['application'] as String?,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> getImagePrompt(Verse verse) async {
    final prompt =
        'Create a short image generation prompt (max 20 words) for a beautiful, spiritual, artistic illustration based on this Bible verse. Style: dramatic lighting, painterly, sacred art. No text, no markdown, no headings, just the prompt.\n\nVerse: ${verse.reference} - "${verse.text}"';
    return _sendRequest(prompt);
  }

  Future<String?> prayerRequest(String prompt) async {
    return _sendRequest(prompt);
  }

  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .replaceAll(RegExp(r'__(.*?)__'), r'$1')
        .replaceAll(RegExp(r'_(.*?)_'), r'$1')
        .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<String?> _sendRequest(String prompt) async {
    try {
      String? result;
      switch (provider.id) {
        case 'anthropic':
          result = await _sendAnthropic(prompt);
          break;
        case 'openai':
          result = await _sendOpenAI(prompt);
          break;
        case 'gemini':
          result = await _sendGemini(prompt);
          break;
        default:
          return null;
      }
      return result != null ? _cleanMarkdown(result) : null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _sendRequestRaw(String prompt, {int maxTokens = 1024}) async {
    try {
      switch (provider.id) {
        case 'anthropic':
          return await _sendAnthropicRaw(prompt, maxTokens: maxTokens);
        case 'openai':
          return await _sendOpenAIRaw(prompt, maxTokens: maxTokens);
        case 'gemini':
          return await _sendGeminiRaw(prompt);
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> _sendAnthropic(String prompt) async {
    return _sendAnthropicRaw(prompt);
  }

  Future<String?> _sendAnthropicRaw(String prompt, {int maxTokens = 1024}) async {
    final response = await http.post(
      Uri.parse(provider.baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': provider.model,
        'max_tokens': maxTokens,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'];
    }
    return null;
  }

  Future<String?> _sendOpenAI(String prompt) async {
    return _sendOpenAIRaw(prompt);
  }

  Future<String?> _sendOpenAIRaw(String prompt, {int maxTokens = 1024}) async {
    final response = await http.post(
      Uri.parse(provider.baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': provider.model,
        'max_tokens': maxTokens,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    }
    return null;
  }

  Future<String?> _sendGemini(String prompt) async {
    return _sendGeminiRaw(prompt);
  }

  Future<String?> _sendGeminiRaw(String prompt) async {
    final url = '${provider.baseUrl}/${provider.model}:generateContent?key=$apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    }
    return null;
  }

  Future<BibleLocation?> getBibleLocation(String book, int chapter) async {
    final prompt = 'What is the primary geographical location for the Bible book "$book" chapter $chapter? Respond ONLY with a JSON object: {"name": "City/Region name", "description": "Brief description (1 sentence)", "lat": 0.0, "lng": 0.0}. Use decimal coordinates. No other text.';
    try {
      final result = await _sendRequestRaw(prompt, maxTokens: 200);
      if (result == null) return null;
      String cleaned = result.trim();
      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
      }
      final data = jsonDecode(cleaned);
      return BibleLocation(
        name: data['name'] as String,
        description: data['description'] as String,
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> askAssistant({
    required String question,
    required String systemPrompt,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse(provider.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': provider.model,
          'max_tokens': 1024,
          'system': systemPrompt,
          'messages': [
            ...history.map((m) => {'role': m['role'], 'content': m['content']}),
            {'role': 'user', 'content': question},
          ],
        }),
      ).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> validateKey() async {
    try {
      final result = await _sendRequest('Reply with one word: OK');
      return result != null && result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
