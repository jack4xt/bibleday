import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final _settings = SettingsService();
  final _apiKeyController = TextEditingController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    if (_apiKeyController.text.isNotEmpty) {
      await _settings.setApiKey(_apiKeyController.text.trim());
      await _settings.setProviderId('anthropic');
    }
    await _settings.setOnboardingDone();
    widget.onDone();
  }

  Future<void> _openApiUrl() async {
    const url = 'https://console.anthropic.com/settings/keys';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final pages = [
      {
        'icon': '✝️',
        'title': l.onboardingTitle1,
        'subtitle': l.onboardingSubtitle1,
        'body': l.onboardingBody1,
      },
      {
        'icon': '📖',
        'title': l.onboardingTitle2,
        'subtitle': l.onboardingSubtitle2,
        'body': l.onboardingBody2,
      },
      {
        'icon': '🔑',
        'title': l.onboardingTitle3,
        'subtitle': l.onboardingSubtitle3,
        'body': l.onboardingBody3,
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage ? AppTheme.neonGold : AppTheme.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(page['icon']!, style: const TextStyle(fontSize: 64))
                            .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 24),
                        Text(page['title']!,
                            style: Theme.of(context).textTheme.displayMedium,
                            textAlign: TextAlign.center)
                            .animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 8),
                        Text(page['subtitle']!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.neonPurple),
                            textAlign: TextAlign.center)
                            .animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 24),
                        Text(page['body']!,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center)
                            .animate().fadeIn(delay: 400.ms),

                        if (index == 2) ...[
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.neonGold.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                Text(l.onboardingPrice,
                                    style: GoogleFonts.cinzel(
                                        color: AppTheme.neonGold,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(l.onboardingPriceDesc,
                                    style: GoogleFonts.crimsonText(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                        height: 1.5),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _apiKeyController,
                            obscureText: true,
                            style: GoogleFonts.crimsonText(
                                color: AppTheme.textPrimary, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: l.apiKeyHint,
                              hintStyle: GoogleFonts.crimsonText(color: AppTheme.textSecondary),
                              filled: true,
                              fillColor: AppTheme.surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.divider)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.divider)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.neonGold)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _openApiUrl,
                            icon: const Icon(Icons.open_in_new,
                                color: AppTheme.neonPurple, size: 16),
                            label: Text(l.getApiKey,
                                style: GoogleFonts.cinzel(
                                    color: AppTheme.neonPurple, fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  if (_currentPage == pages.length - 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _finish,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.divider),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l.skip,
                            style: GoogleFonts.cinzel(color: AppTheme.textSecondary, fontSize: 14)),
                      ),
                    ),
                  if (_currentPage == pages.length - 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _currentPage < pages.length - 1 ? _nextPage : _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonGold,
                        foregroundColor: AppTheme.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentPage < pages.length - 1 ? l.next : l.startStudying,
                        style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
