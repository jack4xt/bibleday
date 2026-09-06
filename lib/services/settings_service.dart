import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse.dart';

class SettingsService {
  static const String _keyApiKey = 'api_key';
  static const String _keyProviderId = 'provider_id';
  static const String _keyTranslation = 'translation';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyReadingPlan = 'reading_plan';
  static const String _keyCurrentBook = 'current_book';
  static const String _keyCurrentChapter = 'current_chapter';
  static const String _keyFontSize = 'font_size';
  static const String _keyAiLanguage = 'ai_language'; // 'cs' | 'en' | 'auto'

  static const List<Map<String, String>> translations = [
    {'id': 'bkr', 'name': 'Kralická (BKR)', 'lang': 'cs'},
    {'id': 'cep', 'name': 'Ekumenická (CEP)', 'lang': 'cs'},
    {'id': 'kjv', 'name': 'King James (KJV)', 'lang': 'en'},
    {'id': 'web', 'name': 'World English (WEB)', 'lang': 'en'},
    {'id': 'niv', 'name': 'New International (NIV)', 'lang': 'en'},
  ];

  // Velikost písma: 0.8 = malé, 1.0 = normální, 1.2 = velké, 1.4 = velmi velké
  static const List<Map<String, dynamic>> fontSizes = [
    {'id': 0.8, 'name': 'Malé'},
    {'id': 1.0, 'name': 'Normální'},
    {'id': 1.2, 'name': 'Velké'},
    {'id': 1.4, 'name': 'Velmi velké'},
  ];

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, key);
  }

  Future<String> getProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProviderId) ?? 'anthropic';
  }

  Future<void> setProviderId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProviderId, id);
  }

  Future<AIProvider> getProvider() async {
    final id = await getProviderId();
    return AIProvider.available.firstWhere(
      (p) => p.id == id,
      orElse: () => AIProvider.available.first,
    );
  }

  Future<String> getTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTranslation) ?? 'kjv';
  }

  Future<void> setTranslation(String translation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTranslation, translation);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<void> setCurrentChapter(String book, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentBook, book);
    await prefs.setInt(_keyCurrentChapter, chapter);
  }

  Future<Map<String, dynamic>> getCurrentChapter() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'book': prefs.getString(_keyCurrentBook) ?? 'John',
      'chapter': prefs.getInt(_keyCurrentChapter) ?? 1,
    };
  }

  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontSize) ?? 1.0;
  }

  Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, size);
  }

  /// Vrací nastavený jazyk AI: 'cs', 'en', nebo 'auto' (podle překladu Bible).
  Future<String> getAiLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAiLanguage) ?? 'auto';
  }

  Future<void> setAiLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiLanguage, lang);
  }

  /// Vyřeší skutečný jazyk pro AI — bere v úvahu nastavení jazyka AI a překlad Bible.
  Future<String> resolveAiLanguage() async {
    final aiLang = await getAiLanguage();
    if (aiLang == 'cs') return 'cs';
    if (aiLang == 'en') return 'en';
    // 'auto' — podle překladu Bible
    final translation = await getTranslation();
    return (translation == 'bkr' || translation == 'cep') ? 'cs' : 'en';
  }

  static const String _keyTheme = 'app_theme';

  Future<bool> isDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTheme) ?? true;
  }

  Future<void> setDarkTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTheme, dark);
  }
}
