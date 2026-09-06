import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/bible_service.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final _bibleService = BibleService();
  final _settings = SettingsService();

  String? _prayer;
  bool _loading = false;
  bool _hasApiKey = false;
  String _translationId = 'kjv';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final hasKey = await _settings.hasApiKey();
    final translation = await _settings.getTranslation();
    setState(() {
      _hasApiKey = hasKey;
      _translationId = translation;
    });

    if (hasKey && _prayer == null && !_loading) {
      _generatePrayer();
    }
  }

  Future<void> _generatePrayer() async {
    setState(() {
      _loading = true;
      _prayer = null;
    });

    final verse = _bibleService.getDailyVerseLocal();
    final provider = await _settings.getProvider();
    final apiKey = await _settings.getApiKey();
    final ai = AIService(provider: provider, apiKey: apiKey!);
    final lang = _translationId == 'bkr' || _translationId == 'cep' ? 'cs' : 'en';

    final prompt = lang == 'cs'
        ? 'Napiš krátkou osobní modlitbu (5-8 vět) inspirovanou tímto biblickým veršem. Modlitba by měla být upřímná, osobní a duchovně hluboká. Piš v první osobě, bez nadpisů, bez markdownu.\n\nVerš: ${verse.reference} - "${verse.text}"'
        : 'Write a short personal prayer (5-8 sentences) inspired by this Bible verse. The prayer should be sincere, personal and spiritually deep. Write in first person, plain text only.\n\nVerse: ${verse.reference} - "${verse.text}"';

    final prayer = await ai.prayerRequest(prompt);

    setState(() {
      _prayer = prayer;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final verse = _bibleService.getDailyVerseLocal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modlitba dne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonGold),
            onPressed: _hasApiKey && !_loading ? _generatePrayer : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verš inspirace
            Text(
              'INSPIRACE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.neonGold,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.neonGold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${verse.text}"',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      verse.reference,
                      style: GoogleFonts.cinzel(
                        color: AppTheme.neonGold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 28),

            // Modlitba
            Row(
              children: [
                Text(
                  'MODLITBA',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.neonGold,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.volunteer_activism,
                    color: AppTheme.neonGold, size: 16),
              ],
            ),
            const SizedBox(height: 12),

            if (!_hasApiKey)
              _buildNoApiCard(context)
            else if (_loading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.neonPurple),
                    SizedBox(height: 16),
                    Text(
                      'AI připravuje modlitbu...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            else if (_prayer == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'Nepodařilo se načíst modlitbu.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _generatePrayer,
                      child: Text(
                        'Zkusit znovu',
                        style: GoogleFonts.cinzel(color: AppTheme.neonGold),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.neonPurple.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonPurple.withValues(alpha: 0.05),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppTheme.neonPurple, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Modlitba',
                          style: GoogleFonts.cinzel(
                            color: AppTheme.neonPurple,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _prayer!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.9,
                          ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ).animate().slideY(begin: 0.2, duration: 500.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNoApiCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: AppTheme.neonGold, size: 32),
          const SizedBox(height: 12),
          Text(
            'Modlitba vyžaduje API klíč',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Přejdi do Nastavení a zadej svůj API klíč.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
