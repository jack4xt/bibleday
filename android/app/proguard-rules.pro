# Flutter local notifications (starý balíček - zachovat pro jistotu)
-keep class com.dexterous.** { *; }

# Awesome Notifications
-keep class me.carda.awesome_notifications.** { *; }
-keep class me.carda.awesomeNotifications.** { *; }
-dontwarn me.carda.**

# SQLite / sqflite
-keep class io.flutter.plugins.** { *; }

# Keep all notification related classes
-keep class * extends android.app.Service { *; }
-keep class * extends android.content.BroadcastReceiver { *; }

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
