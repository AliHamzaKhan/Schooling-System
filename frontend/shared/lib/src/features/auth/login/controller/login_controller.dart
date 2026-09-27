import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../services/auth_service.dart';
import '../../../../services/data_store_service.dart';
import '../../auth_config.dart';
import '../../auth_routes.dart';
import '../../session_navigation.dart';
import '../../models/institution.dart';

/// Drives the shared login screen: institution selection, credentials, the
/// password visibility toggle, "remember me", and the login call.
class LoginController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final DataStoreService _store = Get.find<DataStoreService>();

  /// Field values. The `TextEditingController`s that feed these live on the
  /// login screen's State ([LoginView]), so they are disposed with the screen
  /// rather than with this GetX controller.
  final email = (kDebugMode ? 'student@ths.edu' : '').obs;
  final password = (kDebugMode ? 'Pass1234!' : '').obs;

  final institutions = <Institution>[].obs;
  final selectedInstitution = Rxn<Institution>();
  final loadingInstitutions = false.obs;

  final obscurePassword = true.obs;
  final rememberMe = false.obs;
  final submitting = false.obs;
  final error = RxnString();
  String? _returnTo;

  bool get requireInstitution => AuthConfig.requireInstitution;

  /// True when this platform can persist the password. False on web, where
  /// secure storage is unencrypted browser storage — the checkbox still works
  /// there, it just remembers the email only.
  bool get canRememberPassword => DataStoreService.canStorePassword;

  @override
  void onInit() {
    super.onInit();
    if (requireInstitution) _loadInstitutions();
    _restoreRemembered();
    _returnTo = Get.parameters['returnTo'];
  }

  /// Prefills saved credentials so a returning user can sign straight in.
  Future<void> _restoreRemembered() async {
    try {
    if (!_store.rememberMe) return;
    rememberMe.value = true;
    final savedEmail = _store.rememberedEmail;
    if (savedEmail != null && savedEmail.isNotEmpty) email.value = savedEmail;
    final savedPassword = await _store.readRememberedPassword();
    if (savedPassword != null && savedPassword.isNotEmpty) {
      password.value = savedPassword;
    }
    } catch (_) {
      error.value = 'Saved sign-in details are unavailable. You can enter them again.';
    }
  }

  Future<void> _loadInstitutions() async {
    final loader = AuthConfig.institutionsLoader;
    if (loader == null) return;
    loadingInstitutions.value = true;
    try {
      institutions.assignAll(await loader());
    } catch (_) {
      // Non-fatal — dropdown stays empty, login still possible.
    } finally {
      loadingInstitutions.value = false;
    }
  }

  void toggleObscure() => obscurePassword.toggle();
  void toggleRemember(bool? v) {
    rememberMe.value = v ?? false;
    // Forget straight away when unticked — waiting until the next successful
    // login would leave the old credentials on disk in the meantime.
    if (!rememberMe.value) {
      _store.clearRememberedCredentials().catchError((Object _) {
        error.value = 'Saved details could not be removed. Please retry.';
      });
    }
  }
  void selectInstitution(Institution? i) => selectedInstitution.value = i;

  void goToForgotPassword() => Get.toNamed(AuthRoutes.forgotPassword);

  Future<void> submit() async {
    if (submitting.value) return;
    error.value = null;
    final enteredEmail = email.value.trim();
    final enteredPassword = password.value.trim();

    if (requireInstitution && selectedInstitution.value == null) {
      error.value = 'Please select your institution.';
      return;
    }
    if (enteredEmail.isEmpty || enteredPassword.isEmpty) {
      error.value = 'Enter your email and password.';
      return;
    }

    submitting.value = true;
    try {
      final res =
          await _auth.login(email: enteredEmail, password: enteredPassword);
      if (res.success) {
        // Only persist once the backend has confirmed the pair is valid, so we
        // never store a wrong password.
        try {
        if (rememberMe.value) {
          await _store.saveRememberedCredentials(
              email: enteredEmail, password: enteredPassword);
        } else {
          await _store.clearRememberedCredentials();
        }
        } catch (_) {
          _auth.sessionNotice.value = 'Signed in, but remember-me preferences could not be saved.';
        }
        // Route by role when a resolver is configured; otherwise fall back to
        // the single configured home route.
        final resolved = SessionNavigation.destination(_auth.roleCodes, _returnTo);
        Get.offAllNamed(resolved);
      } else {
        error.value = res.error ?? 'Login failed. Check your credentials.';
      }
    } catch (e) {
      error.value = 'Something went wrong. Please try again.';
    } finally {
      submitting.value = false;
    }
  }
}
