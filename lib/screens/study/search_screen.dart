import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/bible_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class SearchResult {
  final String book;
  final String bookCs;
  final int chapter;
  final int verseNumber;
  final String text;

  const SearchResult({
    required this.book,
    required this.bookCs,
    required this.chapter,
    required this.verseNumber,
    required this.text,
  });
}

class SearchScreen extends StatefulWidget {
  final Function(String book, int chapter)? onNavigate;
  // Aktuálně načtená kapitola — prohledá se okamžitě
  final String? currentBook;
  final int? currentChapter;
  final List<String>? currentVerses;

  const SearchScreen({
    super.key,
    this.onNavigate,
    this.currentBook,
    this.currentChapter,
    this.currentVerses,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _bibleService = BibleService();
  final _settings = SettingsService();
  final _controller = TextEditingController();

  List<SearchResult> _results = [];
  bool _searching = false;
  String _lastQuery = '';
  String _translationId = 'kjv';

  // Rozsah hledání
  String _searchScope = 'chapter'; // 'chapter' | 'book' | 'nt' | 'all'

  @override
  void initState() {
    super.initState();
    _loadTranslation();
  }

  Future<void> _loadTranslation() async {
    final t = await _settings.getTranslation();
    setState(() => _translationId = t);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getBookCs(String book) {
    final found = BibleService.books.firstWhere(
      (b) => b['name'] == book,
      orElse: () => {'cs': book},
    );
    return found['cs'] as String;
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }

    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() {
      _searching = true;
      _results = [];
    });

    final results = <SearchResult>[];
    final q = query.toLowerCase();

    if (_searchScope == 'chapter' && widget.currentVerses != null) {
      // Prohledej aktuální kapitolu — okamžité
      for (int v = 0; v < widget.currentVerses!.length; v++) {
        if (widget.currentVerses![v].toLowerCase().contains(q)) {
          results.add(SearchResult(
            book: widget.currentBook!,
            bookCs: _getBookCs(widget.currentBook!),
            chapter: widget.currentChapter!,
            verseNumber: v + 1,
            text: widget.currentVerses![v],
          ));
        }
      }
      setState(() {
        _results = results;
        _searching = false;
      });
    } else {
      // Prohledej přes API — pomalé, ale funguje
      List<Map<String, dynamic>> booksToSearch = [];

      if (_searchScope == 'book' && widget.currentBook != null) {
        booksToSearch = BibleService.books
            .where((b) => b['name'] == widget.currentBook)
            .toList();
      } else if (_searchScope == 'nt') {
        const ntBooks = ['Matthew', 'Mark', 'Luke', 'John', 'Acts', 'Romans',
          '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
          'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
          '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews',
          'James', '1 Peter', '2 Peter', '1 John', '2 John', '3 John',
          'Jude', 'Revelation'];
        booksToSearch = BibleService.books
            .where((b) => ntBooks.contains(b['name']))
            .toList();
      } else {
        booksToSearch = List.from(BibleService.books);
      }

      for (final book in booksToSearch) {
        final bookName = book['name'] as String;
        final bookCs = book['cs'] as String;
        final chapCount = book['chapters'] as int;

        for (int ch = 1; ch <= chapCount; ch++) {
          final chapter = await _bibleService.fetchChapter(bookName, ch, _translationId);
          if (chapter == null) continue;

          for (int v = 0; v < chapter.verses.length; v++) {
            if (chapter.verses[v].toLowerCase().contains(q)) {
              results.add(SearchResult(
                book: bookName,
                bookCs: bookCs,
                chapter: ch,
                verseNumber: v + 1,
                text: chapter.verses[v],
              ));
              if (results.length >= 30) break;
            }
          }
          if (!mounted) return;
          setState(() => _results = List.from(results));
          if (results.length >= 30) break;
        }
        if (results.length >= 30) break;
      }

      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bookCs = widget.currentBook != null ? _getBookCs(widget.currentBook!) : '';

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: GoogleFonts.crimsonText(color: AppTheme.textPrimaryColor(context), fontSize: 18),
          decoration: InputDecoration(
            hintText: l.searchHint,
            hintStyle: GoogleFonts.crimsonText(color: AppTheme.textSecondaryColor(context)),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppTheme.textSecondaryColor(context)),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _results = [];
                        _lastQuery = '';
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: _search,
          onChanged: (v) => setState(() {}),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.goldColor(context)),
            onPressed: () => _search(_controller.text),
          ),
        ],
      ),
      body: Column(
        children: [
          // Rozsah hledání
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _ScopeChip(
                  label: l.searchScopeChapter,
                  selected: _searchScope == 'chapter',
                  onTap: () => setState(() { _searchScope = 'chapter'; _lastQuery = ''; _results = []; }),
                ),
                SizedBox(width: 8),
                _ScopeChip(
                  label: bookCs.isNotEmpty ? bookCs : l.searchScopeBook,
                  selected: _searchScope == 'book',
                  onTap: () => setState(() { _searchScope = 'book'; _lastQuery = ''; _results = []; }),
                ),
                SizedBox(width: 8),
                _ScopeChip(
                  label: l.searchScopeNT,
                  selected: _searchScope == 'nt',
                  onTap: () => setState(() { _searchScope = 'nt'; _lastQuery = ''; _results = []; }),
                ),
                SizedBox(width: 8),
                _ScopeChip(
                  label: l.searchScopeAll,
                  selected: _searchScope == 'all',
                  onTap: () => setState(() { _searchScope = 'all'; _lastQuery = ''; _results = []; }),
                ),
              ],
            ),
          ),

          if (_searchScope != 'chapter')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Text(l.searchSlowWarning,
                  style: GoogleFonts.crimsonText(
                      color: AppTheme.goldColor(context), fontSize: 12, fontStyle: FontStyle.italic)),
            ),

          if (_searching)
            LinearProgressIndicator(color: AppTheme.goldColor(context), backgroundColor: AppTheme.divider),

          if (_results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Text(
                    '${_results.length}${_results.length >= 30 ? '+' : ''} ${l.searchResults}',
                    style: GoogleFonts.cinzel(
                        color: AppTheme.textSecondaryColor(context), fontSize: 12, letterSpacing: 1),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _results.isEmpty && !_searching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: AppTheme.textSecondaryColor(context), size: 64),
                        SizedBox(height: 16),
                        Text(l.searchEmpty,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final r = _results[index];
                      return GestureDetector(
                        onTap: () {
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(r.book, r.chapter);
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.dividerColor(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHighlightedText(context, r.text, _controller.text),
                              SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldColor(context).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.goldColor(context).withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '${r.bookCs} ${r.chapter}:${r.verseNumber}',
                                  style: GoogleFonts.cinzel(
                                      color: AppTheme.goldColor(context),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: index * 30)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context, String text, String query) {
    if (query.isEmpty) {
      return Text(text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic, height: 1.5));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          color: AppTheme.goldColor(context),
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0x33FFD700),
        ),
      ));
      start = idx + query.length;
    }

    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic, height: 1.5);

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.goldColor(context).withValues(alpha: 0.15) : AppTheme.surfaceElevatedColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.neonGold : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cinzel(
            color: selected ? AppTheme.neonGold : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
