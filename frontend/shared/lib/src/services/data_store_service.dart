import 'dart:convert';
import 'session/session_coordinator.dart';


import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CredentialStorageUnavailable implements Exception {}

/// Two-tier local persistence:
/// - **SharedPreferences** for general K/V (settings, cached JSON, profile blobs).
/// - **flutter_secure_storage** for secrets (auth tokens, refresh tokens, API keys).
///
/// Call [init] once during app bootstrap.
class DataStoreService {
  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _secure;
  late SharedPreferences _prefs;
  bool _ready = false;
  bool _blocked = false;
  static const _invalidatedKey = 'auth_invalidated';
  final SessionCoordinator coordinator = SessionCoordinator();

  /// Immediately stops this process using credentials, even if deletion fails.
  void blockCredentials() => _blocked = true;

  Future<bool> _credentialsBlocked() async {
    if (_blocked) return true;
    if (_ready) await _prefs.reload();
    return _ready && (_prefs.getBool(_invalidatedKey) ?? false);
  }

  Future<void> writeSession(String token, String refresh) async {
    _blocked = true;
    if (_ready && !await _prefs.setBool(_invalidatedKey, true)) {
      throw CredentialStorageUnavailable();
    }
    await writeToken(token);
    await writeRefreshToken(refresh);
    if (_ready && !await _prefs.setBool(_invalidatedKey, false)) {
      throw CredentialStorageUnavailable();
    }
    _blocked = false;
  }

  DataStoreService({FlutterSecureStorage? secure})
      : _secure = secure ?? const FlutterSecureStorage();

  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  void _assertReady() {
    if (!_ready) {
      throw StateError('DataStoreService.init() must be awaited before use.');
    }
  }

  // ── Token helpers (secure) ──────────────────────────────────
  Future<String?> readToken() async => await _credentialsBlocked() ? null : _secure.read(key: _tokenKey);
  Future<void> writeToken(String value) => _secure.write(key: _tokenKey, value: value);
  Future<void> deleteToken() => _secure.delete(key: _tokenKey);

  Future<String?> readRefreshToken() async => await _credentialsBlocked() ? null : _secure.read(key: _refreshKey);
  Future<void> writeRefreshToken(String value) => _secure.write(key: _refreshKey, value: value);
  Future<void> deleteRefreshToken() => _secure.delete(key: _refreshKey);

  Future<void> clearSecure() => _secure.deleteAll();

  // ── "Remember me" credentials ───────────────────────────────
  // Email is a preference; the password is a credential and lives in secure
  // storage (Keychain on iOS, EncryptedSharedPreferences on Android).
  //
  // The password is deliberately NEVER persisted on web: there,
  // FlutterSecureStorage falls back to unencrypted browser storage, so a saved
  // password would sit in plaintext and be readable by any XSS or by anyone
  // on a shared machine. On web we remember the email only — the refresh token
  // already keeps the user signed in, so the practical UX is the same.
  static const _rememberEmailKey = 'remember_email';
  static const _rememberFlagKey = 'remember_me';
  static const _rememberPasswordKey = 'remember_password';

  /// True when the password can be stored on this platform.
  static bool get canStorePassword => !kIsWeb;

  bool get rememberMe => read<bool>(_rememberFlagKey, defaultValue: false) ?? false;
  String? get rememberedEmail => read<String>(_rememberEmailKey);

  Future<String?> readRememberedPassword() async {
    if (!canStorePassword) return null;
    return _secure.read(key: _rememberPasswordKey);
  }

  /// Persists the credentials for prefill. Password is skipped on web.
  Future<void> saveRememberedCredentials({
    required String email,
    required String password,
  }) async {
    await write(_rememberFlagKey, true);
    await write(_rememberEmailKey, email);
    // An empty password means "nothing to keep" (web, or restoring after a
    // logout where none was stored) — don't write a blank entry.
    if (canStorePassword && password.isNotEmpty) {
      await _secure.write(key: _rememberPasswordKey, value: password);
    }
  }

  /// Forgets everything "remember me" saved.
  Future<void> clearRememberedCredentials() async {
    await write(_rememberFlagKey, false);
    await _prefs.remove(_rememberEmailKey);
    await _secure.delete(key: _rememberPasswordKey);
  }

  // ── Generic K/V (preferences) ───────────────────────────────
  /// Write any JSON-encodable value: String, num, bool, List, Map.
  Future<bool> write(String key, dynamic value) {
    _assertReady();
    if (value is String) return _prefs.setString(key, value);
    if (value is int) return _prefs.setInt(key, value);
    if (value is double) return _prefs.setDouble(key, value);
    if (value is bool) return _prefs.setBool(key, value);
    if (value is List<String>) return _prefs.setStringList(key, value);
    // Fallback — JSON-encode anything else.
    return _prefs.setString(key, jsonEncode(value));
  }

  /// Read a value. Pass [defaultValue] to get a fallback for missing keys.
  T? read<T>(String key, {T? defaultValue}) {
    _assertReady();
    final v = _prefs.get(key);
    if (v == null) return defaultValue;
    if (v is T) return v as T;
    // String stored via fallback path — try JSON-decode.
    if (v is String) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is T) return decoded;
        return defaultValue;
      } catch (_) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  bool contains(String key) {
    _assertReady();
    return _prefs.containsKey(key);
  }

  Future<bool> delete(String key) {
    _assertReady();
    return _prefs.remove(key);
  }

  Future<bool> clearPreferences() {
    _assertReady();
    return _prefs.clear();
  }

  /// Nuke both stores — use on full logout.
  /// Wipes the session. "Remember me" survives on purpose: logging out should
  /// bring you back to a login screen with your details prefilled, not force a
  /// full retype. Only unticking the checkbox clears them.
  Future<void> clearAll() async {
    _blocked = true;
    var failed = false;
    Future<void> attempt(Future<void> Function() action) async {
      try { await action(); } catch (_) { failed = true; }
    }
    // Persist a tombstone before deletion. A failed secure-store read must never
    // prevent deletion, and a failed deletion must not prevent the other one.
    if (_ready) {
      await attempt(() async {
        if (!await _prefs.setBool(_invalidatedKey, true)) {
          throw CredentialStorageUnavailable();
        }
      });
    }
    await attempt(deleteToken);
    await attempt(deleteRefreshToken);
    if (_ready) {
      for (final key in _prefs.getKeys().toList()) {
        if (key == _rememberFlagKey || key == _rememberEmailKey || key == _invalidatedKey) continue;
        await attempt(() async {
          if (!await _prefs.remove(key)) throw CredentialStorageUnavailable();
        });
      }
    }
    if (failed) throw CredentialStorageUnavailable();
  }
}
