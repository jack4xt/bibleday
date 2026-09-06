import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Služba pro lokální SQLite databázi Bible.
/// ČSP je bundled v assets — vždy dostupný offline.
class BibleDatabaseService {
  static BibleDatabaseService? _instance;
  static Database? _db;

  BibleDatabaseService._();

  static BibleDatabaseService get instance {
    _instance ??= BibleDatabaseService._();
    return _instance!;
  }

  Future<Database> get db async {
    _db ??= await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final path = join(await getDatabasesPath(), 'bible_v3.db');
    return openDatabase(
      path,
      version: 3,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Smaž staré tabulky a vytvoř nové
        await db.execute('DROP TABLE IF EXISTS verses');
        await db.execute('DROP TABLE IF EXISTS translations');
        await db.execute('''
          CREATE TABLE translations (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            lang TEXT NOT NULL,
            is_bundled INTEGER NOT NULL DEFAULT 0,
            is_downloaded INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE verses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            translation_id TEXT NOT NULL,
            book_code TEXT NOT NULL,
            book_name_cs TEXT NOT NULL,
            book_name_en TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            text TEXT NOT NULL,
            UNIQUE(translation_id, book_code, chapter, verse)
          )
        ''');
        await db.execute('CREATE INDEX idx_verses_lookup ON verses(translation_id, book_code, chapter, verse)');
        await db.execute('CREATE INDEX idx_verses_search ON verses(translation_id, text)');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE translations (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            lang TEXT NOT NULL,
            is_bundled INTEGER NOT NULL DEFAULT 0,
            is_downloaded INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE verses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            translation_id TEXT NOT NULL,
            book_code TEXT NOT NULL,
            book_name_cs TEXT NOT NULL,
            book_name_en TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            text TEXT NOT NULL,
            UNIQUE(translation_id, book_code, chapter, verse)
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_verses_lookup
          ON verses(translation_id, book_code, chapter, verse)
        ''');
        await db.execute('''
          CREATE INDEX idx_verses_search
          ON verses(translation_id, text)
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTranslations() async {
    final database = await db;
    return database.query('translations');
  }

  Future<bool> isTranslationAvailable(String translationId) async {
    final database = await db;
    final result = await database.query(
      'translations',
      where: 'id = ? AND (is_bundled = 1 OR is_downloaded = 1)',
      whereArgs: [translationId],
    );
    return result.isNotEmpty;
  }

  Future<List<String>> getChapter(
      String translationId, String bookCode, int chapter) async {
    final database = await db;
    final rows = await database.query(
      'verses',
      where: 'translation_id = ? AND book_code = ? AND chapter = ?',
      whereArgs: [translationId, bookCode, chapter],
      orderBy: 'verse ASC',
    );
    return rows.map((r) => r['text'] as String).toList();
  }

  /// Načte konkrétní verš podle čísla
  Future<String?> getVerse(
      String translationId, String bookCode, int chapter, int verse) async {
    final database = await db;
    final rows = await database.query(
      'verses',
      where: 'translation_id = ? AND book_code = ? AND chapter = ? AND verse = ?',
      whereArgs: [translationId, bookCode, chapter, verse],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['text'] as String;
  }

  Future<List<Map<String, dynamic>>> searchVerses(
      String translationId, String query,
      {int limit = 30}) async {
    final database = await db;
    final q = '%${query.toLowerCase()}%';
    return database.rawQuery('''
      SELECT book_name_cs, book_name_en, chapter, verse, text
      FROM verses
      WHERE translation_id = ? AND LOWER(text) LIKE ?
      LIMIT ?
    ''', [translationId, q, limit]);
  }

  /// Importuje ČSP z assets. Volá se při prvním spuštění appky.
  /// Parsuje všech 66 SFM souborů a uloží do SQLite.
  Future<void> importCspFromAssets({void Function(int, int)? onProgress}) async {
    final database = await db;

    // Zkontroluj jestli ČSP už je importován
    final existing = await database.query('translations',
        where: 'id = ?', whereArgs: ['csp']);
    if (existing.isNotEmpty) return;

    // Přidej metadata
    await database.insert('translations', {
      'id': 'csp',
      'name': 'Český studijní překlad (ČSP)',
      'lang': 'cs',
      'is_bundled': 1,
      'is_downloaded': 0,
    });

    int processed = 0;
    for (final book in _sfmBookFiles) {
      try {
        final assetPath = 'assets/bible/csp/${book['file']}';
        final content = await rootBundle.loadString(assetPath);
        final verses = SfmParser.parse(
          content,
          bookCode: book['code']!,
          bookNameCs: book['cs']!,
          bookNameEn: book['en']!,
        );

        final batch = database.batch();
        for (final verse in verses) {
          batch.insert('verses', {
            'translation_id': 'csp',
            'book_code': verse.bookCode,
            'book_name_cs': verse.bookNameCs,
            'book_name_en': verse.bookNameEn,
            'chapter': verse.chapter,
            'verse': verse.verse,
            'text': verse.text,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
        processed++;
        onProgress?.call(processed, _sfmBookFiles.length);
      } catch (e) {
        // Přeskoč chybějící soubor
      }
    }
  }

  Future<void> deleteTranslation(String translationId) async {
    final database = await db;
    final result = await database.query('translations',
        where: 'id = ? AND is_bundled = 0', whereArgs: [translationId]);
    if (result.isEmpty) return;
    await database.delete('verses',
        where: 'translation_id = ?', whereArgs: [translationId]);
    await database.delete('translations',
        where: 'id = ?', whereArgs: [translationId]);
  }

  // Mapování SFM souborů — přesné názvy z KMS
  static const List<Map<String, String>> _sfmBookFiles = [
    {'file': '01GENCSTwn.SFM', 'code': 'Genesis', 'cs': 'Genesis', 'en': 'Genesis'},
    {'file': '02EXOCSTwn.SFM', 'code': 'Exodus', 'cs': 'Exodus', 'en': 'Exodus'},
    {'file': '03LEVCSTwn.SFM', 'code': 'Leviticus', 'cs': 'Leviticus', 'en': 'Leviticus'},
    {'file': '04NUMCSTwn.SFM', 'code': 'Numbers', 'cs': 'Numeri', 'en': 'Numbers'},
    {'file': '05DEUCSTwn.SFM', 'code': 'Deuteronomy', 'cs': 'Deuteronomium', 'en': 'Deuteronomy'},
    {'file': '06JOSCSTwn.SFM', 'code': 'Joshua', 'cs': 'Jozue', 'en': 'Joshua'},
    {'file': '07JDGCSTwn.SFM', 'code': 'Judges', 'cs': 'Soudců', 'en': 'Judges'},
    {'file': '08RUTCSTwn.SFM', 'code': 'Ruth', 'cs': 'Rút', 'en': 'Ruth'},
    {'file': '091SACSTwn.SFM', 'code': '1 Samuel', 'cs': '1. Samuelova', 'en': '1 Samuel'},
    {'file': '102SACSTwn.SFM', 'code': '2 Samuel', 'cs': '2. Samuelova', 'en': '2 Samuel'},
    {'file': '111KICSTwn.SFM', 'code': '1 Kings', 'cs': '1. Královská', 'en': '1 Kings'},
    {'file': '122KICSTwn.SFM', 'code': '2 Kings', 'cs': '2. Královská', 'en': '2 Kings'},
    {'file': '131CHCSTwn.SFM', 'code': '1 Chronicles', 'cs': '1. Paralipomenon', 'en': '1 Chronicles'},
    {'file': '142CHCSTwn.SFM', 'code': '2 Chronicles', 'cs': '2. Paralipomenon', 'en': '2 Chronicles'},
    {'file': '15EZRCSTwn.SFM', 'code': 'Ezra', 'cs': 'Ezdráš', 'en': 'Ezra'},
    {'file': '16NEHCSTwn.SFM', 'code': 'Nehemiah', 'cs': 'Nehemiáš', 'en': 'Nehemiah'},
    {'file': '17ESTCSTwn.SFM', 'code': 'Esther', 'cs': 'Ester', 'en': 'Esther'},
    {'file': '18JOBCSTwn.SFM', 'code': 'Job', 'cs': 'Job', 'en': 'Job'},
    {'file': '19PSACSTwn.SFM', 'code': 'Psalms', 'cs': 'Žalmy', 'en': 'Psalms'},
    {'file': '20PROCSTwn.SFM', 'code': 'Proverbs', 'cs': 'Přísloví', 'en': 'Proverbs'},
    {'file': '21ECCCSTwn.SFM', 'code': 'Ecclesiastes', 'cs': 'Kazatel', 'en': 'Ecclesiastes'},
    {'file': '22SNGCSTwn.SFM', 'code': 'Song of Solomon', 'cs': 'Píseň písní', 'en': 'Song of Solomon'},
    {'file': '23ISACSTwn.SFM', 'code': 'Isaiah', 'cs': 'Izajáš', 'en': 'Isaiah'},
    {'file': '24JERCSTwn.SFM', 'code': 'Jeremiah', 'cs': 'Jeremjáš', 'en': 'Jeremiah'},
    {'file': '25LAMCSTwn.SFM', 'code': 'Lamentations', 'cs': 'Pláč Jeremjášův', 'en': 'Lamentations'},
    {'file': '26EZKCSTwn.SFM', 'code': 'Ezekiel', 'cs': 'Ezechiel', 'en': 'Ezekiel'},
    {'file': '27DANCSTwn.SFM', 'code': 'Daniel', 'cs': 'Daniel', 'en': 'Daniel'},
    {'file': '28HOSCSTwn.SFM', 'code': 'Hosea', 'cs': 'Ozeáš', 'en': 'Hosea'},
    {'file': '29JOLCSTwn.SFM', 'code': 'Joel', 'cs': 'Joel', 'en': 'Joel'},
    {'file': '30AMOCSTwn.SFM', 'code': 'Amos', 'cs': 'Ámos', 'en': 'Amos'},
    {'file': '31OBACSTwn.SFM', 'code': 'Obadiah', 'cs': 'Abdiáš', 'en': 'Obadiah'},
    {'file': '32JONCSTwn.SFM', 'code': 'Jonah', 'cs': 'Jonáš', 'en': 'Jonah'},
    {'file': '33MICCSTwn.SFM', 'code': 'Micah', 'cs': 'Micheáš', 'en': 'Micah'},
    {'file': '34NAMCSTwn.SFM', 'code': 'Nahum', 'cs': 'Nahum', 'en': 'Nahum'},
    {'file': '35HABCSTwn.SFM', 'code': 'Habakkuk', 'cs': 'Abakuk', 'en': 'Habakkuk'},
    {'file': '36ZEPCSTwn.SFM', 'code': 'Zephaniah', 'cs': 'Sofoniáš', 'en': 'Zephaniah'},
    {'file': '37HAGCSTwn.SFM', 'code': 'Haggai', 'cs': 'Aggeus', 'en': 'Haggai'},
    {'file': '38ZECCSTwn.SFM', 'code': 'Zechariah', 'cs': 'Zachariáš', 'en': 'Zechariah'},
    {'file': '39MALCSTwn.SFM', 'code': 'Malachi', 'cs': 'Malachiáš', 'en': 'Malachi'},
    {'file': '41MATCSTwn.SFM', 'code': 'Matthew', 'cs': 'Matouš', 'en': 'Matthew'},
    {'file': '42MRKCSTwn.SFM', 'code': 'Mark', 'cs': 'Marek', 'en': 'Mark'},
    {'file': '43LUKCSTwn.SFM', 'code': 'Luke', 'cs': 'Lukáš', 'en': 'Luke'},
    {'file': '44JHNCSTwn.SFM', 'code': 'John', 'cs': 'Jan', 'en': 'John'},
    {'file': '45ACTCSTwn.SFM', 'code': 'Acts', 'cs': 'Skutky', 'en': 'Acts'},
    {'file': '46ROMCSTwn.SFM', 'code': 'Romans', 'cs': 'Římanům', 'en': 'Romans'},
    {'file': '471COCSTwn.SFM', 'code': '1 Corinthians', 'cs': '1. Korintským', 'en': '1 Corinthians'},
    {'file': '482COCSTwn.SFM', 'code': '2 Corinthians', 'cs': '2. Korintským', 'en': '2 Corinthians'},
    {'file': '49GALCSTwn.SFM', 'code': 'Galatians', 'cs': 'Galatským', 'en': 'Galatians'},
    {'file': '50EPHCSTwn.SFM', 'code': 'Ephesians', 'cs': 'Efezským', 'en': 'Ephesians'},
    {'file': '51PHPCSTwn.SFM', 'code': 'Philippians', 'cs': 'Filipským', 'en': 'Philippians'},
    {'file': '52COLCSTwn.SFM', 'code': 'Colossians', 'cs': 'Koloským', 'en': 'Colossians'},
    {'file': '531THCSTwn.SFM', 'code': '1 Thessalonians', 'cs': '1. Tesalonickým', 'en': '1 Thessalonians'},
    {'file': '542THCSTwn.SFM', 'code': '2 Thessalonians', 'cs': '2. Tesalonickým', 'en': '2 Thessalonians'},
    {'file': '551TICSTwn.SFM', 'code': '1 Timothy', 'cs': '1. Timoteovi', 'en': '1 Timothy'},
    {'file': '562TICSTwn.SFM', 'code': '2 Timothy', 'cs': '2. Timoteovi', 'en': '2 Timothy'},
    {'file': '57TITCSTwn.SFM', 'code': 'Titus', 'cs': 'Titovi', 'en': 'Titus'},
    {'file': '58PHMCSTwn.SFM', 'code': 'Philemon', 'cs': 'Filemonovi', 'en': 'Philemon'},
    {'file': '59HEBCSTwn.SFM', 'code': 'Hebrews', 'cs': 'Hebrejům', 'en': 'Hebrews'},
    {'file': '60JASCSTwn.SFM', 'code': 'James', 'cs': 'Jakub', 'en': 'James'},
    {'file': '611PECSTwn.SFM', 'code': '1 Peter', 'cs': '1. Petra', 'en': '1 Peter'},
    {'file': '622PECSTwn.SFM', 'code': '2 Peter', 'cs': '2. Petra', 'en': '2 Peter'},
    {'file': '631JNCSTwn.SFM', 'code': '1 John', 'cs': '1. Jan', 'en': '1 John'},
    {'file': '642JNCSTwn.SFM', 'code': '2 John', 'cs': '2. Jan', 'en': '2 John'},
    {'file': '653JNCSTwn.SFM', 'code': '3 John', 'cs': '3. Jan', 'en': '3 John'},
    {'file': '66JUDCSTwn.SFM', 'code': 'Jude', 'cs': 'Juda', 'en': 'Jude'},
    {'file': '67REVCSTwn.SFM', 'code': 'Revelation', 'cs': 'Zjevení', 'en': 'Revelation'},
  ];
}

class ParsedVerse {
  final String bookCode;
  final String bookNameCs;
  final String bookNameEn;
  final int chapter;
  final int verse;
  final String text;

  const ParsedVerse({
    required this.bookCode,
    required this.bookNameCs,
    required this.bookNameEn,
    required this.chapter,
    required this.verse,
    required this.text,
  });
}

class SfmParser {
  static List<ParsedVerse> parse(
    String content, {
    required String bookCode,
    required String bookNameCs,
    required String bookNameEn,
  }) {
    final verses = <ParsedVerse>[];
    int currentChapter = 0;
    int currentVerse = 0;
    final verseBuffer = StringBuffer();

    void flushVerse() {
      if (currentChapter > 0 && currentVerse > 0) {
        final text = _cleanText(verseBuffer.toString());
        if (text.isNotEmpty) {
          verses.add(ParsedVerse(
            bookCode: bookCode,
            bookNameCs: bookNameCs,
            bookNameEn: bookNameEn,
            chapter: currentChapter,
            verse: currentVerse,
            text: text,
          ));
        }
        verseBuffer.clear();
      }
    }

    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith(r'\c ')) {
        flushVerse();
        final parts = trimmed.split(' ');
        if (parts.length >= 2) {
          currentChapter = int.tryParse(parts[1]) ?? currentChapter;
          currentVerse = 0;
        }
      } else if (trimmed.startsWith(r'\v ')) {
        flushVerse();
        final match = RegExp(r'^\\v\s+(\d+)\s*(.*)$').firstMatch(trimmed);
        if (match != null) {
          currentVerse = int.tryParse(match.group(1)!) ?? 0;
          verseBuffer.write(match.group(2) ?? '');
        }
      } else if (currentVerse > 0 &&
          !trimmed.startsWith(r'\s') &&
          !trimmed.startsWith(r'\p') &&
          !trimmed.startsWith(r'\q') &&
          !trimmed.startsWith(r'\m') &&
          !trimmed.startsWith(r'\id') &&
          !trimmed.startsWith(r'\h') &&
          !trimmed.startsWith(r'\mt') &&
          !trimmed.startsWith(r'\toc')) {
        if (verseBuffer.isNotEmpty) verseBuffer.write(' ');
        verseBuffer.write(trimmed);
      }
    }
    flushVerse();
    return verses;
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\\it\*?'), '')
        .replaceAll(RegExp(r'\\bd\*?'), '')
        .replaceAll(RegExp(r'\\bdit\*?'), '')
        .replaceAll(RegExp(r'\\nd\*?'), '')
        .replaceAll(RegExp(r'\\sc\*?'), '')
        .replaceAll(RegExp(r'\\add\*?'), '')
        .replaceAll(RegExp(r'\\wj\*?'), '')
        .replaceAll(RegExp(r'\\[a-z]+\d?\*?'), '')
        .replaceAll('~', '\u00A0')
        .replaceAll(RegExp(r'  +'), ' ')
        .trim();
  }
}
