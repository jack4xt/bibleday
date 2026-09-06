import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'bible_service.dart';

class NotificationService {
  static const String _keyEnabled = 'notification_verse_enabled';
  static const String _keyHour = 'notification_verse_hour';
  static const String _keyMinute = 'notification_verse_minute';
  static const int _verseNotificationId = 1;

  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
  }

  /// Zobraz okamžitou testovací notifikaci
  static Future<void> showVerseNotification({required bool czech}) async {
    final verse = BibleService().getDailyVerseLocal(czech: czech);
    final title = czech ? '✝️ Verš dne' : '✝️ Verse of the day';
    final body = '"${verse.text}" — ${verse.reference}';

    await _plugin.show(
      _verseNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'verse_of_day',
          czech ? 'Verš dne' : 'Verse of the day',
          channelDescription: czech ? 'Denní verš z Bible' : 'Daily Bible verse',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
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

    tz_data.initializeTimeZones();

    await _plugin.zonedSchedule(
      _verseNotificationId,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'verse_of_day',
          czech ? 'Verš dne' : 'Verse of the day',
          channelDescription: czech ? 'Denní verš z Bible' : 'Daily Bible verse',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelVerseNotification() async {
    await _plugin.cancel(_verseNotificationId);
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
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

  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;

      final areEnabled = await android.areNotificationsEnabled();
      if (areEnabled == true) return true;

      final granted = await android.requestNotificationsPermission();
      if (granted == true) return true;

      final enabledAfter = await android.areNotificationsEnabled();
      return enabledAfter == true;
    } catch (e) {
      return true;
    }
  }
}
