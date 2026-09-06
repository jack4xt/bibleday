# Flutter local notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }

# Keep all notification related classes
-keep class * extends android.app.Service { *; }
-keep class * extends android.content.BroadcastReceiver { *; }
