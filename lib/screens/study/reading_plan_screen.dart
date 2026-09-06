import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/bible_service.dart';
import '../../services/reading_plan_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ReadingPlanScreen extends StatefulWidget {
  final Function(String book, int chapter)? onNavigateToChapter;
  final String? currentOpenBook;
  final int? currentOpenChapter;
  const ReadingPlanScreen({
    super.key,
    this.onNavigateToChapter,
    this.currentOpenBook,
    this.currentOpenChapter,
  });

  @override
  State<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends State<ReadingPlanScreen> {
  final _planService = ReadingPlanService();

  ReadingPlanType? _activePlan;
  Map<String, dynamic>? _todayChapters;
  bool _loading = true;

  final String _customBook = 'John';
  final int _customChaptersPerDay = 2;
  Set<String> _completedSet = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReadingPlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentOpenBook != widget.currentOpenBook ||
        oldWidget.currentOpenChapter != widget.currentOpenChapter) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final planType = await _planService.getActivePlanType();
    final today = planType != null ? await _planService.getTodayChapters() : null;
    final completedList = await _planService.getCompletedChapters();
    setState(() {
      _activePlan = planType;
      _todayChapters = today;
      _completedSet = completedList.toSet();
      _loading = false;
    });
  }

  Future<void> _startPlan(ReadingPlanType type, {String? customBook, int chaptersPerDay = 2}) async {
    await _planService.startPlan(type, customBook: customBook, chaptersPerDay: chaptersPerDay);
    _load();
  }

  String _getCsName(String book) {
    final found = BibleService.books.firstWhere(
      (b) => b['name'] == book,
      orElse: () => {'cs': book},
    );
    return found['cs'] as String;
  }

  String _planName(ReadingPlanType type, AppLocalizations l) {
    switch (type) {
      case ReadingPlanType.wholeBible: return l.wholeBible;
      case ReadingPlanType.newTestament: return l.newTestament;
      case ReadingPlanType.custom: return l.customPlan;
    }
  }

  void _showStartPlanDialog(AppLocalizations l) {
    ReadingPlanType selectedType = ReadingPlanType.wholeBible;
    String selectedBook = _customBook;
    int selectedChaptersPerDay = _customChaptersPerDay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevatedColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor(context), borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(l.readingPlan, style: Theme.of(context).textTheme.displayMedium),
              SizedBox(height: 20),

              ...[
                ReadingPlanType.wholeBible,
                ReadingPlanType.newTestament,
                ReadingPlanType.custom,
              ].map((type) => RadioListTile<ReadingPlanType>(
                value: type,
                groupValue: selectedType,
                activeColor: AppTheme.neonGold,
                onChanged: (v) => setModalState(() => selectedType = v!),
                title: Text(_planName(type, l),
                    style: GoogleFonts.crimsonText(
                      color: selectedType == type ? AppTheme.neonGold : AppTheme.textPrimary,
                      fontSize: 18,
                    )),
                subtitle: Text(
                  type == ReadingPlanType.wholeBible
                      ? '${_planService.getTotalChapters(ReadingPlanType.wholeBible)} ${l.chapters}'
                      : type == ReadingPlanType.newTestament
                          ? '${_planService.getTotalChapters(ReadingPlanType.newTestament)} ${l.chapters}'
                          : l.selectBook,
                  style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context), fontSize: 11),
                ),
              )),

              if (selectedType == ReadingPlanType.custom) ...[
                SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor(context)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedBook,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceElevatedColor(context),
                      items: BibleService.books.map((b) => DropdownMenuItem(
                        value: b['name'] as String,
                        child: Text(b['cs'] as String,
                            style: GoogleFonts.crimsonText(
                                color: AppTheme.textPrimaryColor(context), fontSize: 16)),
                      )).toList(),
                      onChanged: (v) => setModalState(() => selectedBook = v!),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(l.chaptersPerDay,
                        style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context), fontSize: 13)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.remove, color: AppTheme.goldColor(context)),
                      onPressed: () => setModalState(() {
                        if (selectedChaptersPerDay > 1) selectedChaptersPerDay--;
                      }),
                    ),
                    Text('$selectedChaptersPerDay',
                        style: GoogleFonts.cinzel(
                            color: AppTheme.goldColor(context), fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.add, color: AppTheme.goldColor(context)),
                      onPressed: () => setModalState(() {
                        if (selectedChaptersPerDay < 10) selectedChaptersPerDay++;
                      }),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startPlan(
                      selectedType,
                      customBook: selectedType == ReadingPlanType.custom ? selectedBook : null,
                      chaptersPerDay: selectedChaptersPerDay,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldColor(context),
                    foregroundColor: AppTheme.backgroundColorOf(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l.startPlan,
                      style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.goldColor(context)));
    }
    if (_activePlan == null) {
      return _buildNoPlanView(context, l);
    }
    return _buildActivePlanView(context, l);
  }

  Widget _buildNoPlanView(BuildContext context, AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondaryColor(context), size: 64),
            SizedBox(height: 24),
            Text(l.noPlan,
                style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
            SizedBox(height: 12),
            Text(l.noPlanDesc,
                style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showStartPlanDialog(l),
              icon: Icon(Icons.add),
              label: Text(l.createPlan, style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor(context),
                foregroundColor: AppTheme.backgroundColorOf(context),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildActivePlanView(BuildContext context, AppLocalizations l) {
    final total = _todayChapters?['total'] ?? 0;
    final completed = _todayChapters?['completed'] ?? 0;
    final isDone = _todayChapters?['done'] == true;
    final allBatchDone = _todayChapters?['allBatchDone'] == true;
    final chapters = (_todayChapters?['chapters'] as List?) ?? [];
    final progress = total > 0 ? completed / total : 0.0;
    final batchSize = _todayChapters?['batchSize'] ?? chapters.length;
    final batchDone = _todayChapters?['batchDone'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.readingPlan,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppTheme.goldColor(context), letterSpacing: 2)),
                    SizedBox(height: 4),
                    Text(_planName(_activePlan!, l),
                        style: Theme.of(context).textTheme.displayMedium),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.progress,
                        style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context), fontSize: 12)),
                    Text('$completed / $total ${l.chapters}',
                        style: GoogleFonts.cinzel(color: AppTheme.goldColor(context), fontSize: 12)),
                  ],
                ),
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.toDouble(),
                    backgroundColor: AppTheme.dividerColor(context),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.neonGold),
                    minHeight: 8,
                  ),
                ),
                SizedBox(height: 8),
                Text('${(progress * 100).toStringAsFixed(1)}${l.completed}',
                    style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context), fontSize: 11)),
              ],
            ),
          ).animate().fadeIn(),

          SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.todayReading,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppTheme.goldColor(context), letterSpacing: 2)),
              if (!isDone)
                Text('$batchDone / $batchSize',
                    style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context), fontSize: 12)),
            ],
          ),
          if (!isDone) ...[
            SizedBox(height: 4),
            Text(l.planAutoTrackHint,
                style: GoogleFonts.crimsonText(
                    color: AppTheme.textSecondaryColor(context), fontSize: 13, fontStyle: FontStyle.italic)),
          ],
          SizedBox(height: 12),

          if (isDone)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.goldColor(context).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.celebration, color: AppTheme.goldColor(context), size: 48),
                  SizedBox(height: 16),
                  Text(l.planDone,
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center),
                  SizedBox(height: 8),
                  Text(l.planDoneDesc,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            )
          else if (allBatchDone)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.goldColor(context).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.goldColor(context).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.goldColor(context), size: 48),
                  SizedBox(height: 16),
                  Text(l.planTodayDone,
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center),
                  SizedBox(height: 8),
                  Text(l.planTodayDoneDesc,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  // Zobraz odškrtnuté kapitoly
                  ...chapters.map((ch) {
                    final book = ch['book'] as String;
                    final chapter = ch['chapter'] as int;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppTheme.goldColor(context), size: 18),
                          SizedBox(width: 10),
                          Text('${_getCsName(book)} $chapter',
                              style: GoogleFonts.cinzel(
                                  color: AppTheme.goldColor(context),
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            )
          else
            ...chapters.asMap().entries.map((e) {
              final ch = e.value as Map<String, dynamic>;
              final book = ch['book'] as String;
              final chapter = ch['chapter'] as int;
              final isChapterDone = (completed as int) >= 0 &&
                  _completedSet.contains('$book:$chapter');
              final isCurrentlyOpen = widget.currentOpenBook == book &&
                  widget.currentOpenChapter == chapter;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isChapterDone
                      ? AppTheme.goldColor(context).withValues(alpha: 0.06)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isChapterDone
                        ? AppTheme.goldColor(context).withValues(alpha: 0.4)
                        : isCurrentlyOpen
                            ? AppTheme.purpleColor(context).withValues(alpha: 0.7)
                            : AppTheme.purpleColor(context).withValues(alpha: 0.3),
                    width: isCurrentlyOpen ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isChapterDone ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isChapterDone ? AppTheme.neonGold : AppTheme.textSecondary,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('${_getCsName(book)} $chapter',
                          style: GoogleFonts.cinzel(
                              color: isChapterDone ? AppTheme.neonGold : AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: isChapterDone ? TextDecoration.lineThrough : null)),
                    ),
                    if (isCurrentlyOpen && !isChapterDone)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(l.currentlyReading,
                            style: GoogleFonts.cinzel(
                                color: AppTheme.purpleColor(context),
                                fontSize: 10,
                                fontStyle: FontStyle.italic)),
                      ),
                    if (widget.onNavigateToChapter != null && !isChapterDone)
                      TextButton(
                        onPressed: () => widget.onNavigateToChapter!(book, chapter),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.neonPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(l.read,
                            style: GoogleFonts.cinzel(
                                color: AppTheme.purpleColor(context),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: e.key * 100));
            }),

          SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => _showStartPlanDialog(l),
              child: Text(l.changePlan,
                  style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context))),
            ),
          ),
          SizedBox(height: 8),
          // Tlačítko Načíst další kapitoly
          if (!isDone)
            Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _planService.loadNextBatch();
                  _load();
                },
                icon: Icon(Icons.add, color: AppTheme.purpleColor(context), size: 18),
                label: Text(l.planLoadNext,
                    style: GoogleFonts.cinzel(
                        color: AppTheme.purpleColor(context), fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.purpleColor(context)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          SizedBox(height: 8),
          // Tlačítko Obnovit (pokud se kapitoly nezobrazí)
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await _planService.refreshTodayBatch();
                _load();
              },
              icon: Icon(Icons.refresh,
                  color: AppTheme.textSecondaryColor(context), size: 16),
              label: Text(l.planRefresh,
                  style: GoogleFonts.cinzel(
                      color: AppTheme.textSecondaryColor(context), fontSize: 12)),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
