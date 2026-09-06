import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible_service.dart';
import 'bible_database_service.dart';
import 'settings_service.dart';

class NotificationService {
  static const String _keyEnabled = 'notification_verse_enabled';
  static const String _keyHour = 'notification_verse_hour';
  static const String _keyMinute = 'notification_verse_minute';
  static const int _verseNotificationId = 1;
  static const String _channelKey = 'verse_of_day';

  /// Inicializace — volat při startu appky
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'Verš dne',
          channelDescription: 'Denní verš z Bible',
          defaultColor: const Color(0xFFFFD700),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
      debug: false,
    );

    // Handler pro klik na notifikaci — otevře appku
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Appka se otevře automaticky při kliknutí na notifikaci
  }

  /// Požádej o oprávnění k notifikacím
  static Future<bool> requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (isAllowed) return true;
    final granted = await AwesomeNotifications().requestPermissionToSendNotifications();
    return granted;
  }

  /// Načti dnešní verš z aktivního překladu
  static Future<String> _getTodayVerseText({required bool czech}) async {
    try {
      final settings = SettingsService();
      final translation = await settings.getTranslation();
      final bibleService = BibleService();
      final verse = await bibleService.getDailyVerseFromTranslation(translation);
      if (verse != null && verse.text.isNotEmpty) {
        return '"${verse.text}" — ${verse.reference}';
      }
    } catch (_) {}
    // Fallback
    final verse = BibleService().getDailyVerseLocal(czech: czech);
    return '"${verse.text}" — ${verse.reference}';
  }

  /// Zobraz okamžitou testovací notifikaci
  static Future<void> showVerseNotification({required bool czech}) async {
    final title = czech ? '✝️ Verš dne' : '✝️ Verse of the day';
    final body = await _getTodayVerseText(czech: czech);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _verseNotificationId,
        channelKey: _channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: true,
      ),
    );
  }

  /// Naplánuj denní notifikaci
  static Future<void> scheduleDailyVerseNotification({
    required int hour,
    required int minute,
    required bool czech,
  }) async {
    await cancelVerseNotification();

    final title = czech ? '✝️ Verš dne' : '✝️ Verse of the day';
    final body = await _getTodayVerseText(czech: czech);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _verseNotificationId,
        channelKey: _channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  static Future<void> cancelVerseNotification() async {
    await AwesomeNotifications().cancel(_verseNotificationId);
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
  }

  static Future<({int hour, int minute})> getTime() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      hour: prefs.getInt(_keyHour) ?? 8,
      minute: prefs.getInt(_keyMinute) ?? 0,
    );
  }

  static Future<void> setTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);
  }
}
