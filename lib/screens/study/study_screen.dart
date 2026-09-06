import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/verse.dart';
import '../../services/bible_service.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../services/bookmarks_service.dart';
import '../../theme/app_theme.dart';
import '../../services/cache_service.dart';
import '../../services/reading_plan_service.dart';
import '../../l10n/app_localizations.dart';
import 'reading_plan_screen.dart';
import 'map_screen.dart';
import 'search_screen.dart';
import 'assistant_screen.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with SingleTickerProviderStateMixin {
  final _bibleService = BibleService();
  final _settings = SettingsService();
  final _bookmarks = BookmarksService();
  final _cache = CacheService();
  final _planService = ReadingPlanService();
  final _tts = FlutterTts();

  late TabController _tabController;

  BibleChapter? _chapter;
  StructuredStudy? _structuredStudy;
  bool _loadingChapter = false;
  bool _loadingStudy = false;
  bool _hasApiKey = false;
  String _translationId = 'kjv';
  Set<int> _bookmarkedVerses = {};
  bool _justCompletedInPlan = false;

  // TTS stav
  bool _ttsPlaying = false;
  bool _ttsPaused = false;
  int _ttsCurrentVerse = -1;
  double _ttsRate = 0.5; // rychlost 0.0 - 1.0

  String _selectedBook = 'John';
  int _selectedChapter = 1;
  int _maxChapters = 21;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initTts();
    _load();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage(_translationId == 'bkr' || _translationId == 'cep' || _translationId == 'csp' ? 'cs-CZ' : 'en-US');
    await _tts.setSpeechRate(_ttsRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (_chapter != null && _ttsCurrentVerse < _chapter!.verses.length - 1) {
        _ttsSpeak(_ttsCurrentVerse + 1);
      } else {
        setState(() {
          _ttsPlaying = false;
          _ttsPaused = false;
          _ttsCurrentVerse = -1;
        });
      }
    });
  }

  Future<void> _ttsSpeak(int verseIndex) async {
    if (_chapter == null) return;
    final lang = (_translationId == 'bkr' || _translationId == 'cep' || _translationId == 'csp') ? 'cs-CZ' : 'en-US';
    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(_ttsRate);
    setState(() {
      _ttsPlaying = true;
      _ttsPaused = false;
      _ttsCurrentVerse = verseIndex;
    });
    await _tts.speak(_chapter!.verses[verseIndex]);
  }

  Future<void> _ttsStartReading() async {
    // Zobraz upozornění při prvním použití TTS
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('tts_info_shown') ?? false;
    if (!shown && mounted) {
      final l = AppLocalizations.of(context)!;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceElevatedColor(context),
          title: Text('🔊 ${l.ttsInfoTitle}',
              style: GoogleFonts.cinzel(color: AppTheme.goldColor(context))),
          content: Text(l.ttsInfoDesc,
              style: GoogleFonts.crimsonText(
                  color: AppTheme.textPrimaryColor(context), fontSize: 16, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK',
                  style: GoogleFonts.cinzel(
                      color: AppTheme.goldColor(context),
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      await prefs.setBool('tts_info_shown', true);
    }
    await _ttsSpeak(0);
  }

  Future<void> _ttsPause() async {
    await _tts.pause();
    setState(() {
      _ttsPaused = true;
      _ttsPlaying = false;
    });
  }

  Future<void> _ttsResume() async {
    await _tts.speak(_chapter!.verses[_ttsCurrentVerse]);
    setState(() {
      _ttsPaused = false;
      _ttsPlaying = true;
    });
  }

  Future<void> _ttsStop() async {
    await _tts.stop();
    setState(() {
      _ttsPlaying = false;
      _ttsPaused = false;
      _ttsCurrentVerse = -1;
    });
  }

  Future<void> _ttsSetRate(double rate) async {
    setState(() => _ttsRate = rate);
    await _tts.setSpeechRate(rate);
  }

  @override
  void dispose() {
    _tts.stop();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final hasKey = await _settings.hasApiKey();
    final translation = await _settings.getTranslation();
    final current = await _settings.getCurrentChapter();

    final newTranslation = translation;
    final newBook = current['book'] as String;
    final newChapter = current['chapter'] as int;

    if (_translationId != newTranslation ||
        _selectedBook != newBook ||
        _selectedChapter != newChapter ||
        _chapter == null) {
      setState(() {
        _hasApiKey = hasKey;
        _translationId = newTranslation;
        _selectedBook = newBook;
        _selectedChapter = newChapter;
        _maxChapters = _getMaxChapters(newBook);
      });
      _fetchChapter();
    }
  }

  int _getMaxChapters(String book) {
    final found = BibleService.books.firstWhere(
      (b) => b['name'] == book,
      orElse: () => {'chapters': 1},
    );
    return found['chapters'] as int;
  }

  String _getCsName(String book) {
    final found = BibleService.books.firstWhere(
      (b) => b['name'] == book,
      orElse: () => {'cs': book},
    );
    return found['cs'] as String;
  }

  Future<void> _fetchChapter() async {
    setState(() {
      _loadingChapter = true;
      _chapter = null;
      _structuredStudy = null;
      _bookmarkedVerses = {};
      _justCompletedInPlan = false;
    });

    final chapter = await _bibleService.fetchChapter(
      _selectedBook, _selectedChapter, _translationId,
    );

    setState(() {
      _chapter = chapter;
      _loadingChapter = false;
    });

    await _settings.setCurrentChapter(_selectedBook, _selectedChapter);

    if (chapter != null && _hasApiKey) {
      _fetchStructuredStudy(chapter);
    }
  }

  Future<void> _fetchStructuredStudy(BibleChapter chapter) async {
    setState(() => _loadingStudy = true);
    final lang = await _settings.resolveAiLanguage();

    final cached = await _cache.getStudy(_selectedBook, _selectedChapter, _translationId);
    if (cached != null) {
      List<StudyQuestion>? questions;
      if (cached['questions'] != null) {
        final parts = cached['questions']!.split('|||').where((s) => s.isNotEmpty).toList();
        questions = [];
        for (final part in parts) {
          final idx = part.indexOf(':::');
          if (idx != -1) {
            questions.add(StudyQuestion(
              question: part.substring(0, idx),
              answer: part.substring(idx + 3),
            ));
          }
        }
      }
      final study = StructuredStudy(
        context: cached['context'],
        summary: cached['summary'],
        keyVerses: cached['keyVerses']?.split('|||').where((s) => s.isNotEmpty).toList(),
        questions: questions,
        application: cached['application'],
      );
      setState(() {
        _structuredStudy = study;
        _loadingStudy = false;
      });
      _markPlanProgressIfNeeded();
      return;
    }

    final provider = await _settings.getProvider();
    final apiKey = await _settings.getApiKey();
    final ai = AIService(provider: provider, apiKey: apiKey!);
    final study = await ai.getStructuredStudy(chapter, lang);

    if (study != null) {
      await _cache.setStudy(
        _selectedBook, _selectedChapter, _translationId,
        context: study.context,
        summary: study.summary,
        keyVerses: study.keyVerses?.join('|||'),
        questions: study.questions?.map((q) => '${q.question}:::${q.answer}').join('|||'),
        application: study.application,
      );
    }

    setState(() {
      _structuredStudy = study;
      _loadingStudy = false;
    });

    if (study != null) {
      _markPlanProgressIfNeeded();
    }
  }

  /// Pokud uživatel dočetl kapitolu až ke studiu (otázky se úspěšně
  /// zobrazily) a tato kapitola je součástí dnešní dávky aktivního plánu,
  /// automaticky ji označí jako přečtenou.
  Future<void> _markPlanProgressIfNeeded() async {
    final marked = await _planService.markChapterDoneIfInPlan(_selectedBook, _selectedChapter);
    if (marked && mounted) {
      setState(() => _justCompletedInPlan = true);
    }
  }

  Future<void> _toggleBookmark(int verseIndex, AppLocalizations l) async {
    if (_chapter == null) return;
    final verseText = _chapter!.verses[verseIndex];
    final reference = '${_getCsName(_selectedBook)} $_selectedChapter:${verseIndex + 1}';
    final verse = Verse(
      reference: reference,
      text: verseText,
      book: _selectedBook,
      chapter: _selectedChapter,
      verseNumber: verseIndex + 1,
    );

    final isBookmarked = _bookmarkedVerses.contains(verseIndex);

    if (isBookmarked) {
      await _bookmarks.removeBookmark(verse);
      setState(() => _bookmarkedVerses.remove(verseIndex));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.bookmarkRemoved,
              style: GoogleFonts.cinzel(color: AppTheme.background)),
          backgroundColor: AppTheme.textSecondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } else {
      await _bookmarks.addBookmark(verse);
      setState(() => _bookmarkedVerses.add(verseIndex));

      // Zkontroluj jestli byl přidán do skupiny (po sobě jdoucí verš)
      final groups = await _bookmarks.getBookmarkGroups();
      final inGroup = groups.any((g) =>
          g.book == _selectedBook &&
          g.chapter == _selectedChapter &&
          g.verseNumbers.length > 1 &&
          g.verseNumbers.contains(verseIndex + 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            inGroup ? l.bookmarkAddedToGroup : l.bookmarkAdded,
            style: GoogleFonts.cinzel(color: AppTheme.background)),
          backgroundColor: AppTheme.goldColor(context),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _showVerseCopyMenu(BuildContext context, AppLocalizations l, String text, int verseIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevatedColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic, color: AppTheme.textSecondaryColor(context)),
              ),
            ),
            Divider(color: AppTheme.divider),
            ListTile(
              leading: Icon(Icons.copy, color: AppTheme.goldColor(context)),
              title: Text(l.verseCopy,
                  style: GoogleFonts.cinzel(color: AppTheme.textPrimaryColor(context))),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l.verseCopied,
                        style: GoogleFonts.cinzel(color: AppTheme.background)),
                    backgroundColor: AppTheme.goldColor(context),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.bookmark_add_outlined, color: AppTheme.purpleColor(context)),
              title: Text(l.bookmarkAdded,
                  style: GoogleFonts.cinzel(color: AppTheme.textPrimaryColor(context))),
              onTap: () {
                Navigator.pop(ctx);
                _toggleBookmark(verseIndex, l);
              },
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToChapter(String book, int chapter) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = chapter;
      _maxChapters = _getMaxChapters(book);
    });
    _tabController.animateTo(0);
    _fetchChapter();
  }

  String _removeDiacritics(String text) {
    const withDiacritics    = 'áäčďéěíňóöřšťúůüýžÁÄČĎÉĚÍŇÓÖŘŠŤÚŮÜÝŽ';
    const withoutDiacritics = 'aacdeeinnoorsstuuuyzAACDEEINNOORSSTUUUYZ';
    var result = text;
    for (int i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result;
  }

  void _showBookPicker(AppLocalizations l) {
    String query = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevatedColor(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = BibleService.books.where((b) {
            if (query.isEmpty) return true;
            final q = _removeDiacritics(query.toLowerCase());
            final csName = _removeDiacritics((b['cs'] as String).toLowerCase());
            final enName = _removeDiacritics((b['name'] as String).toLowerCase());
            return csName.contains(q) || enName.contains(q);
          }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: TextField(
                    autofocus: false,
                    style: GoogleFonts.crimsonText(
                        color: AppTheme.textPrimaryColor(context), fontSize: 17),
                    decoration: InputDecoration(
                      hintText: l.searchHint,
                      hintStyle: GoogleFonts.crimsonText(
                          color: AppTheme.textSecondaryColor(context)),
                      prefixIcon: Icon(Icons.search,
                          color: AppTheme.textSecondaryColor(context)),
                      filled: true,
                      fillColor: AppTheme.surfaceColor(context),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppTheme.dividerColor(context))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppTheme.dividerColor(context))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppTheme.goldColor(context))),
                    ),
                    onChanged: (v) => setModalState(() => query = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final book = filtered[index];
                      final isSelected = book['name'] == _selectedBook;
                      return ListTile(
                        title: Text(
                          book['cs'] as String,
                          style: GoogleFonts.crimsonText(
                            color: isSelected
                                ? AppTheme.neonGold
                                : AppTheme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 17,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check,
                                color: AppTheme.goldColor(context))
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedBook = book['name'] as String;
                            _selectedChapter = 1;
                            _maxChapters = book['chapters'] as int;
                          });
                          Navigator.pop(context);
                          _fetchChapter();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.studyBible),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.goldColor(context)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchScreen(
                  onNavigate: _navigateToChapter,
                  currentBook: _selectedBook,
                  currentChapter: _selectedChapter,
                  currentVerses: _chapter?.verses,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonGold,
          labelColor: AppTheme.neonGold,
          unselectedLabelColor: const Color(0xFFCCCCCC),
          labelStyle: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.cinzel(fontSize: 13),
          tabs: [
            Tab(text: l.tabReading),
            Tab(text: l.tabPlan),
            Tab(text: l.tabAssistant),
            Tab(text: l.tabMap),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadingTab(l),
          ReadingPlanScreen(
            onNavigateToChapter: _navigateToChapter,
            currentOpenBook: _selectedBook,
            currentOpenChapter: _selectedChapter,
          ),
          const AssistantScreen(),
          MapScreen(book: _selectedBook, chapter: _selectedChapter),
        ],
      ),
    );
  }

  Widget _buildReadingTab(AppLocalizations l) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surfaceColor(context),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTap: () => _showBookPicker(l),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevatedColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.goldColor(context).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getCsName(_selectedBook),
                            style: GoogleFonts.cinzel(color: AppTheme.goldColor(context), fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: AppTheme.goldColor(context)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevatedColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor(context)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedChapter,
                      dropdownColor: AppTheme.surfaceElevatedColor(context),
                      isExpanded: true,
                      items: List.generate(
                        _maxChapters,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${l.chapter} ${i + 1}',
                              style: GoogleFonts.cinzel(color: AppTheme.textPrimaryColor(context), fontSize: 13)),
                        ),
                      ),
                      onChanged: (v) {
                        setState(() => _selectedChapter = v!);
                        _fetchChapter();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _loadingChapter
              ? Center(child: CircularProgressIndicator(color: AppTheme.goldColor(context)))
              : _chapter == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, color: AppTheme.textSecondaryColor(context), size: 48),
                          SizedBox(height: 16),
                          Text(l.chapterLoadError,
                              style: Theme.of(context).textTheme.bodyMedium),
                          SizedBox(height: 12),
                          TextButton(
                            onPressed: _fetchChapter,
                            child: Text(l.tryAgain,
                                style: GoogleFonts.cinzel(color: AppTheme.goldColor(context))),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text('${_getCsName(_selectedBook)} $_selectedChapter',
                                    style: Theme.of(context).textTheme.displayMedium)
                                    .animate().fadeIn(),
                              ),
                              if (_justCompletedInPlan)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldColor(context).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.goldColor(context).withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: AppTheme.goldColor(context), size: 14),
                                      SizedBox(width: 4),
                                      Text(l.planChapterDone,
                                          style: GoogleFonts.cinzel(
                                              color: AppTheme.goldColor(context),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ).animate().fadeIn().scale(delay: 100.ms),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(_translationId.toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: AppTheme.goldColor(context))),
                          SizedBox(height: 24),

                          // TTS ovládání
                          if (_chapter != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.dividerColor(context)),
                              ),
                              child: Row(
                                children: [
                                  // Play/Pause/Stop
                                  if (!_ttsPlaying && !_ttsPaused)
                                    IconButton(
                                      icon: Icon(Icons.play_circle, color: AppTheme.goldColor(context), size: 32),
                                      onPressed: _ttsStartReading,
                                      tooltip: 'Přečíst',
                                    )
                                  else if (_ttsPlaying)
                                    IconButton(
                                      icon: Icon(Icons.pause_circle, color: AppTheme.goldColor(context), size: 32),
                                      onPressed: _ttsPause,
                                      tooltip: 'Pauza',
                                    )
                                  else
                                    IconButton(
                                      icon: Icon(Icons.play_circle, color: AppTheme.goldColor(context), size: 32),
                                      onPressed: _ttsResume,
                                      tooltip: 'Pokračovat',
                                    ),
                                  if (_ttsPlaying || _ttsPaused)
                                    IconButton(
                                      icon: Icon(Icons.stop_circle, color: AppTheme.textSecondaryColor(context), size: 28),
                                      onPressed: _ttsStop,
                                      tooltip: 'Stop',
                                    ),
                                  SizedBox(width: 4),
                                  // Rychlost
                                  Icon(Icons.speed, color: AppTheme.textSecondaryColor(context), size: 16),
                                  Expanded(
                                    child: Slider(
                                      value: _ttsRate,
                                      min: 0.2,
                                      max: 1.0,
                                      divisions: 4,
                                      activeColor: AppTheme.neonGold,
                                      inactiveColor: AppTheme.divider,
                                      onChanged: _ttsSetRate,
                                    ),
                                  ),
                                  if (_ttsCurrentVerse >= 0)
                                    Text(
                                      '${_ttsCurrentVerse + 1}/${_chapter!.verses.length}',
                                      style: GoogleFonts.cinzel(
                                          color: AppTheme.textSecondaryColor(context), fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                          ],

                          ..._chapter!.verses.asMap().entries.map((e) {
                            final isBookmarked = _bookmarkedVerses.contains(e.key);
                            final isCurrentTts = e.key == _ttsCurrentVerse;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: isCurrentTts ? BoxDecoration(
                                color: AppTheme.goldColor(context).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.goldColor(context).withValues(alpha: 0.3)),
                              ) : null,
                              child: GestureDetector(
                                onLongPress: () {
                                  final ref = '${_getCsName(_selectedBook)} $_selectedChapter:${e.key + 1}';
                                  final text = '"${e.value}" — $ref';
                                  _showVerseCopyMenu(context, l, text, e.key);
                                },
                                child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCurrentTts ? 8 : 0,
                                vertical: isCurrentTts ? 4 : 0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: RichText(
                                      textScaler: MediaQuery.textScalerOf(context),
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${e.key + 1}  ',
                                            style: GoogleFonts.cinzel(
                                              color: AppTheme.goldColor(context),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: e.value,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontFamily: GoogleFonts.crimsonText().fontFamily,
                                              height: 1.7,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _toggleBookmark(e.key, l),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8, top: 2),
                                      child: Icon(
                                        isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                                        color: isBookmarked ? AppTheme.neonGold : AppTheme.textSecondary,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                              ),
                            ).animate().fadeIn(delay: Duration(milliseconds: e.key * 20));
                          }),

                          SizedBox(height: 32),
                          Divider(color: AppTheme.divider),
                          SizedBox(height: 24),

                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: AppTheme.purpleColor(context), size: 16),
                              SizedBox(width: 8),
                              Text(l.studyChapter,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: AppTheme.purpleColor(context))),
                            ],
                          ),
                          SizedBox(height: 16),

                          if (!_hasApiKey)
                            _buildNoApiCard(context, l)
                          else if (_loadingStudy)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(color: AppTheme.purpleColor(context)),
                                    SizedBox(height: 12),
                                    Text(l.studyLoading,
                                        style: TextStyle(color: AppTheme.textSecondaryColor(context))),
                                  ],
                                ),
                              ),
                            )
                          else if (_structuredStudy == null)
                            Center(
                              child: TextButton(
                                onPressed: () => _fetchStructuredStudy(_chapter!),
                                child: Text(l.studyLoad,
                                    style: GoogleFonts.cinzel(color: AppTheme.goldColor(context))),
                              ),
                            )
                          else
                            _buildStructuredStudy(context, _structuredStudy!, l),

                          if (_structuredStudy != null)
                            _buildPlanProgressSection(l),

                          SizedBox(height: 32),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPlanProgressSection(AppLocalizations l) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _planService.getTodayChapters(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
        final today = snapshot.data!;
        if (today['done'] == true) return const SizedBox.shrink();

        final chapters = (today['chapters'] as List).cast<Map<String, dynamic>>();
        final completed = (today['completed'] as int? ?? 0);
        final allBatchDone = today['allBatchDone'] == true;

        // Najdi index aktuální kapitoly v dnešní dávce
        final currentIdx = chapters.indexWhere(
            (c) => c['book'] == _selectedBook && c['chapter'] == _selectedChapter);

        // Další kapitola v dnešní dávce
        Map<String, dynamic>? nextChapter;
        if (currentIdx != -1 && currentIdx + 1 < chapters.length) {
          final next = chapters[currentIdx + 1];
          final isNextDone = _planService.isChapterDone(
              next['book'], next['chapter'] as int);
          nextChapter = next;
        }

        return Column(
          children: [
            SizedBox(height: 24),
            Divider(color: AppTheme.divider),
            SizedBox(height: 16),

            if (allBatchDone)
              // Všechny dnešní kapitoly přečteny
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor(context).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.goldColor(context).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.goldColor(context), size: 36),
                    SizedBox(height: 8),
                    Text(l.planTodayDone,
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center),
                    SizedBox(height: 4),
                    Text(l.planTodayDoneDesc,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                  ],
                ),
              ).animate().fadeIn()
            else if (nextChapter != null)
              // Další kapitola v plánu
              Column(
                children: [
                  Text(l.planReadNext,
                      style: GoogleFonts.cinzel(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 11,
                          letterSpacing: 1.5)),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _navigateToChapter(
                          nextChapter!['book'] as String,
                          nextChapter['chapter'] as int,
                        );
                      },
                      icon: Icon(Icons.arrow_forward),
                      label: Text(
                        '${_getCsName(nextChapter['book'] as String)} ${nextChapter['chapter']}',
                        style: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(),
          ],
        );
      },
    );
  }

  Widget _buildStructuredStudy(BuildContext context, StructuredStudy study, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (study.context != null) ...[
          _buildStudySection(context, icon: '📜', title: l.context,
              child: Text(study.context!, style: Theme.of(context).textTheme.bodyLarge)),
          SizedBox(height: 16),
        ],
        if (study.summary != null) ...[
          _buildStudySection(context, icon: '📋', title: l.summary,
              child: Text(study.summary!, style: Theme.of(context).textTheme.bodyLarge)),
          SizedBox(height: 16),
        ],
        if (study.keyVerses != null && study.keyVerses!.isNotEmpty) ...[
          _buildStudySection(
            context, icon: '💡', title: l.keyVerses,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: study.keyVerses!.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✦  ', style: GoogleFonts.cinzel(color: AppTheme.goldColor(context), fontSize: 12)),
                    Expanded(
                      child: Text(v, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          SizedBox(height: 16),
        ],
        if (study.questions != null && study.questions!.isNotEmpty) ...[
          _buildStudySection(
            context, icon: '❓', title: l.questions,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: study.questions!.asMap().entries.map((e) =>
                QuestionItem(index: e.key + 1, question: e.value),
              ).toList(),
            ),
          ),
          SizedBox(height: 16),
        ],
        if (study.application != null) ...[
          _buildStudySection(context, icon: '🎯', title: l.application,
              child: Text(study.application!, style: Theme.of(context).textTheme.bodyLarge),
              borderColor: AppTheme.goldColor(context).withValues(alpha: 0.3)),
        ],
      ],
    ).animate().fadeIn();
  }

  Widget _buildStudySection(BuildContext context, {
    required String icon, required String title, required Widget child, Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppTheme.purpleColor(context).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppTheme.purpleColor(context), letterSpacing: 1.5)),
            ],
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildNoApiCard(BuildContext context, AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: AppTheme.goldColor(context), size: 32),
          SizedBox(height: 12),
          Text(l.studyApiRequired,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text(l.apiKeyRequiredDesc,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class QuestionItem extends StatefulWidget {
  final int index;
  final StudyQuestion question;

  const QuestionItem({super.key, required this.index, required this.question});

  @override
  State<QuestionItem> createState() => _QuestionItemState();
}

class _QuestionItemState extends State<QuestionItem> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24, height: 24,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: AppTheme.purpleColor(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.purpleColor(context).withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text('${widget.index}',
                      style: GoogleFonts.cinzel(
                          color: AppTheme.purpleColor(context), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: Text(widget.question.question,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showAnswer = !_showAnswer),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _showAnswer ? AppTheme.goldColor(context).withValues(alpha: 0.08) : AppTheme.surfaceElevatedColor(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _showAnswer ? AppTheme.goldColor(context).withValues(alpha: 0.3) : AppTheme.divider,
                ),
              ),
              child: _showAnswer
                  ? Text(widget.question.answer,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: GoogleFonts.crimsonText().fontFamily,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppTheme.textSecondaryColor(context), size: 14),
                        SizedBox(width: 6),
                        Text(l.showAnswer,
                            style: GoogleFonts.cinzel(
                                color: AppTheme.textSecondaryColor(context), fontSize: 11, letterSpacing: 1)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
