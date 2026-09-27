import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'notification_api.dart';
import 'notification_config.dart';
import 'notification_diagnostics.dart';
import 'push_message.dart';

/// Top-level FCM background handler.
///
/// **Must** be a top-level / static function annotated with
/// `@pragma('vm:entry-point')` — it runs in a separate isolate, so it can't
/// touch your service singletons. Register it from `main()` *before*
/// `runApp` (the service does this for you in [NotificationService.init]):
///
/// ```dart
/// FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
/// ```
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The isolate is fresh — Firebase must be (re)initialised before any use.
  await Firebase.initializeApp();
  // Data-only messages can be processed here (analytics, pre-fetch, etc.).
  // Notification messages are auto-displayed by the OS in the background.
}

/// Centralised Firebase Cloud Messaging service.
///
/// One place for: permission requests, the device token (+ refresh), topic
/// subscriptions, foreground re-display via local notifications, and a single
/// [onMessageTap] stream that fires whenever the user taps a notification —
/// from foreground, background, terminated start, or the local tray.
///
/// Boot order:
/// ```dart
/// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
/// final notes = NotificationService();
/// await notes.init();
/// Get.put<NotificationService>(notes, permanent: true);
///
/// // Navigate on tap (wire to your router):
/// notes.onMessageTap.listen((m) {
///   if (m.route != null) Get.toNamed(m.route!, arguments: m.data);
/// });
/// ```
class NotificationService extends GetxService {
  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _local;
  NotificationConfig _config;

  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    NotificationConfig config = const NotificationConfig(),
  })  : _fcm = messaging ?? FirebaseMessaging.instance,
        _local = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _config = config;

  // ── Reactive state ──────────────────────────────────────────
  /// The current FCM device token (null until [init] resolves it).
  final Rxn<String> token = Rxn<String>();

  /// Whether the user has granted notification permission.
  final RxBool isAuthorized = false.obs;

  /// The last message received in the foreground (handy for in-app banners).
  final Rxn<PushMessage> lastMessage = Rxn<PushMessage>();

  final _tapController = StreamController<PushMessage>.broadcast();

  /// Fires every time the user *taps* a notification, regardless of app state.
  /// This is your single navigation entry point.
  Stream<PushMessage> get onMessageTap => _tapController.stream;

  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _initialised = false;

  /// Initialise messaging, local notifications, permissions and all listeners.
  /// Assumes `Firebase.initializeApp()` has already run. Idempotent.
  Future<void> init({NotificationConfig? config}) async {
    if (_initialised) return;
    if (config != null) _config = config;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();
    await requestPermission();

    // iOS: show heads-up banners while the app is foregrounded.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Token + refresh.
    token.value = await _fcm.getToken();
    writeNotificationDiagnostic(NotificationDiagnosticEvent.tokenRetrieved);
    _subscriptions.add(_fcm.onTokenRefresh.listen((t) {
      token.value = t;
      writeNotificationDiagnostic(NotificationDiagnosticEvent.tokenRefreshed);
    }));

    // Foreground messages → re-raise as a local notification + expose state.
    _subscriptions.add(FirebaseMessaging.onMessage.listen((m) {
      final msg = PushMessage.fromRemote(m, source: PushSource.foreground);
      lastMessage.value = msg;
      writeNotificationDiagnostic(
        NotificationDiagnosticEvent.foregroundMessageReceived,
      );
      _showLocal(m);
    }));

    // Tapped while app was backgrounded.
    _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen((m) {
      _tapController.add(
        PushMessage.fromRemote(m, source: PushSource.background),
      );
    }));

    // Tapped to cold-start from terminated.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Defer so listeners attached right after init() still receive it.
      scheduleMicrotask(() => _tapController.add(
            PushMessage.fromRemote(initial, source: PushSource.terminated),
          ));
    }

    _initialised = true;
  }

  Future<void> _initLocalNotifications() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
          _tapController.add(
            PushMessage(data: data, source: PushSource.localTap),
          );
        } catch (_) {/* malformed payload — ignore */}
      },
    );

    // Create the Android channel up-front so high-importance heads-up works.
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_config.androidChannel);
  }

  void _showLocal(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title ?? message.data['title'] as String?;
    final body = n?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return; // nothing to display

    final channel = _config.androidChannel;
    _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: _config.importance,
          priority: Priority.high,
          icon: _config.androidNotificationIcon,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Permissions ─────────────────────────────────────────────
  /// Request notification permission (no-op grant on Android < 13).
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    isAuthorized.value =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    return isAuthorized.value;
  }

  // ── Topics ──────────────────────────────────────────────────
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    writeNotificationDiagnostic(
      NotificationDiagnosticEvent.topicSubscriptionChanged,
    );
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    writeNotificationDiagnostic(
      NotificationDiagnosticEvent.topicSubscriptionChanged,
    );
  }

  /// Subscribe to several topics at once (e.g. role + per-user).
  Future<void> subscribeToTopics(Iterable<String> topics) =>
      Future.wait(topics.map(subscribeToTopic));

  // ── Token helpers ───────────────────────────────────────────
  /// Force-refresh the token (e.g. after login, to register it server-side).
  Future<String?> refreshToken() async {
    token.value = await _fcm.getToken();
    return token.value;
  }

  /// Delete the token on logout so this device stops receiving the user's pushes.
  Future<void> deleteToken() async {
    await _fcm.deleteToken();
    token.value = null;
  }

  // ── Backend registration ────────────────────────────────────
  StreamSubscription<String?>? _syncSub;
  String _syncPlatform = 'android';

  /// Upload the current FCM token to the backend (via [api]) and keep it in sync
  /// on refresh. Call **after login**, once [ApiService] has the auth token.
  /// Safe to call repeatedly. [platform] is one of android|ios|web.
  Future<void> syncTokenWith(NotificationApi api, {String platform = 'android'}) async {
    _syncPlatform = platform;
    final current = token.value ?? await refreshToken();
    if (current != null && current.isNotEmpty) {
      try {
        await api.registerDevice(token: current, platform: platform);
      } catch (_) {
        writeNotificationDiagnostic(
          NotificationDiagnosticEvent.deviceRegistrationFailed,
        );
      }
    }
    // Re-register whenever FCM rotates the token.
    _syncSub ??= token.listen((t) async {
      if (t == null || t.isEmpty) return;
      try {
        await api.registerDevice(token: t, platform: _syncPlatform);
      } catch (_) {
        writeNotificationDiagnostic(
          NotificationDiagnosticEvent.deviceReregistrationFailed,
        );
      }
    });
  }

  /// Unregister this device server-side and stop syncing (call on logout).
  Future<void> unsyncToken(NotificationApi api) async {
    final current = token.value;
    await _syncSub?.cancel();
    _syncSub = null;
    if (current != null && current.isNotEmpty) {
      try {
        await api.unregisterDevice(current);
      } catch (_) {
        writeNotificationDiagnostic(
          NotificationDiagnosticEvent.deviceUnregistrationFailed,
        );
      }
    }
  }

  @override
  void onClose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _syncSub?.cancel();
    _tapController.close();
    super.onClose();
  }
}
