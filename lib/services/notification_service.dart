import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bible_service.dart';

class NotificationService {
  static const String _keyEnabled = 'notification_verse_enabled';
  static const String _keyHour = 'notification_verse_hour';
  static const String _keyMinute = 'notification_verse_minute';
  static const int _verseNotificationId = 1;
  static const String _channelKey = 'verse_of_day';

  /// Inicializace — volat při startu appky
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // použije výchozí ikonu aplikace
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
  }

  /// Požádej o oprávnění k notifikacím
  static Future<bool> requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (isAllowed) return true;

    final granted = await AwesomeNotifications().requestPermissionToSendNotifications();
    return granted;
  }

  /// Zobraz okamžitou testovací notifikaci
  static Future<void> showVerseNotification({required bool czech}) async {
    final verse = BibleService().getDailyVerseLocal(czech: czech);
    final title = czech ? '✝️ Verš dne' : '✝️ Verse of the day';
    final body = '"${verse.text}" — ${verse.reference}';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _verseNotificationId,
        channelKey: _channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigText,
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

    final verse = BibleService().getDailyVerseLocal(czech: czech);
    final title = czech ? '✝️ Verš dne' : '✝️ Verse of the day';
    final body = '"${verse.text}" — ${verse.reference}';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _verseNotificationId,
        channelKey: _channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigText,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        repeats: true,
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
