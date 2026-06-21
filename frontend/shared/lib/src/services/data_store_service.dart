import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<String?> readToken() => _secure.read(key: _tokenKey);
  Future<void> writeToken(String value) => _secure.write(key: _tokenKey, value: value);
  Future<void> deleteToken() => _secure.delete(key: _tokenKey);

  Future<String?> readRefreshToken() => _secure.read(key: _refreshKey);
  Future<void> writeRefreshToken(String value) => _secure.write(key: _refreshKey, value: value);
  Future<void> deleteRefreshToken() => _secure.delete(key: _refreshKey);

  Future<void> clearSecure() => _secure.deleteAll();

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
  Future<void> clearAll() async {
    await clearSecure();
    if (_ready) await clearPreferences();
  }
}
