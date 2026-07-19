/// Formats an amount as a plain grouped number — `20000` → `20,000`.
///
/// Salary figures across the HR/payroll screens are currency-symbol free: the
/// school's currency is implicit, and mixing a hardcoded `$` into a product
/// used outside the US was misleading.
String money(num value) {
  final rounded = value.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return negative ? '-$grouped' : grouped;
}
