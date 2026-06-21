import 'package:firebase_messaging/firebase_messaging.dart';

/// A normalised view over an FCM [RemoteMessage] — the only notification type
/// the rest of the app needs to know about.
///
/// Carries the display fields plus the free-form [data] payload your backend
/// sends, and a few convenience getters ([route], [id]) for navigation.
class PushMessage {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  /// How the user encountered this message — drives whether you navigate.
  final PushSource source;

  const PushMessage({
    this.title,
    this.body,
    this.data = const {},
    this.source = PushSource.foreground,
  });

  factory PushMessage.fromRemote(
    RemoteMessage message, {
    PushSource source = PushSource.foreground,
  }) {
    final n = message.notification;
    return PushMessage(
      title: n?.title ?? message.data['title'] as String?,
      body: n?.body ?? message.data['body'] as String?,
      data: Map<String, dynamic>.from(message.data),
      source: source,
    );
  }

  /// Deep-link target your backend put in the payload, e.g. `/consultation/42`.
  /// Reads `route`, falling back to `click_action` / `screen`.
  String? get route =>
      data['route'] as String? ??
      data['click_action'] as String? ??
      data['screen'] as String?;

  /// Optional entity id (appointment, chat, …) used to build the route.
  String? get id => data['id'] as String? ?? data['entity_id'] as String?;

  bool get hasNavigation => route != null;

  @override
  String toString() =>
      'PushMessage(title: $title, source: ${source.name}, data: $data)';
}

/// Where the [PushMessage] came from in the app lifecycle.
enum PushSource {
  /// Delivered while the app was open and focused.
  foreground,

  /// The user tapped a notification that woke the app from the background.
  background,

  /// The user tapped a notification that cold-started the app from terminated.
  terminated,

  /// Tapped from the OS tray via the local-notifications plugin.
  localTap,
}
