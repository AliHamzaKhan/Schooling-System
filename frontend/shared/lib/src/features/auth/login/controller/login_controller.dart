import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/auth_service.dart';
import '../../../../services/data_store_service.dart';
import '../../auth_config.dart';
import '../../auth_routes.dart';
import '../../models/institution.dart';

/// Drives the shared login screen: institution selection, credentials, the
/// password visibility toggle, "remember me", and the login call.
class LoginController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final DataStoreService _store = Get.find<DataStoreService>();

  final emailCtrl = TextEditingController(text:kDebugMode ? 'student@ths.edu' : '');
  final passwordCtrl = TextEditingController(text:kDebugMode ? 'Pass1234!' : '');

  final institutions = <Institution>[].obs;
  final selectedInstitution = Rxn<Institution>();
  final loadingInstitutions = false.obs;

  final obscurePassword = true.obs;
  final rememberMe = false.obs;
  final submitting = false.obs;
  final error = RxnString();

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
  }

  /// Prefills saved credentials so a returning user can sign straight in.
  Future<void> _restoreRemembered() async {
    if (!_store.rememberMe) return;
    rememberMe.value = true;
    final email = _store.rememberedEmail;
    if (email != null && email.isNotEmpty) emailCtrl.text = email;
    final password = await _store.readRememberedPassword();
    if (password != null && password.isNotEmpty) passwordCtrl.text = password;
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
    if (!rememberMe.value) _store.clearRememberedCredentials();
  }
  void selectInstitution(Institution? i) => selectedInstitution.value = i;

  void goToForgotPassword() => Get.toNamed(AuthRoutes.forgotPassword);

  Future<void> submit() async {
    error.value = null;
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    if (requireInstitution && selectedInstitution.value == null) {
      error.value = 'Please select your institution.';
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      error.value = 'Enter your email and password.';
      return;
    }

    submitting.value = true;
    try {
      final res = await _auth.login(email: email, password: password);
      if (res.success) {
        // Only persist once the backend has confirmed the pair is valid, so we
        // never store a wrong password.
        if (rememberMe.value) {
          await _store.saveRememberedCredentials(
              email: email, password: password);
        } else {
          await _store.clearRememberedCredentials();
        }
        // Route by role when a resolver is configured; otherwise fall back to
        // the single configured home route.
        final resolved =
            AuthConfig.homeRouteResolver?.call(_auth.roleCodes) ??
                AuthConfig.homeRoute;
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

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
