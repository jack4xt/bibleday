import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _keyDailyReflection = 'cache_daily_reflection';
  static const String _keyDailyPrayer = 'cache_daily_prayer';
  static const String _keyDailyDate = 'cache_daily_date';
  static const String _keyStudyPrefix = 'cache_study_';

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  bool _isToday(String? dateKey) {
    if (dateKey == null) return false;
    return dateKey == _todayKey();
  }

  // Denní cache — verš/modlitba
  Future<String?> getDailyReflection() async {
    final prefs = await SharedPreferences.getInstance();
    final date = prefs.getString(_keyDailyDate);
    if (!_isToday(date)) return null;
    return prefs.getString(_keyDailyReflection);
  }

  Future<void> setDailyReflection(String reflection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDailyReflection, reflection);
    await prefs.setString(_keyDailyDate, _todayKey());
  }

  Future<String?> getDailyPrayer() async {
    final prefs = await SharedPreferences.getInstance();
    final date = prefs.getString(_keyDailyDate);
    if (!_isToday(date)) return null;
    return prefs.getString(_keyDailyPrayer);
  }

  Future<void> setDailyPrayer(String prayer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDailyPrayer, prayer);
    await prefs.setString(_keyDailyDate, _todayKey());
  }

  // Cache pro studium kapitoly
  Future<Map<String, String?>?> getStudy(String book, int chapter, String translation) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyStudyPrefix${book}_${chapter}_$translation';
    final context = prefs.getString('${key}_context');
    final keyVerses = prefs.getString('${key}_keyVerses');
    final questions = prefs.getString('${key}_questions');
    final application = prefs.getString('${key}_application');

    // Pokud nic není uloženo, vrať null
    if (context == null && keyVerses == null && questions == null && application == null) {
      return null;
    }

    return {
      'context': context,
      'keyVerses': keyVerses,
      'questions': questions,
      'application': application,
    };
  }

  Future<void> setStudy(String book, int chapter, String translation, {
    String? context,
    String? keyVerses,
    String? questions,
    String? application,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyStudyPrefix${book}_${chapter}_$translation';
    if (context != null) await prefs.setString('${key}_context', context);
    if (keyVerses != null) await prefs.setString('${key}_keyVerses', keyVerses);
    if (questions != null) await prefs.setString('${key}_questions', questions);
    if (application != null) await prefs.setString('${key}_application', application);
  }

  Future<void> clearDailyCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDailyReflection);
    await prefs.remove(_keyDailyPrayer);
    await prefs.remove(_keyDailyDate);
  }
}
