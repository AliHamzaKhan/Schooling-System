/// Outcome of a biometric / device-credential authentication attempt.
///
/// A flat enum keeps call sites simple (`switch` on the result) while still
/// distinguishing the cases callers actually branch on — success, user
/// cancellation, hardware/enrolment gaps, and lock-outs.
enum BiometricResult {
  /// The user successfully authenticated.
  success,

  /// The user dismissed the prompt or failed too many quick attempts.
  cancelled,

  /// The device has no biometric hardware, or the platform reports it can't
  /// run the check right now.
  notAvailable,

  /// Hardware exists but the user hasn't enrolled a fingerprint / face, and
  /// (for [BiometricService.authenticate] with `biometricOnly: true`) there's
  /// no device passcode to fall back to.
  notEnrolled,

  /// Too many failed attempts — biometrics are temporarily or permanently
  /// locked. The user must unlock with the device passcode.
  lockedOut,

  /// The platform doesn't support biometrics at all (e.g. web/desktop) or an
  /// unexpected error occurred.
  unavailable,

  /// Any other platform error.
  error,
}

extension BiometricResultX on BiometricResult {
  bool get isSuccess => this == BiometricResult.success;

  /// A human-friendly message suitable for a snackbar / inline error.
  String get message => switch (this) {
        BiometricResult.success => 'Authenticated',
        BiometricResult.cancelled => 'Authentication cancelled',
        BiometricResult.notAvailable =>
          'Biometric authentication isn\'t available on this device',
        BiometricResult.notEnrolled =>
          'No fingerprint or face is enrolled. Add one in your device settings',
        BiometricResult.lockedOut =>
          'Too many attempts. Unlock with your device passcode and try again',
        BiometricResult.unavailable =>
          'Biometrics aren\'t supported on this platform',
        BiometricResult.error => 'Something went wrong. Please try again',
      };
}
