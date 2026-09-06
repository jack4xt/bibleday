import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/bible_service.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  final _bibleService = BibleService();
  final _settings = SettingsService();

  String? _imageUrl;
  String? _imagePrompt;
  bool _loading = false;
  bool _hasApiKey = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasKey = await _settings.hasApiKey();
    setState(() => _hasApiKey = hasKey);
    _generateImage();
  }

  Future<void> _generateImage() async {
    setState(() {
      _loading = true;
      _error = null;
      _imageUrl = null;
    });

    try {
      final verse = _bibleService.getDailyVerseLocal();
      String prompt;

      if (_hasApiKey) {
        final provider = await _settings.getProvider();
        final apiKey = await _settings.getApiKey();
        final ai = AIService(provider: provider, apiKey: apiKey!);
        final aiPrompt = await ai.getImagePrompt(verse);
        prompt = aiPrompt != null && aiPrompt.isNotEmpty
            ? aiPrompt
            : 'Biblical scene, dramatic divine light, sacred art, painterly style';
      } else {
        prompt = 'Biblical scene, dramatic divine light, sacred art, painterly style';
      }

      // Vyčisti prompt — odstraň markdown a speciální znaky
      prompt = prompt
          .replaceAll(RegExp(r'#{1,6}\s*'), '')
          .replaceAll(RegExp(r'\*\*?(.*?)\*\*?'), r'$1')
          .replaceAll('\n', ' ')
          .trim();

      setState(() => _imagePrompt = prompt);

      final encodedPrompt = Uri.encodeComponent(prompt);
      final seed = DateTime.now().day +
          DateTime.now().month * 31 +
          DateTime.now().year * 365;

      // Zkusíme více modelů — flux je nejspolehlivější
      final url =
          'https://image.pollinations.ai/prompt/$encodedPrompt?model=flux&width=512&height=768&seed=$seed&nologo=true&enhance=true';

      setState(() {
        _imageUrl = url;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Nepodařilo se vygenerovat obraz.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final verse = _bibleService.getDailyVerseLocal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obraz dne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonGold),
            onPressed: _loading ? null : _generateImage,
            tooltip: 'Nový obraz',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INSPIRACE',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.neonGold,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${verse.text}"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ).animate().fadeIn(),
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

              const SizedBox(height: 28),

              Text(
                'OBRAZ DNE',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.neonGold,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 12),

              if (_loading)
                Container(
                  width: double.infinity,
                  height: 400,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.neonGold),
                      const SizedBox(height: 20),
                      Text(
                        _hasApiKey ? 'AI tvoří obraz...' : 'Generuji obraz...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              else if (_error != null)
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image_outlined,
                          color: AppTheme.textSecondary, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _generateImage,
                        child: Text(
                          'Zkusit znovu',
                          style: GoogleFonts.cinzel(color: AppTheme.neonGold),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    _imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child.animate().fadeIn(duration: 800.ms);
                      }
                      return Container(
                        width: double.infinity,
                        height: 400,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppTheme.neonGold,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Načítám obraz...\n(může trvat 10–30 sekund)',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image_outlined,
                              color: AppTheme.textSecondary, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Obraz se nepodařilo načíst.\nPollinations.ai je přetížený, zkus znovu.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _generateImage,
                            child: Text(
                              'Zkusit znovu',
                              style: GoogleFonts.cinzel(color: AppTheme.neonGold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_imagePrompt != null && !_loading) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROMPT',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: AppTheme.neonPurple),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _imagePrompt!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
