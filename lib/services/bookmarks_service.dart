import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse.dart';

class BookmarkGroup {
  final String book;
  final int chapter;
  final List<int> verseNumbers;
  final List<String> texts;
  final String reference;

  const BookmarkGroup({
    required this.book,
    required this.chapter,
    required this.verseNumbers,
    required this.texts,
    required this.reference,
  });

  String get fullText => texts.join(' ');

  // Serializace do stringu pro uložení
  String serialize() {
    final versesPart = verseNumbers.join(',');
    final textsPart = texts.map((t) => t.replaceAll('|', '‖')).join('|');
    return '$book::$chapter::$versesPart::$textsPart';
  }

  static BookmarkGroup? deserialize(String raw) {
    try {
      final parts = raw.split('::');
      if (parts.length < 4) return null;
      final book = parts[0];
      final chapter = int.parse(parts[1]);
      final verseNumbers = parts[2].split(',').map(int.parse).toList();
      final texts = parts[3].split('|').map((t) => t.replaceAll('‖', '|')).toList();

      String ref;
      if (verseNumbers.length == 1) {
        ref = '$book $chapter:${verseNumbers.first}';
      } else {
        ref = '$book $chapter:${verseNumbers.first}-${verseNumbers.last}';
      }

      return BookmarkGroup(
        book: book,
        chapter: chapter,
        verseNumbers: verseNumbers,
        texts: texts,
        reference: ref,
      );
    } catch (_) {
      return null;
    }
  }
}

class BookmarksService {
  static const String _key = 'bookmarks_v2';
  static const String _keyLegacy = 'bookmarks';

  Future<List<BookmarkGroup>> getBookmarkGroups() async {
    final prefs = await SharedPreferences.getInstance();

    // Načti nový formát
    final v2 = prefs.getStringList(_key);
    if (v2 != null) {
      return v2
          .map(BookmarkGroup.deserialize)
          .whereType<BookmarkGroup>()
          .toList();
    }

    // Migruj starý formát
    final legacy = prefs.getStringList(_keyLegacy) ?? [];
    if (legacy.isNotEmpty) {
      final groups = <BookmarkGroup>[];
      for (final raw in legacy) {
        final parts = raw.split('|||');
        if (parts.length >= 4) {
          final book = parts[0];
          final chapter = int.tryParse(parts[1]) ?? 1;
          final verseNum = int.tryParse(parts[2]) ?? 1;
          final text = parts[3];
          groups.add(BookmarkGroup(
            book: book,
            chapter: chapter,
            verseNumbers: [verseNum],
            texts: [text],
            reference: '$book $chapter:$verseNum',
          ));
        }
      }
      // Ulož v novém formátu
      await prefs.setStringList(_key, groups.map((g) => g.serialize()).toList());
      return groups;
    }

    return [];
  }

  Future<void> _saveGroups(List<BookmarkGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, groups.map((g) => g.serialize()).toList());
  }

  /// Přidá verš do záložek.
  /// Pokud existuje záložka ze stejné kapitoly a poslední verš je přímo předchůdce,
  /// přidá verš do té záložky (skupinová záložka).
  Future<void> addBookmark(Verse verse) async {
    final groups = await getBookmarkGroups();

    // Hledej existující skupinu ze stejné knihy a kapitoly kde poslední verš je verse.verseNumber - 1
    final idx = groups.indexWhere((g) =>
        g.book == verse.book &&
        g.chapter == verse.chapter &&
        g.verseNumbers.last == verse.verseNumber - 1);

    if (idx != -1) {
      // Přidej do existující skupiny
      final old = groups[idx];
      final newVerseNumbers = [...old.verseNumbers, verse.verseNumber];
      final newTexts = [...old.texts, verse.text];
      final newRef = '${old.book} ${old.chapter}:${newVerseNumbers.first}-${newVerseNumbers.last}';
      groups[idx] = BookmarkGroup(
        book: old.book,
        chapter: old.chapter,
        verseNumbers: newVerseNumbers,
        texts: newTexts,
        reference: newRef,
      );
    } else {
      // Vytvoř novou skupinu
      groups.insert(0, BookmarkGroup(
        book: verse.book,
        chapter: verse.chapter,
        verseNumbers: [verse.verseNumber],
        texts: [verse.text],
        reference: '${verse.book} ${verse.chapter}:${verse.verseNumber}',
      ));
    }

    await _saveGroups(groups);
  }

  Future<void> removeBookmarkGroup(BookmarkGroup group) async {
    final groups = await getBookmarkGroups();
    groups.removeWhere((g) =>
        g.book == group.book &&
        g.chapter == group.chapter &&
        g.verseNumbers.toString() == group.verseNumbers.toString());
    await _saveGroups(groups);
  }

  /// Vrátí true pokud je verš v jakékoli záložce
  Future<bool> isVerseBookmarked(String book, int chapter, int verseNumber) async {
    final groups = await getBookmarkGroups();
    return groups.any((g) =>
        g.book == book &&
        g.chapter == chapter &&
        g.verseNumbers.contains(verseNumber));
  }

  /// Pro zpětnou kompatibilitu se study_screen.dart
  Future<List<Verse>> getBookmarks() async {
    final groups = await getBookmarkGroups();
    return groups.map((g) => Verse(
      reference: g.reference,
      text: g.fullText,
      book: g.book,
      chapter: g.chapter,
      verseNumber: g.verseNumbers.first,
    )).toList();
  }

  Future<void> removeBookmark(Verse verse) async {
    final groups = await getBookmarkGroups();
    groups.removeWhere((g) =>
        g.book == verse.book &&
        g.chapter == verse.chapter &&
        g.verseNumbers.contains(verse.verseNumber));
    await _saveGroups(groups);
  }
}
