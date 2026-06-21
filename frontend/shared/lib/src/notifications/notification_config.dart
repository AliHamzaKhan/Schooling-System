import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Configuration for the local-notification channel used to surface FCM
/// messages while the app is in the **foreground** (Android won't auto-display
/// data/notification messages when the app is open — we re-raise them locally).
///
/// Override per app by passing a custom instance to
/// [NotificationService.init].
class NotificationConfig {
  /// Android channel id — keep stable across releases.
  final String androidChannelId;
  final String androidChannelName;
  final String androidChannelDescription;

  /// Drawable used as the small status-bar icon (Android). Must exist in
  /// `android/app/src/main/res/drawable*`. `@mipmap/ic_launcher` works as a
  /// fallback during development.
  final String androidNotificationIcon;
  final Importance importance;

  const NotificationConfig({
    this.androidChannelId = 'high_importance_channel',
    this.androidChannelName = 'General Notifications',
    this.androidChannelDescription =
        'Appointment reminders, messages and updates.',
    this.androidNotificationIcon = '@mipmap/ic_launcher',
    this.importance = Importance.high,
  });

  AndroidNotificationChannel get androidChannel => AndroidNotificationChannel(
        androidChannelId,
        androidChannelName,
        description: androidChannelDescription,
        importance: importance,
      );
}

/// Topic names both apps may subscribe to. Centralised so the doctor and
/// patient apps stay in sync and there are no stringly-typed typos.
class NotificationTopics {
  NotificationTopics._();

  static const String all = 'all_users';
  static const String doctors = 'doctors';
  static const String patients = 'patients';
  static const String announcements = 'announcements';

  /// Per-user topic, e.g. `user_42` — handy for server-side fan-out.
  static String user(String userId) => 'user_$userId';
}
