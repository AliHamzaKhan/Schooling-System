import 'package:permission_handler/permission_handler.dart';

/// Microphone permission helper for audio capture (e.g. consultation recording).
///
/// Wraps `permission_handler` so feature apps don't depend on the plugin
/// directly. Request [request] before starting any recording.
class MicPermission {
  const MicPermission._();

  /// Whether microphone permission is already granted.
  static Future<bool> isGranted() => Permission.microphone.isGranted;

  /// Prompt for microphone permission. Returns true when granted.
  static Future<bool> request() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// True when the user permanently denied access — the caller should send them
  /// to the system settings via [openSettings].
  static Future<bool> isPermanentlyDenied() =>
      Permission.microphone.isPermanentlyDenied;

  /// Open the OS app-settings screen so the user can grant the permission.
  static Future<bool> openSettings() => openAppSettings();
}
