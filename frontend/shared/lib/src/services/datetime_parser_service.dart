/// Parsing + formatting helpers for dates and times.
///
/// Tolerant of multiple input shapes (ISO-8601, Unix seconds/ms, "yyyy-MM-dd",
/// "dd/MM/yyyy", DateTime instances). All output methods accept a DateTime
/// and return the requested string form.
class DateTimeParserService {
  const DateTimeParserService();

  // ── Parse ───────────────────────────────────────────────────
  /// Best-effort parser. Returns null when nothing matches.
  /// Accepts:
  /// - DateTime
  /// - ISO-8601 string ("2026-05-20T12:30:00Z")
  /// - Date-only string ("2026-05-20" or "20/05/2026" or "20-05-2026")
  /// - Unix epoch (seconds or milliseconds, int or numeric string)
  DateTime? parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    if (value is num) return _fromEpoch(value.toInt());

    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;

      // Numeric string → epoch
      final asInt = int.tryParse(s);
      if (asInt != null) return _fromEpoch(asInt);

      // ISO-8601
      final iso = DateTime.tryParse(s);
      if (iso != null) return iso;

      // dd/MM/yyyy or dd-MM-yyyy
      final dmYRegex = RegExp(r'^(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})$');
      final m = dmYRegex.firstMatch(s);
      if (m != null) {
        final day = int.parse(m.group(1)!);
        final month = int.parse(m.group(2)!);
        final year = int.parse(m.group(3)!);
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  DateTime _fromEpoch(int v) {
    // Distinguish seconds vs milliseconds by magnitude.
    if (v.abs() > 9999999999) {
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    return DateTime.fromMillisecondsSinceEpoch(v * 1000);
  }

  // ── Format ──────────────────────────────────────────────────
  /// ISO-8601 with UTC timezone — safe for sending to the API.
  String toIso(DateTime dt) => dt.toUtc().toIso8601String();

  /// Date only "2026-05-20".
  String toDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Time only "14:30".
  String toTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  /// Date + time "2026-05-20 14:30".
  String toDateTime(DateTime dt) => '${toDate(dt)} ${toTime(dt)}';

  /// Friendly "20 May 2026".
  String toFriendlyDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  /// "2 hours ago", "yesterday", "in 3 days" — relative to [reference] (default: now).
  String toRelative(DateTime dt, {DateTime? reference}) {
    final now = reference ?? DateTime.now();
    final diff = now.difference(dt);
    final absSec = diff.inSeconds.abs();
    final past = diff.inSeconds >= 0;

    String label;
    if (absSec < 60) {
      label = 'just now';
    } else if (absSec < 3600) {
      final m = (absSec / 60).floor();
      label = '$m minute${m == 1 ? '' : 's'}';
    } else if (absSec < 86400) {
      final h = (absSec / 3600).floor();
      label = '$h hour${h == 1 ? '' : 's'}';
    } else if (absSec < 604800) {
      final d = (absSec / 86400).floor();
      label = d == 1 ? (past ? 'yesterday' : 'tomorrow') : '$d days';
    } else if (absSec < 2592000) {
      final w = (absSec / 604800).floor();
      label = '$w week${w == 1 ? '' : 's'}';
    } else if (absSec < 31536000) {
      final mo = (absSec / 2592000).floor();
      label = '$mo month${mo == 1 ? '' : 's'}';
    } else {
      final y = (absSec / 31536000).floor();
      label = '$y year${y == 1 ? '' : 's'}';
    }

    if (label == 'just now' || label == 'yesterday' || label == 'tomorrow') {
      return label;
    }
    return past ? '$label ago' : 'in $label';
  }

  // ── Compute ─────────────────────────────────────────────────
  bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool isToday(DateTime dt, {DateTime? now}) => isSameDay(dt, now ?? DateTime.now());
  bool isPast(DateTime dt, {DateTime? now}) => dt.isBefore(now ?? DateTime.now());
  bool isFuture(DateTime dt, {DateTime? now}) => dt.isAfter(now ?? DateTime.now());

  /// Age in completed years from a date of birth.
  int ageInYears(DateTime dob, {DateTime? on}) {
    final ref = on ?? DateTime.now();
    var age = ref.year - dob.year;
    if (ref.month < dob.month || (ref.month == dob.month && ref.day < dob.day)) age--;
    return age;
  }
}
