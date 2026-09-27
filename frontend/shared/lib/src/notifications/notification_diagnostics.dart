import 'package:flutter/foundation.dart';

import '../env/env_config.dart';

/// Fixed, content-free notification diagnostics.
///
/// Notification payloads, device tokens, topics and exception strings can all
/// identify a child or act as credentials. Callers therefore select an event
/// rather than interpolating runtime values into a diagnostic message.
enum NotificationDiagnosticEvent {
  tokenRetrieved,
  tokenRefreshed,
  foregroundMessageReceived,
  topicSubscriptionChanged,
  deviceRegistrationFailed,
  deviceReregistrationFailed,
  deviceUnregistrationFailed,
}

String notificationDiagnosticMessage(NotificationDiagnosticEvent event) =>
    switch (event) {
      NotificationDiagnosticEvent.tokenRetrieved => 'device token retrieved',
      NotificationDiagnosticEvent.tokenRefreshed => 'device token refreshed',
      NotificationDiagnosticEvent.foregroundMessageReceived =>
        'foreground message received',
      NotificationDiagnosticEvent.topicSubscriptionChanged =>
        'topic subscription changed',
      NotificationDiagnosticEvent.deviceRegistrationFailed =>
        'device registration failed',
      NotificationDiagnosticEvent.deviceReregistrationFailed =>
        'device re-registration failed',
      NotificationDiagnosticEvent.deviceUnregistrationFailed =>
        'device unregistration failed',
    };

void writeNotificationDiagnostic(NotificationDiagnosticEvent event) {
  if (EnvConfig.verboseLogging) {
    debugPrint('[NotificationService] ${notificationDiagnosticMessage(event)}');
  }
}
