/// Small pure helpers used across modules. Keep this file dependency-free
/// (no Flutter / GetX imports) so it stays cheap to unit-test.
class Formatters {
  Formatters._();

  /// Format an integer with thousand separators: `1248 → "1,248"`.
  static String compactInt(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return n < 0 ? '-$buf' : buf.toString();
  }

  /// `1200 → "$1,200"`. Always 0 decimals — used for currency badges.
  static String currency(num amount, {String symbol = '\$'}) =>
      '$symbol${compactInt(amount.round())}';

  /// Up-to-two-letter initials extracted from a person's name. Strips common
  /// titles ("Dr.", "Mr.", "Mrs.", "Ms.") before computing the initials.
  static String initials(String name) {
    final cleaned = name.replaceAll(RegExp(r'^(Dr|Mr|Mrs|Ms)\.?\s+'), '').trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
