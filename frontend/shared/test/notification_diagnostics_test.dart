import 'package:flutter_test/flutter_test.dart';
import 'package:shared/src/notifications/notification_diagnostics.dart';

void main() {
  test('notification diagnostics are fixed content-free event labels', () {
    final output = NotificationDiagnosticEvent.values
        .map(notificationDiagnosticMessage)
        .join('\n');

    for (final disallowed in ['token-value', 'student-name', 'password', 'Bearer ']) {
      expect(output, isNot(contains(disallowed)));
    }
    expect(output, contains('device token retrieved'));
    expect(output, contains('foreground message received'));
  });
}
