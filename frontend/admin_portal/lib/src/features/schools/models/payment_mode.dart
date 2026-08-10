/// How a school pays us for their subscription. Stored per school in the
/// backend `settings.billing` blob so the admin remembers the arrangement.
///
/// Shape stored: `{ method, bank_name, account_title, account_number, notes }`.
class PaymentMode {
  PaymentMode._();

  /// Method code → human label. The code is what we persist.
  static const methods = <String, String>{
    'bank_transfer': 'Bank Transfer',
    'cash': 'Cash',
    'cheque': 'Cheque',
    'online': 'Online',
    'other': 'Other',
  };

  static List<String> get methodCodes => methods.keys.toList();

  static String label(String? code) =>
      code == null ? '—' : (methods[code] ?? code);

  /// Whether a method typically needs bank account details captured.
  static bool needsBankDetails(String? code) =>
      code == 'bank_transfer' || code == 'cheque' || code == 'online';
}
