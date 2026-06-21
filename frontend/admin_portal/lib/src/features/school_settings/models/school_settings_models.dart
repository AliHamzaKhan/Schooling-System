import 'package:shared/shared.dart';

/// General configuration for a school. Plain value object edited on the School
/// Settings screen; persisted via [SchoolSettingsRepository].
class SchoolSettings {
  final String name;
  final String academicYear;
  final String timezone;
  final String gradingScale;
  final String contactEmail;
  final bool guardianRegistration; // allow guardians to self-register
  final bool publicResults; // results visible to guardians on publish
  final bool smsNotifications;

  const SchoolSettings({
    required this.name,
    required this.academicYear,
    required this.timezone,
    required this.gradingScale,
    required this.contactEmail,
    required this.guardianRegistration,
    required this.publicResults,
    required this.smsNotifications,
  });

  SchoolSettings copyWith({
    String? name,
    String? academicYear,
    String? timezone,
    String? gradingScale,
    String? contactEmail,
    bool? guardianRegistration,
    bool? publicResults,
    bool? smsNotifications,
  }) =>
      SchoolSettings(
        name: name ?? this.name,
        academicYear: academicYear ?? this.academicYear,
        timezone: timezone ?? this.timezone,
        gradingScale: gradingScale ?? this.gradingScale,
        contactEmail: contactEmail ?? this.contactEmail,
        guardianRegistration:
            guardianRegistration ?? this.guardianRegistration,
        publicResults: publicResults ?? this.publicResults,
        smsNotifications: smsNotifications ?? this.smsNotifications,
      );
}

class SchoolSettingsRepository {
  static const timezones = <String>[
    'GMT (UTC+0)',
    'EST (UTC-5)',
    'PST (UTC-8)',
    'CET (UTC+1)',
    'GST (UTC+4)',
    'PKT (UTC+5)',
  ];

  static const gradingScales = <String>[
    'Letter (A–F)',
    'Percentage (0–100)',
    'GPA (0–4.0)',
    'Points (0–10)',
  ];

  Future<ApiResponse<SchoolSettings>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(_mock);
  }

  Future<ApiResponse<void>> save(SchoolSettings settings) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return ApiResponse.ok(null);
  }

  static const _mock = SchoolSettings(
    name: 'Greenwood High',
    academicYear: '2025 / 2026',
    timezone: 'GST (UTC+4)',
    gradingScale: 'Letter (A–F)',
    contactEmail: 'admin@greenwood.edu',
    guardianRegistration: true,
    publicResults: false,
    smsNotifications: true,
  );
}
