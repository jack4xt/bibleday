import 'package:shared_preferences/shared_preferences.dart';
import 'bible_service.dart';

enum ReadingPlanType { wholeBible, newTestament, custom }

class ReadingPlanService {
  static const String _keyPlanType = 'reading_plan_type';
  static const String _keyProgress = 'reading_plan_progress';
  static const String _keyStartDate = 'reading_plan_start_date';
  static const String _keyCustomBook = 'reading_plan_custom_book';
  static const String _keyCustomChaptersPerDay = 'reading_plan_custom_chapters';
  static const String _keyCompleted = 'reading_plan_completed';
  // Klíč pro uložení aktuální denní dávky (pevně dané, nemění se přes den)
  static const String _keyTodayBatch = 'reading_plan_today_batch';
  static const String _keyTodayBatchDate = 'reading_plan_today_batch_date';

  static const List<String> newTestamentBooks = [
    'Matthew', 'Mark', 'Luke', 'John', 'Acts', 'Romans',
    '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
    'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
    '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews',
    'James', '1 Peter', '2 Peter', '1 John', '2 John', '3 John',
    'Jude', 'Revelation',
  ];

  List<Map<String, dynamic>> _generateChapters(ReadingPlanType type, {String? customBook}) {
    List<Map<String, dynamic>> chapters = [];
    List<Map<String, dynamic>> books;

    if (type == ReadingPlanType.newTestament) {
      books = BibleService.books.where((b) => newTestamentBooks.contains(b['name'])).toList();
    } else if (type == ReadingPlanType.custom && customBook != null) {
      books = BibleService.books.where((b) => b['name'] == customBook).toList();
    } else {
      books = List.from(BibleService.books);
    }

    for (final book in books) {
      final chapCount = book['chapters'] as int;
      for (int i = 1; i <= chapCount; i++) {
        chapters.add({'book': book['name'], 'chapter': i});
      }
    }
    return chapters;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> startPlan(ReadingPlanType type, {String? customBook, int chaptersPerDay = 2}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlanType, type.name);
    await prefs.setString(_keyStartDate, DateTime.now().toIso8601String());
    await prefs.setInt(_keyProgress, 0);
    await prefs.setStringList(_keyCompleted, []);
    await prefs.setInt(_keyCustomChaptersPerDay, chaptersPerDay);
    await prefs.remove(_keyTodayBatch);
    await prefs.remove(_keyTodayBatchDate);
    if (customBook != null) {
      await prefs.setString(_keyCustomBook, customBook);
    }
  }

  Future<void> markChapterDone(String book, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_keyCompleted) ?? [];
    final key = '$book:$chapter';
    if (!completed.contains(key)) {
      completed.add(key);
      await prefs.setStringList(_keyCompleted, completed);
      await prefs.setInt(_keyProgress, completed.length);
    }
  }

  Future<bool> markChapterDoneIfInPlan(String book, int chapter) async {
    final today = await getTodayChapters();
    if (today == null || today['done'] == true) return false;

    final todaysChapters = (today['chapters'] as List).cast<Map<String, dynamic>>();
    final isInToday = todaysChapters.any((c) => c['book'] == book && c['chapter'] == chapter);
    if (!isInToday) return false;

    await markChapterDone(book, chapter);
    return true;
  }

  Future<bool> isChapterDone(String book, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_keyCompleted) ?? [];
    return completed.contains('$book:$chapter');
  }

  Future<ReadingPlanType?> getActivePlanType() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyPlanType);
    if (name == null) return null;
    return ReadingPlanType.values.firstWhere((e) => e.name == name);
  }

  Future<int> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyProgress) ?? 0;
  }

  Future<int> getChaptersPerDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCustomChaptersPerDay) ?? 2;
  }

  Future<String?> getCustomBook() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomBook);
  }

  Future<List<String>> getCompletedChapters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyCompleted) ?? [];
  }

  /// Vrací DNEŠNÍ dávku kapitol.
  ///
  /// Logika:
  /// 1. Dávka se uloží do prefs při prvním načtení dne a NEMĚNÍ se přes den.
  /// 2. Po půlnoci (nový den) se vygeneruje nová dávka z dalších nedokončených kapitol.
  /// 3. Dokud nejsou všechny kapitoly dávky dokončeny, zobrazují se stále stejné.
  /// 4. Pokud jsou všechny dokončeny, zobrazí se prázdný stav "vše splněno dnes".
  Future<Map<String, dynamic>?> getTodayChapters() async {
    final planType = await getActivePlanType();
    if (planType == null) return null;

    final customBook = await getCustomBook();
    final chaptersPerDay = await getChaptersPerDay();
    final completed = await getCompletedChapters();
    final allChapters = _generateChapters(planType, customBook: customBook);

    // Zkontroluj jestli je plán hotový úplně
    final remaining = allChapters.where((c) => !completed.contains('${c['book']}:${c['chapter']}')).toList();
    if (remaining.isEmpty) return {'done': true, 'chapters': [], 'total': allChapters.length, 'completed': completed.length};

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final savedDate = prefs.getString(_keyTodayBatchDate);
    final savedBatch = prefs.getStringList(_keyTodayBatch);

    List<Map<String, dynamic>> todayChapters;

    if (savedDate == todayKey && savedBatch != null && savedBatch.isNotEmpty) {
      // Použij uloženou dnešní dávku
      todayChapters = savedBatch.map((s) {
        final parts = s.split(':');
        return {'book': parts[0], 'chapter': int.parse(parts[1])};
      }).toList();
    } else {
      // Nový den — vygeneruj novou dávku z dalších nedokončených kapitol
      todayChapters = remaining.take(chaptersPerDay).toList();

      // Ulož dávku pro dnešek
      final batchEncoded = todayChapters.map((c) => '${c['book']}:${c['chapter']}').toList();
      await prefs.setStringList(_keyTodayBatch, batchEncoded);
      await prefs.setString(_keyTodayBatchDate, todayKey);
    }

    final doneInBatch = todayChapters.where((c) => completed.contains('${c['book']}:${c['chapter']}')).length;
    final allBatchDone = doneInBatch == todayChapters.length;

    return {
      'done': false,
      'allBatchDone': allBatchDone, // všechny dnešní kapitoly splněny
      'chapters': todayChapters,
      'total': allChapters.length,
      'completed': completed.length,
      'batchSize': todayChapters.length,
      'batchDone': doneInBatch,
    };
  }

  Future<void> resetPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPlanType);
    await prefs.remove(_keyProgress);
    await prefs.remove(_keyStartDate);
    await prefs.remove(_keyCompleted);
    await prefs.remove(_keyCustomBook);
    await prefs.remove(_keyCustomChaptersPerDay);
    await prefs.remove(_keyTodayBatch);
    await prefs.remove(_keyTodayBatchDate);
  }

  /// Vymaže dnešní uloženou dávku — při příštím načtení se vygeneruje nová.
  /// Použij když se kapitoly nezobrazí správně.
  Future<void> refreshTodayBatch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTodayBatch);
    await prefs.remove(_keyTodayBatchDate);
  }

  /// Přidá další dávku kapitol k dnešnímu čtení (dobrovolné čtení navíc).
  /// Nové kapitoly se přidají za stávající a zůstanou i příští den pokud nejsou přečteny.
  Future<void> loadNextBatch() async {
    final planType = await getActivePlanType();
    if (planType == null) return;

    final customBook = await getCustomBook();
    final chaptersPerDay = await getChaptersPerDay();
    final completed = await getCompletedChapters();
    final allChapters = _generateChapters(planType, customBook: customBook);
    final prefs = await SharedPreferences.getInstance();

    // Načti aktuální dávku
    final savedBatch = prefs.getStringList(_keyTodayBatch) ?? [];
    final currentBatchKeys = savedBatch.toSet();

    // Najdi kapitoly které ještě nejsou v dávce ani dokončené
    final remaining = allChapters.where((c) {
      final key = '${c['book']}:${c['chapter']}';
      return !completed.contains(key) && !currentBatchKeys.contains(key);
    }).toList();

    if (remaining.isEmpty) return;

    // Přidej další dávku
    final nextBatch = remaining.take(1).toList();
    final newBatch = [
      ...savedBatch,
      ...nextBatch.map((c) => '${c['book']}:${c['chapter']}'),
    ];

    await prefs.setStringList(_keyTodayBatch, newBatch);
    // Zachovej dnešní datum aby se dávka nezresetovala
    await prefs.setString(_keyTodayBatchDate, _todayKey());
  }

  int getTotalChapters(ReadingPlanType type, {String? customBook}) {
    return _generateChapters(type, customBook: customBook).length;
  }
}
