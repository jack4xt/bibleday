import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/bible_database_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Online překlady — dostupné přes API, vždy přepínatelné
const List<Map<String, String>> _onlineTranslations = [
  {'id': 'bkr', 'name': 'Kralická (BKR)', 'lang': 'cs'},
  {'id': 'cep', 'name': 'Ekumenická (CEP)', 'lang': 'cs'},
  {'id': 'kjv', 'name': 'King James (KJV)', 'lang': 'en'},
  {'id': 'web', 'name': 'World English (WEB)', 'lang': 'en'},
];

class TranslationsScreen extends StatefulWidget {
  const TranslationsScreen({super.key});

  @override
  State<TranslationsScreen> createState() => _TranslationsScreenState();
}

class _TranslationsScreenState extends State<TranslationsScreen> {
  final _db = BibleDatabaseService.instance;
  final _settings = SettingsService();

  List<Map<String, dynamic>> _dbTranslations = [];
  String _activeTranslationId = 'bkr';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _db.getTranslations(),
        _settings.getTranslation(),
      ]).timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _dbTranslations = results[0] as List<Map<String, dynamic>>;
          _activeTranslationId = results[1] as String;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dbTranslations = [];
          _activeTranslationId = 'bkr';
          _loading = false;
        });
      }
    }
  }

  Future<void> _setActive(String id) async {
    await _settings.setTranslation(id);
    setState(() => _activeTranslationId = id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Překlad nastaven',
            style: GoogleFonts.cinzel(color: AppTheme.background)),
        backgroundColor: AppTheme.neonGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _deleteOffline(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevatedColor(context),
        title: Text('Smazat offline překlad',
            style: GoogleFonts.cinzel(color: AppTheme.goldColor(context))),
        content: Text('Offline data budou smazána. Překlad zůstane dostupný online.',
            style: GoogleFonts.crimsonText(color: AppTheme.textPrimaryColor(context), fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Zrušit',
                style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white),
            child: Text('Smazat', style: GoogleFonts.cinzel()),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _db.deleteTranslation(id);
    _load();
  }

  bool _isOfflineAvailable(String id) {
    return _dbTranslations.any((t) =>
        t['id'] == id && t['is_downloaded'] == 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translation)),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.goldColor(context)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ČSP — bundled, připravujeme
                  _sectionLabel('📖  PŘEDINSTALOVANÉ PŘEKLADY'),
                  const SizedBox(height: 12),
                  _buildCard(
                    id: 'csp',
                    name: 'Český studijní překlad (ČSP) — revidované vydání',
                    lang: 'cs',
                    isActive: _activeTranslationId == 'csp',
                    badge: 'Předinstalováno',
                    badgeColor: AppTheme.neonGold,
                    onTap: _activeTranslationId == 'csp' ? null : () => _setActive('csp'),
                  ).animate().fadeIn(),

                  const SizedBox(height: 28),

                  // Online překlady — vždy dostupné, přepínatelné
                  _sectionLabel('🌐  ONLINE PŘEKLADY'),
                  const SizedBox(height: 4),
                  Text('Tyto překlady jsou dostupné online. Vyber aktivní překlad.',
                      style: GoogleFonts.crimsonText(
                          color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.4)),
                  const SizedBox(height: 12),

                  ..._onlineTranslations.asMap().entries.map((e) {
                    final t = e.value;
                    final id = t['id']!;
                    final isActive = _activeTranslationId == id;
                    final isOffline = _isOfflineAvailable(id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildCard(
                        id: id,
                        name: t['name']!,
                        lang: t['lang']!,
                        isActive: isActive,
                        badge: isOffline ? 'Offline' : 'Online',
                        badgeColor: isOffline ? AppTheme.neonGold : AppTheme.textSecondary,
                        onTap: isActive ? null : () => _setActive(id),
                        trailing: isOffline
                            ? IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red.shade400, size: 20),
                                onPressed: () => _deleteOffline(id),
                              )
                            : null,
                      ).animate().fadeIn(delay: Duration(milliseconds: e.key * 80)),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.cinzel(
            color: AppTheme.goldColor(context), fontSize: 12, letterSpacing: 2));
  }

  Widget _buildCard({
    required String id,
    required String name,
    required String lang,
    required bool isActive,
    required String badge,
    required Color badgeColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppTheme.goldColor(context).withValues(alpha: 0.6)
                : AppTheme.divider,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(lang == 'cs' ? '🇨🇿' : '🇬🇧',
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.cinzel(
                          color: isActive ? AppTheme.neonGold : AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _badge(badge, badgeColor),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        _badge('Aktivní', Colors.green),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (isActive)
              Icon(Icons.check_circle, color: AppTheme.goldColor(context), size: 22)
            else if (onTap != null)
              Icon(Icons.radio_button_unchecked,
                  color: AppTheme.textSecondaryColor(context), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: GoogleFonts.cinzel(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
