import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';
import '../../services/backup_service.dart';
import '../../services/backup_worker.dart';
import '../../services/notification_service.dart';
import 'translations_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  final _backup = BackupService();
  final _apiKeyController = TextEditingController();

  String _translationId = 'kjv';
  bool _apiKeyVisible = false;
  bool _hasApiKey = false;
  String _version = '';
  double _fontSize = 1.0;
  String _aiLanguage = 'auto';
  bool _autoBackupEnabled = false;
  String _autoBackupFrequency = 'daily';
  TimeOfDayValue _autoBackupTime = const TimeOfDayValue(hour: 8, minute: 0);
  DateTime? _lastAutoBackup;
  bool _notificationEnabled = false;
  int _notificationHour = 8;
  int _notificationMinute = 0;
  bool _isDarkTheme = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final translationId = await _settings.getTranslation();
    final apiKey = await _settings.getApiKey();
    final hasKey = await _settings.hasApiKey();
    final info = await PackageInfo.fromPlatform();
    final fontSize = await _settings.getFontSize();
    final autoEnabled = await _backup.isAutoBackupEnabled();
    final autoFreq = await _backup.getAutoBackupFrequency();
    final autoTime = await _backup.getAutoBackupTime();
    final lastBackup = await _backup.getLastAutoBackupTime();
    final aiLanguage = await _settings.getAiLanguage();
    final notifEnabled = await NotificationService.isEnabled();
    final notifTime = await NotificationService.getTime();
    final isDark = await _settings.isDarkTheme();

    setState(() {
      _translationId = translationId;
      _hasApiKey = hasKey;
      _version = info.version;
      _fontSize = fontSize;
      _aiLanguage = aiLanguage;
      _autoBackupEnabled = autoEnabled;
      _autoBackupFrequency = autoFreq;
      _autoBackupTime = autoTime;
      _lastAutoBackup = lastBackup;
      _notificationEnabled = notifEnabled;
      _notificationHour = notifTime.hour;
      _notificationMinute = notifTime.minute;
      _isDarkTheme = isDark;
      if (apiKey != null) _apiKeyController.text = apiKey;
    });
  }

  Future<void> _saveApiKey(AppLocalizations l) async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      await _settings.setApiKey('');
      setState(() => _hasApiKey = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.apiKeyRemoved, style: GoogleFonts.cinzel(color: AppTheme.background)),
          backgroundColor: AppTheme.goldColor(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.apiKeyVerifying, style: GoogleFonts.cinzel(color: AppTheme.background)),
        backgroundColor: AppTheme.textSecondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }

    await _settings.setProviderId('anthropic');
    final provider = await _settings.getProvider();
    final ai = AIService(provider: provider, apiKey: key);
    final valid = await ai.validateKey();

    if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (valid) {
      await _settings.setApiKey(key);
      setState(() => _hasApiKey = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.apiKeyValid, style: GoogleFonts.cinzel(color: AppTheme.background)),
          backgroundColor: AppTheme.goldColor(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.apiKeyInvalid, style: GoogleFonts.cinzel(color: Colors.white)),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _openApiUrl() async {
    const url = 'https://console.anthropic.com/settings/keys';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  // Font size names from localizations
  String _getFontSizeName(AppLocalizations l, double size) {
    if (size == 0.8) return l.fontSmall;
    if (size == 1.0) return l.fontNormal;
    if (size == 1.2) return l.fontLarge;
    return l.fontXLarge;
  }





  Future<void> _exportBackup(AppLocalizations l) async {
    final success = await _backup.exportBackup();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          success ? l.backupExportSuccess : l.backupExportError,
          style: GoogleFonts.cinzel(color: AppTheme.background),
        ),
        backgroundColor: success ? AppTheme.neonGold : Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showImportInstructions(AppLocalizations l) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevatedColor(context),
        title: Text(l.backupImport,
            style: GoogleFonts.cinzel(color: AppTheme.goldColor(context))),
        content: Text(l.backupImportHowTo,
            style: GoogleFonts.crimsonText(color: AppTheme.textPrimaryColor(context), fontSize: 16, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.cinzel(color: AppTheme.goldColor(context))),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAutoBackup(bool value) async {
    setState(() => _autoBackupEnabled = value);
    await _backup.setAutoBackupEnabled(value);
    if (value) {
      await BackupWorkerScheduler.scheduleAutoBackup(frequency: _autoBackupFrequency);
    } else {
      await BackupWorkerScheduler.cancelAutoBackup();
    }
  }

  Future<void> _changeAutoBackupFrequency(String freq) async {
    setState(() => _autoBackupFrequency = freq);
    await _backup.setAutoBackupFrequency(freq);
    if (_autoBackupEnabled) {
      await BackupWorkerScheduler.scheduleAutoBackup(frequency: freq);
    }
  }

  Future<void> _pickAutoBackupTime(AppLocalizations l) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _autoBackupTime.hour, minute: _autoBackupTime.minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.neonGold,
            surface: AppTheme.surfaceElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _autoBackupTime = TimeOfDayValue(hour: picked.hour, minute: picked.minute));
    await _backup.setAutoBackupTime(picked.hour, picked.minute);
  }

  String _formatLastBackup(AppLocalizations l) {
    if (_lastAutoBackup == null) return l.backupNever;
    final dt = _lastAutoBackup!;
    final months = [
      l.january, l.february, l.march, l.april, l.may, l.june,
      l.july, l.august, l.september, l.october, l.november, l.december
    ];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}. ${months[dt.month - 1]} $hh:$mm';
  }

  Future<void> _toggleNotification(bool value, AppLocalizations l) async {
    if (value) {
      // Nejdřív vysvětli proč potřebujeme oprávnění
      final explain = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceElevatedColor(context),
          title: Text('🔔 ${l.notificationTitle}',
              style: GoogleFonts.cinzel(color: AppTheme.goldColor(context))),
          content: Text(
            l.notificationPermissionExplain,
            style: GoogleFonts.crimsonText(
                color: AppTheme.textPrimaryColor(context), fontSize: 16, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel,
                  style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor(context),
                  foregroundColor: AppTheme.background),
              child: Text(l.allow,
                  style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (explain != true) return;

      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l.notificationPermissionDeniedSettings,
                style: GoogleFonts.cinzel(color: AppTheme.background)),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ));
        }
        return;
      }
    }   setState(() => _notificationEnabled = value);
    await NotificationService.setEnabled(value);
    if (value) {
      final locale = Localizations.localeOf(context);
      await NotificationService.scheduleDailyVerseNotification(
        hour: _notificationHour,
        minute: _notificationMinute,
        czech: locale.languageCode == 'cs',
      );
    } else {
      await NotificationService.cancelVerseNotification();
    }
  }

  Future<void> _pickNotificationTime(AppLocalizations l) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notificationHour, minute: _notificationMinute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.neonGold,
            surface: AppTheme.surfaceElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _notificationHour = picked.hour;
      _notificationMinute = picked.minute;
    });
    await NotificationService.setTime(picked.hour, picked.minute);
    if (_notificationEnabled) {
      final locale = Localizations.localeOf(context);
      await NotificationService.scheduleDailyVerseNotification(
        hour: picked.hour,
        minute: picked.minute,
        czech: locale.languageCode == 'cs',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(context, '🔑  ${l.apiKey}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasApiKey ? AppTheme.goldColor(context).withValues(alpha: 0.4) : AppTheme.divider,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasApiKey)
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.goldColor(context), size: 16),
                        const SizedBox(width: 8),
                        Text(l.apiKeySet,
                            style: GoogleFonts.cinzel(color: AppTheme.goldColor(context), fontSize: 12)),
                      ],
                    ),
                  if (_hasApiKey) const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: !_apiKeyVisible,
                    style: GoogleFonts.crimsonText(color: AppTheme.textPrimaryColor(context), fontSize: 16),
                    decoration: InputDecoration(
                      hintText: l.apiKeyHint,
                      hintStyle: GoogleFonts.crimsonText(color: AppTheme.textSecondaryColor(context)),
                      filled: true,
                      fillColor: AppTheme.surfaceElevatedColor(context),
                      suffixIcon: IconButton(
                        icon: Icon(_apiKeyVisible ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textSecondaryColor(context)),
                        onPressed: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.dividerColor(context))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.dividerColor(context))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.goldColor(context))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveApiKey(l),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldColor(context),
                            foregroundColor: AppTheme.backgroundColorOf(context),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(l.save, style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _openApiUrl,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.dividerColor(context)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l.getKey,
                            style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context), fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevatedColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor(context)),
                    ),
                    child: Text(l.apiKeyPrice,
                        style: GoogleFonts.crimsonText(
                            color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.5),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 28),

            _buildSectionLabel(context, '🎨  ${l.themeTitle}'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor(context)),
              ),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: true,
                    groupValue: _isDarkTheme,
                    onChanged: (v) async {
                      setState(() => _isDarkTheme = true);
                      await _settings.setDarkTheme(true);
                      if (mounted) BibleDayApp.of(context)?.updateTheme(true);
                    },
                    activeColor: AppTheme.goldColor(context),
                    title: Text(l.themeDark,
                        style: GoogleFonts.crimsonText(
                            color: _isDarkTheme ? AppTheme.goldColor(context) : AppTheme.textPrimaryColor(context),
                            fontSize: 17)),
                    secondary: Icon(Icons.dark_mode_outlined, color: AppTheme.goldColor(context)),
                  ),
                  Divider(height: 1, color: AppTheme.dividerColor(context), indent: 16),
                  RadioListTile<bool>(
                    value: false,
                    groupValue: _isDarkTheme,
                    onChanged: (v) async {
                      setState(() => _isDarkTheme = false);
                      await _settings.setDarkTheme(false);
                      if (mounted) BibleDayApp.of(context)?.updateTheme(false);
                    },
                    activeColor: AppTheme.goldColor(context),
                    title: Text(l.themeLight,
                        style: GoogleFonts.crimsonText(
                            color: !_isDarkTheme ? AppTheme.goldColor(context) : AppTheme.textPrimaryColor(context),
                            fontSize: 17)),
                    secondary: Icon(Icons.light_mode_outlined, color: AppTheme.goldColor(context)),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 28),

            _buildSectionLabel(context, '🔤  ${l.fontSize}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor(context)),
              ),
              child: Column(
                children: SettingsService.fontSizes.asMap().entries.map((e) {
                  final i = e.key;
                  final fs = e.value;
                  final isLast = i == SettingsService.fontSizes.length - 1;
                  final size = fs['id'] as double;
                  return Column(
                    children: [
                      RadioListTile<double>(
                        value: size,
                        groupValue: _fontSize,
                        onChanged: (v) async {
                          setState(() => _fontSize = v!);
                          await _settings.setFontSize(v!);
                          if (mounted) BibleDayApp.of(context)?.updateFontSize(v);
                        },
                        activeColor: AppTheme.goldColor(context),
                        title: Text(
                          _getFontSizeName(l, size),
                          style: GoogleFonts.crimsonText(
                            color: _fontSize == size ? AppTheme.neonGold : AppTheme.textPrimary,
                            fontSize: 17 * size,
                          ),
                        ),
                      ),
                      if (!isLast) Divider(height: 1, color: AppTheme.dividerColor(context), indent: 16),
                    ],
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 28),

            _buildSectionLabel(context, '🤖  ${l.aiLanguage}'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor(context)),
              ),
              child: Column(
                children: [
                  for (final item in [
                    {'id': 'auto', 'label': l.aiLanguageAuto},
                    {'id': 'cs', 'label': l.aiLanguageCz},
                    {'id': 'en', 'label': l.aiLanguageEn},
                  ]) ...[
                    RadioListTile<String>(
                      value: item['id']!,
                      groupValue: _aiLanguage,
                      onChanged: (v) async {
                        setState(() => _aiLanguage = v!);
                        await _settings.setAiLanguage(v!);
                      },
                      activeColor: AppTheme.goldColor(context),
                      title: Text(item['label']!,
                          style: GoogleFonts.crimsonText(
                            color: _aiLanguage == item['id'] ? AppTheme.neonGold : AppTheme.textPrimary,
                            fontSize: 17,
                          )),
                    ),
                    if (item['id'] != 'en')
                      Divider(height: 1, color: AppTheme.dividerColor(context), indent: 16),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 210.ms),

            const SizedBox(height: 28),

            _buildSectionLabel(context, '📖  ${l.translation}'),
            const SizedBox(height: 12),
            ListTile(
              tileColor: AppTheme.surfaceColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Icon(Icons.menu_book_outlined, color: AppTheme.goldColor(context)),
              title: Text(l.translation,
                  style: GoogleFonts.cinzel(color: AppTheme.textPrimaryColor(context))),
              subtitle: Text(_translationId.toUpperCase(),
                  style: GoogleFonts.crimsonText(color: AppTheme.goldColor(context))),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: AppTheme.textSecondaryColor(context), size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TranslationsScreen()),
              ).then((_) => _load()),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 28),

            _buildSectionLabel(context, '🔔  ${l.notificationTitle}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _notificationEnabled
                      ? AppTheme.goldColor(context).withValues(alpha: 0.4)
                      : AppTheme.divider,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l.notificationVerseDaily,
                            style: GoogleFonts.cinzel(
                                color: AppTheme.textPrimaryColor(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                      Switch(
                        value: _notificationEnabled,
                        onChanged: (v) => _toggleNotification(v, l),
                        activeColor: AppTheme.goldColor(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(l.notificationDesc,
                      style: GoogleFonts.crimsonText(
                          color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.4)),
                  if (_notificationEnabled) ...[
                    const SizedBox(height: 16),
                    Divider(color: AppTheme.dividerColor(context), height: 1),
                    const SizedBox(height: 16),
                    Text(l.notificationTime,
                        style: GoogleFonts.cinzel(
                            color: AppTheme.textSecondaryColor(context), fontSize: 12)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickNotificationTime(l),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevatedColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_outlined,
                                color: AppTheme.goldColor(context), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '${_notificationHour.toString().padLeft(2, '0')}:${_notificationMinute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.cinzel(
                                  color: AppTheme.textPrimaryColor(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final locale = Localizations.localeOf(context);
                          await NotificationService.showVerseNotification(
                            czech: locale.languageCode == 'cs',
                          );
                        },
                        icon: Icon(Icons.notifications_active_outlined,
                            color: AppTheme.goldColor(context)),
                        label: Text('Otestovat notifikaci',
                            style: GoogleFonts.cinzel(color: AppTheme.goldColor(context))),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.goldColor(context)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final locale = Localizations.localeOf(context);
                          await NotificationService.showVerseNotification(
                            czech: locale.languageCode == 'cs',
                          );
                        },
                        icon: Icon(Icons.notifications_active_outlined,
                            color: AppTheme.goldColor(context)),
                        label: Text('Otestovat notifikaci',
                            style: GoogleFonts.cinzel(color: AppTheme.goldColor(context))),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.goldColor(context)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 240.ms),

            const SizedBox(height: 28),

            _buildSectionLabel(context, '💾  ${l.backupTitle}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.backupDesc,
                      style: GoogleFonts.crimsonText(
                          color: AppTheme.textSecondaryColor(context), fontSize: 14, height: 1.4)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _exportBackup(l),
                      icon: Icon(Icons.upload),
                      label: Text(l.backupExport,
                          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showImportInstructions(l),
                      icon: Icon(Icons.download, color: AppTheme.purpleColor(context)),
                      label: Text(l.backupImport,
                          style: GoogleFonts.cinzel(color: AppTheme.purpleColor(context), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.purpleColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 20),

            // Automatická záloha — hned pod ruční zálohou jako pojistka
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _autoBackupEnabled
                      ? AppTheme.goldColor(context).withValues(alpha: 0.4)
                      : AppTheme.divider,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l.autoBackupTitle,
                            style: GoogleFonts.cinzel(
                                color: AppTheme.textPrimaryColor(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                      Switch(
                        value: _autoBackupEnabled,
                        onChanged: _toggleAutoBackup,
                        activeThumbColor: AppTheme.neonGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(l.autoBackupDesc,
                      style: GoogleFonts.crimsonText(
                          color: AppTheme.textSecondaryColor(context), fontSize: 13, height: 1.4)),

                  if (_autoBackupEnabled) ...[
                    const SizedBox(height: 16),
                    Divider(color: AppTheme.dividerColor(context), height: 1),
                    const SizedBox(height: 16),

                    Text(l.autoBackupFrequency,
                        style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context), fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _FrequencyChip(
                            label: l.autoBackupDaily,
                            selected: _autoBackupFrequency == 'daily',
                            onTap: () => _changeAutoBackupFrequency('daily'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FrequencyChip(
                            label: l.autoBackupWeekly,
                            selected: _autoBackupFrequency == 'weekly',
                            onTap: () => _changeAutoBackupFrequency('weekly'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text(l.autoBackupTime,
                        style: GoogleFonts.cinzel(color: AppTheme.textSecondaryColor(context), fontSize: 12)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickAutoBackupTime(l),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevatedColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: AppTheme.goldColor(context), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '${_autoBackupTime.hour.toString().padLeft(2, '0')}:${_autoBackupTime.minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.cinzel(
                                  color: AppTheme.textPrimaryColor(context), fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(l.autoBackupTimeApprox,
                                style: GoogleFonts.crimsonText(
                                    color: AppTheme.textSecondaryColor(context), fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.history, color: AppTheme.textSecondaryColor(context), size: 14),
                        const SizedBox(width: 6),
                        Text('${l.autoBackupLast}: ${_formatLastBackup(l)}',
                            style: GoogleFonts.crimsonText(
                                color: AppTheme.textSecondaryColor(context), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(l.autoBackupLocation,
                        style: GoogleFonts.crimsonText(
                            color: AppTheme.textSecondaryColor(context), fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 270.ms),

            const SizedBox(height: 28),

            _buildSectionLabel(context, 'ℹ️  ${l.aboutApp}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor(context)),
              ),
              child: Column(
                children: [
                  _buildInfoRow(context, l.version, _version),
                  Divider(color: AppTheme.dividerColor(context), height: 24),
                  _buildInfoRow(context, l.bibleApi, 'bible-api.com'),
                  Divider(color: AppTheme.dividerColor(context), height: 24),
                  _buildInfoRow(context, l.madeBy, 'jack4xt'),
                  Divider(color: AppTheme.dividerColor(context), height: 24),
                  // Atribuce ČSP dle licenční smlouvy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l.cspAttribution,
                          style: GoogleFonts.cinzel(
                              color: AppTheme.textSecondaryColor(context),
                              fontSize: 12,
                              letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Český studijní překlad Bible (ČSP)',
                          style: GoogleFonts.cinzel(
                              color: AppTheme.textPrimaryColor(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('© Nadační fond překladu Bible',
                          style: GoogleFonts.crimsonText(
                              color: AppTheme.textPrimaryColor(context), fontSize: 14)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          final url = Uri.parse('https://biblecsp.cz');
                          if (await canLaunchUrl(url)) {
                            launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text('biblecsp.cz',
                            style: GoogleFonts.crimsonText(
                                color: AppTheme.goldColor(context),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppTheme.neonGold)),
                      ),
                    ],
                  ),
Divider(color: AppTheme.dividerColor(context), height: 24),
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () async {
      final url = Uri.parse('https://ko-fi.com/jack4xt');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    },
    icon: Icon(Icons.coffee, color: AppTheme.goldColor(context)),
    label: Text(l.supportDeveloper,
        style: GoogleFonts.cinzel(color: AppTheme.goldColor(context), fontSize: 13)),
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: AppTheme.goldColor(context)),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.goldColor(context), letterSpacing: 2));
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: GoogleFonts.cinzel(color: AppTheme.goldColor(context), fontSize: 13)),
      ],
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FrequencyChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.goldColor(context).withValues(alpha: 0.15) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.neonGold : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            color: selected ? AppTheme.neonGold : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
