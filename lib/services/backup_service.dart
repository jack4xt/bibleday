import 'dart:convert';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// Jednoduchá, spolehlivá záloha BibleDay dat.
/// Exportuje POUZE strukturovaná, smysluplná data — žádný cache obsah
/// vygenerovaný AI (ten se po reinstalaci jednoduše znovu vygeneruje).
class BackupService {
  static const String _appKey = 'BibleDay';
  static const int _backupVersion = 2;
  static const int _maxAutoBackups = 3;

  static const String _keyAutoEnabled = 'auto_backup_enabled';
  static const String _keyAutoFrequency = 'auto_backup_frequency'; // 'daily' | 'weekly'
  static const String _keyAutoHour = 'auto_backup_hour';
  static const String _keyAutoMinute = 'auto_backup_minute';
  static const String _keyLastAutoBackup = 'auto_backup_last_run';

  Future<Map<String, dynamic>> _collectData() async {
    final prefs = await SharedPreferences.getInstance();

    final apiKey = prefs.getString('api_key');
    final providerId = prefs.getString('provider_id');
    final translation = prefs.getString('translation');
    final fontSize = prefs.getDouble('font_size');
    final onboardingDone = prefs.getBool('onboarding_done');

    final planType = prefs.getString('reading_plan_type');
    final planStartDate = prefs.getString('reading_plan_start_date');
    final planCustomBook = prefs.getString('reading_plan_custom_book');
    final planChaptersPerDay = prefs.getInt('reading_plan_custom_chapters');
    final planCompleted = prefs.getStringList('reading_plan_completed') ?? [];

    final notes = prefs.getStringList('notes') ?? [];
    final bookmarks = prefs.getStringList('bookmarks') ?? [];

    return {
      'app': _appKey,
      'version': _backupVersion,
      'created': DateTime.now().toIso8601String(),
      'settings': {
        'apiKey': apiKey,
        'providerId': providerId,
        'translation': translation,
        'fontSize': fontSize,
        'onboardingDone': onboardingDone,
      },
      'readingPlan': {
        'type': planType,
        'startDate': planStartDate,
        'customBook': planCustomBook,
        'chaptersPerDay': planChaptersPerDay,
        'completed': planCompleted,
      },
      'notes': notes,
      'bookmarks': bookmarks,
    };
  }

  String _filenameFor(DateTime now) {
    final time =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'bibleday_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$time.json';
  }

  /// Ruční export — otevře systémové sdílení, uživatel zvolí kam uložit.
  Future<bool> exportBackup() async {
    try {
      final backup = await _collectData();
      final json = const JsonEncoder.withIndent('  ').convert(backup);
      final filename = _filenameFor(DateTime.now());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], subject: 'BibleDay backup');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Automatický export — ukládá přímo do pevné složky na úložišti,
  /// bez dialogu (běží na pozadí). Udržuje max. _maxAutoBackups souborů.
  Future<bool> runAutoBackup() async {
    try {
      final dir = await _autoBackupDir();
      if (dir == null) return false;

      final backup = await _collectData();
      final json = const JsonEncoder.withIndent('  ').convert(backup);
      final filename = _filenameFor(DateTime.now());
      final file = File('${dir.path}/$filename');
      await file.writeAsString(json);

      await _pruneOldBackups(dir);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastAutoBackup, DateTime.now().toIso8601String());

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Directory?> _autoBackupDir() async {
    try {
      // Použij složku specifickou pro appku na externím úložišti
      // — funguje na všech zařízeních bez ohledu na jazyk systému
      final base = await getExternalStorageDirectory();
      if (base != null) {
        final dir = Directory('${base.path}/AutoBackup');
        if (!dir.existsSync()) dir.createSync(recursive: true);
        return dir;
      }
    } catch (_) {}

    // Fallback na interní úložiště appky
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/AutoBackup');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pruneOldBackups(Directory dir) async {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('bibleday_backup_'))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    if (files.length > _maxAutoBackups) {
      for (final f in files.skip(_maxAutoBackups)) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }

  // --- Nastavení automatické zálohy ---

  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoEnabled) ?? false;
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoEnabled, enabled);
  }

  /// 'daily' nebo 'weekly'
  Future<String> getAutoBackupFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAutoFrequency) ?? 'daily';
  }

  Future<void> setAutoBackupFrequency(String freq) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAutoFrequency, freq);
  }

  Future<TimeOfDayValue> getAutoBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_keyAutoHour) ?? 8;
    final minute = prefs.getInt(_keyAutoMinute) ?? 0;
    return TimeOfDayValue(hour: hour, minute: minute);
  }

  Future<void> setAutoBackupTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoHour, hour);
    await prefs.setInt(_keyAutoMinute, minute);
  }

  Future<DateTime?> getLastAutoBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_keyLastAutoBackup);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  // --- Import ---

  Future<bool> importFromPath(String path) async {
    try {
      final content = await File(path).readAsString();
      return await importFromJson(content);
    } catch (e) {
      return false;
    }
  }

  Future<bool> importFromJson(String content) async {
    try {
      final backup = jsonDecode(content) as Map<String, dynamic>;
      if (backup['app'] != _appKey) return false;

      final prefs = await SharedPreferences.getInstance();

      final settings = backup['settings'] as Map<String, dynamic>?;
      if (settings != null) {
        if (settings['apiKey'] != null) {
          await prefs.setString('api_key', settings['apiKey']);
        }
        if (settings['providerId'] != null) {
          await prefs.setString('provider_id', settings['providerId']);
        }
        if (settings['translation'] != null) {
          await prefs.setString('translation', settings['translation']);
        }
        if (settings['fontSize'] != null) {
          await prefs.setDouble('font_size', (settings['fontSize'] as num).toDouble());
        }
        if (settings['onboardingDone'] != null) {
          await prefs.setBool('onboarding_done', settings['onboardingDone']);
        }
      }

      final plan = backup['readingPlan'] as Map<String, dynamic>?;
      if (plan != null && plan['type'] != null) {
        await prefs.setString('reading_plan_type', plan['type']);
        if (plan['startDate'] != null) {
          await prefs.setString('reading_plan_start_date', plan['startDate']);
        }
        if (plan['customBook'] != null) {
          await prefs.setString('reading_plan_custom_book', plan['customBook']);
        }
        if (plan['chaptersPerDay'] != null) {
          await prefs.setInt('reading_plan_custom_chapters', plan['chaptersPerDay']);
        }
        if (plan['completed'] != null) {
          await prefs.setStringList(
            'reading_plan_completed',
            (plan['completed'] as List).cast<String>(),
          );
        }
      }

      if (backup['notes'] != null) {
        await prefs.setStringList('notes', (backup['notes'] as List).cast<String>());
      }

      if (backup['bookmarks'] != null) {
        await prefs.setStringList('bookmarks', (backup['bookmarks'] as List).cast<String>());
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

class TimeOfDayValue {
  final int hour;
  final int minute;
  const TimeOfDayValue({required this.hour, required this.minute});
}
