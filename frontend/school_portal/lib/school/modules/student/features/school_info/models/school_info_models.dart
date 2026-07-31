// Models for the School Info feature: the public school profile the student
// sees — about, achievements, uniform image, and contact details.

class SchoolAchievement {
  final String title;
  final String? description;
  final String? year;

  const SchoolAchievement({
    required this.title,
    this.description,
    this.year,
  });

  factory SchoolAchievement.fromJson(Map<String, dynamic> j) =>
      SchoolAchievement(
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        year: j['year'] as String?,
      );
}

class SchoolInfo {
  final String name;
  final String? address;
  final String? contactEmail;
  final String? contactPhone;
  final String? about;
  final List<SchoolAchievement> achievements;
  final String? uniformImageUrl;

  const SchoolInfo({
    required this.name,
    this.address,
    this.contactEmail,
    this.contactPhone,
    this.about,
    this.achievements = const [],
    this.uniformImageUrl,
  });

  factory SchoolInfo.fromJson(Map<String, dynamic> j) => SchoolInfo(
        name: j['name'] as String? ?? '',
        address: j['address'] as String?,
        contactEmail: j['contact_email'] as String?,
        contactPhone: j['contact_phone'] as String?,
        about: j['about'] as String?,
        achievements: ((j['achievements'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(SchoolAchievement.fromJson)
            .toList(),
        uniformImageUrl: j['uniform_image_url'] as String?,
      );
}
