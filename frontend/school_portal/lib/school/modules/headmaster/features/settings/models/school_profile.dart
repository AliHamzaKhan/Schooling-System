/// The editable school profile + branding settings shown on the Settings
/// screen. Branding fields live inside the backend school `settings` JSON blob.
class SchoolProfile {
  final String id;
  final String name;
  final String code;
  final String? logoUrl;
  final String? uniformColor; // hex string, e.g. "#1565C0"
  final int? feeDueDay; // day of month monthly fees are due (1–31)

  const SchoolProfile({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl,
    this.uniformColor,
    this.feeDueDay,
  });

  factory SchoolProfile.fromJson(Map<String, dynamic> json) {
    final settings = (json['settings'] as Map?)?.cast<String, dynamic>() ?? {};
    return SchoolProfile(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      logoUrl: settings['logo_url'] as String?,
      uniformColor: settings['uniform_color'] as String?,
      feeDueDay: (settings['fee_due_day'] as num?)?.toInt(),
    );
  }
}
