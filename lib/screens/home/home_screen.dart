import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/verse.dart';
import '../../services/bible_service.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../services/cache_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bibleService = BibleService();
  final _settings = SettingsService();
  final _cache = CacheService();

  Verse? _verse;
  String? _reflection;
  String? _prayer;
  bool _loadingReflection = false;
  bool _loadingPrayer = false;
  bool _hasApiKey = false;
  String _translationId = 'kjv';

  @override
  void initState() {
    super.initState();
    // _load() called from didChangeDependencies where context is available
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    _load(czech: locale.languageCode == 'cs');
  }

  Future<void> _load({bool czech = false}) async {
    final hasKey = await _settings.hasApiKey();
    final translation = await _settings.getTranslation();

    // Načti verš z aktivního překladu
    Verse? verse = await _bibleService.getDailyVerseFromTranslation(translation);
    // Fallback na záložní verš pokud překlad není dostupný
    verse ??= _bibleService.getDailyVerseLocal(czech: czech);

    setState(() {
      _hasApiKey = hasKey;
      _translationId = translation;
      _verse = verse;
    });

    if (!hasKey) return;

    final cachedReflection = await _cache.getDailyReflection();
    final cachedPrayer = await _cache.getDailyPrayer();

    if (cachedReflection != null) {
      setState(() => _reflection = cachedReflection);
    } else if (_reflection == null && !_loadingReflection) {
      _loadReflection(verse);
    }

    if (cachedPrayer != null) {
      setState(() => _prayer = cachedPrayer);
    } else if (_prayer == null && !_loadingPrayer) {
      _loadPrayer(verse);
    }
  }

  Future<void> _loadReflection(Verse verse) async {
    setState(() => _loadingReflection = true);
    final provider = await _settings.getProvider();
    final apiKey = await _settings.getApiKey();
    final ai = AIService(provider: provider, apiKey: apiKey!);
    final lang = await _settings.resolveAiLanguage();
    final reflection = await ai.getVerseReflection(verse, lang);
    if (reflection != null) await _cache.setDailyReflection(reflection);
    setState(() {
      _reflection = reflection;
      _loadingReflection = false;
    });
  }

  Future<void> _loadPrayer(Verse verse) async {
    setState(() => _loadingPrayer = true);
    final provider = await _settings.getProvider();
    final apiKey = await _settings.getApiKey();
    final ai = AIService(provider: provider, apiKey: apiKey!);
    final lang = await _settings.resolveAiLanguage();
    final prompt = lang == 'cs'
        ? 'Napiš krátkou osobní modlitbu (5-8 vět) inspirovanou tímto biblickým veršem. Modlitba by měla být upřímná, osobní a duchovně hluboká. Piš v první osobě, bez nadpisů, bez markdownu.\n\nVerš: ${verse.reference} - "${verse.text}"'
        : 'Write a short personal prayer (5-8 sentences) inspired by this Bible verse. The prayer should be sincere, personal and spiritually deep. Write in first person, plain text only.\n\nVerse: ${verse.reference} - "${verse.text}"';
    final prayer = await ai.prayerRequest(prompt);
    if (prayer != null) await _cache.setDailyPrayer(prayer);
    setState(() {
      _prayer = prayer;
      _loadingPrayer = false;
    });
  }

  void _shareVerse() {
    if (_verse == null) return;
    final text = '"${_verse!.text}"\n— ${_verse!.reference}\n\n#BibleDay';
    Share.share(text);
  }

  void _shareVerseWithReflection() {
    if (_verse == null || _reflection == null) return;
    final text = '"${_verse!.text}"\n— ${_verse!.reference}\n\n${_reflection!}\n\n#BibleDay';
    Share.share(text);
  }

  Future<void> _forceRefresh() async {
    await _cache.clearDailyCache();
    setState(() {
      _reflection = null;
      _prayer = null;
    });
    final locale = Localizations.localeOf(context);
    _load(czech: locale.languageCode == 'cs');
  }

  String _getGreeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l.greetingMorning;
    if (hour < 18) return l.greetingAfternoon;
    return l.greetingEvening;
  }

  String _formatDate(AppLocalizations l) {
    final now = DateTime.now();
    final months = [
      l.january, l.february, l.march, l.april, l.may, l.june,
      l.july, l.august, l.september, l.october, l.november, l.december
    ];
    final days = [l.monday, l.tuesday, l.wednesday, l.thursday, l.friday, l.saturday, l.sunday];
    return '${days[now.weekday - 1]}, ${now.day}. ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Image.asset('assets/images/banner.png',
    fit: BoxFit.cover,
    alignment: Alignment.center,
),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.backgroundColorOf(context)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40, right: 12,
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: AppTheme.goldColor(context)),
                    onPressed: _forceRefresh,
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getGreeting(l), style: Theme.of(context).textTheme.bodyMedium)
                      .animate().fadeIn(),
                  Text(_formatDate(l), style: Theme.of(context).textTheme.displayMedium)
                      .animate().fadeIn(delay: 100.ms),

                  SizedBox(height: 28),

                  if (_verse != null) ...[
                    _buildSectionLabel(context, '✦  ${l.verseOfDay}'),
                    SizedBox(height: 12),
                    _buildVerseCard(context),
                    SizedBox(height: 20),

                    _buildSectionLabel(context, '✦  ${l.reflection}'),
                    SizedBox(height: 12),
                    _buildReflectionCard(context, l),
                    SizedBox(height: 20),

                    _buildSectionLabel(context, '✦  ${l.prayer}'),
                    SizedBox(height: 12),
                    _buildPrayerCard(context, l),
                  ],

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.goldColor(context), letterSpacing: 2));
  }

  Widget _buildVerseCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldColor(context).withValues(alpha: 0.3), width: 1),
        boxShadow: [BoxShadow(color: AppTheme.goldColor(context).withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"${_verse!.text}"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic, fontSize: 20, height: 1.8))
              .animate().fadeIn(delay: 200.ms),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.goldColor(context).withValues(alpha: 0.4)),
                ),
                child: Text(_verse!.reference,
                    style: GoogleFonts.cinzel(color: AppTheme.goldColor(context), fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: Icon(Icons.share_outlined, color: AppTheme.goldColor(context), size: 20),
                onPressed: _shareVerse,
                tooltip: 'Sdílet verš',
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    ).animate().slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildReflectionCard(BuildContext context, AppLocalizations l) {
    if (!_hasApiKey) return _buildNoApiCard(context, '${l.reflection} ${l.apiKeyRequired}', l);
    if (_loadingReflection) return _buildLoadingCard(context, l.loadingReflection);
    if (_reflection == null) return _buildErrorCard(context, () => _loadReflection(_verse!), l);
    return _buildContentCard(context, _reflection!,
        shareAction: _shareVerseWithReflection);
  }

  Widget _buildPrayerCard(BuildContext context, AppLocalizations l) {
    if (!_hasApiKey) return _buildNoApiCard(context, '${l.prayer} ${l.apiKeyRequired}', l);
    if (_loadingPrayer) return _buildLoadingCard(context, l.loadingPrayer);
    if (_prayer == null) return _buildErrorCard(context, () => _loadPrayer(_verse!), l);
    return _buildContentCard(context, _prayer!, italic: true,
        borderColor: AppTheme.goldColor(context).withValues(alpha: 0.3));
  }

  Widget _buildLoadingCard(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor(context)),
      ),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.purpleColor(context)),
            SizedBox(height: 12),
            Text(message, style: TextStyle(color: AppTheme.textSecondaryColor(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, VoidCallback onRetry, AppLocalizations l) {
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
          Icon(Icons.error_outline, color: AppTheme.textSecondaryColor(context)),
          SizedBox(height: 8),
          Text(l.errorLoad, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(l.tryAgain, style: GoogleFonts.cinzel(color: AppTheme.goldColor(context))),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, String text,
      {bool italic = false, Color? borderColor, VoidCallback? shareAction}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppTheme.purpleColor(context).withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(
            color: (borderColor ?? AppTheme.neonPurple).withValues(alpha: 0.05),
            blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: italic ? FontStyle.italic : FontStyle.normal, height: 1.9))
              .animate().fadeIn(delay: 200.ms),
          if (shareAction != null) ...[
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.share_outlined,
                    color: AppTheme.purpleColor(context), size: 20),
                onPressed: shareAction,
                tooltip: 'Sdílet verš se zamyšlením',
              ),
            ),
          ],
        ],
      ),
    ).animate().slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildNoApiCard(BuildContext context, String message, AppLocalizations l) {
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
          Text(message, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text(l.apiKeyRequiredDesc, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
