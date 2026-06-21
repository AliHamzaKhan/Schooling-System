/// Null-safe coercion helpers for any JSON-ish value (String/num/bool/Map/List).
///
/// Backends are messy — fields can be missing, the wrong type, or a string
/// when you expected an int. These helpers always return a usable value
/// (the supplied default) rather than throwing.
class DataParserService {
  const DataParserService();

  // ── Primitives ──────────────────────────────────────────────
  String parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  String? parseStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? defaultValue;
    if (value is bool) return value ? 1 : 0;
    return defaultValue;
  }

  int? parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    return null;
  }

  double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  double? parseDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final s = value.toLowerCase().trim();
      if (['true', '1', 'yes', 'y', 'on'].contains(s)) return true;
      if (['false', '0', 'no', 'n', 'off', ''].contains(s)) return false;
    }
    return defaultValue;
  }

  // ── Collections ─────────────────────────────────────────────
  List<T> parseList<T>(dynamic value, T Function(dynamic) itemParser) {
    if (value is! List) return <T>[];
    return value.map(itemParser).toList();
  }

  Map<String, dynamic> parseMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  // ── Enums ───────────────────────────────────────────────────
  /// Maps a string to an enum value by name. Falls back to [defaultValue]
  /// when the string is null, empty, or doesn't match any enum value.
  T parseEnum<T extends Enum>(dynamic value, List<T> values, {required T defaultValue}) {
    if (value == null) return defaultValue;
    final s = value.toString().toLowerCase().trim();
    for (final e in values) {
      if (e.name.toLowerCase() == s) return e;
    }
    return defaultValue;
  }
}
