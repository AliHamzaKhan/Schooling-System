import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import 'biometric_result.dart';

/// Fingerprint / Face / device-credential authentication, wrapped as a
/// reactive [GetxService] so both apps can share one instance.
///
/// Register once at boot:
/// ```dart
/// Get.put<BiometricService>(BiometricService(), permanent: true);
/// await Get.find<BiometricService>().refreshCapabilities();
/// ```
///
/// Then guard a flow:
/// ```dart
/// final result = await Get.find<BiometricService>().authenticate(
///   reason: 'Confirm it\'s you to view patient records',
/// );
/// if (result.isSuccess) { /* unlock */ }
/// ```
class BiometricService extends GetxService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? localAuth})
      : _auth = localAuth ?? LocalAuthentication();

  // ── Reactive capability state ───────────────────────────────
  /// True when the device has biometric hardware *and* the platform can run
  /// a check right now.
  final RxBool canUseBiometrics = false.obs;

  /// True when the OS exposes a passcode/PIN/pattern we can fall back to.
  final RxBool isDeviceSupported = false.obs;

  /// The concrete modalities enrolled on this device (face, fingerprint, …).
  final RxList<BiometricType> availableBiometrics = <BiometricType>[].obs;

  /// True while an authenticate() prompt is on screen.
  final RxBool isAuthenticating = false.obs;

  /// Convenience: does the device offer face unlock?
  bool get hasFace => availableBiometrics.contains(BiometricType.face);

  /// Convenience: does the device offer fingerprint unlock?
  bool get hasFingerprint =>
      availableBiometrics.contains(BiometricType.fingerprint) ||
      availableBiometrics.contains(BiometricType.strong) ||
      availableBiometrics.contains(BiometricType.weak);

  @override
  void onInit() {
    super.onInit();
    // Fire-and-forget; callers can also await refreshCapabilities() at boot.
    refreshCapabilities();
  }

  /// Re-query the platform for hardware support and enrolled biometrics.
  /// Safe to call after the user changes device settings (e.g. on resume).
  Future<void> refreshCapabilities() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      isDeviceSupported.value = supported;
      canUseBiometrics.value = supported && canCheck;
      availableBiometrics.value =
          canCheck ? await _auth.getAvailableBiometrics() : <BiometricType>[];
    } on PlatformException {
      isDeviceSupported.value = false;
      canUseBiometrics.value = false;
      availableBiometrics.clear();
    }
  }

  /// Prompt the user to authenticate.
  ///
  /// - [reason] is shown in the system dialog — make it specific.
  /// - [biometricOnly] hides the passcode fallback (set false to allow PIN).
  /// - [stickyAuth] keeps the prompt alive if the app is backgrounded mid-auth.
  Future<BiometricResult> authenticate({
    required String reason,
    bool biometricOnly = false,
    bool stickyAuth = true,
  }) async {
    if (isAuthenticating.value) return BiometricResult.cancelled;
    isAuthenticating.value = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: stickyAuth,
      );
      return ok ? BiometricResult.success : BiometricResult.cancelled;
    } on LocalAuthException catch (e) {
      return _mapError(e);
    } finally {
      isAuthenticating.value = false;
    }
  }

  /// Cancel an in-flight prompt (e.g. the user navigated away).
  Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } on PlatformException {
      // Nothing in flight — ignore.
    } finally {
      isAuthenticating.value = false;
    }
  }

  BiometricResult _mapError(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.userRequestedFallback:
        return BiometricResult.cancelled;
      case LocalAuthExceptionCode.noBiometricHardware:
        return BiometricResult.notAvailable;
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noCredentialsSet:
        return BiometricResult.notEnrolled;
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return BiometricResult.lockedOut;
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
      case LocalAuthExceptionCode.uiUnavailable:
        return BiometricResult.unavailable;
      default:
        return BiometricResult.error;
    }
  }
}
