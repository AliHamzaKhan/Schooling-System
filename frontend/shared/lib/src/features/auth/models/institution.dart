/// A selectable school/institution for the login dropdown.
class Institution {
  final String id;
  final String name;

  const Institution({required this.id, required this.name});

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
        id: (json['id'] ?? json['code'] ?? '').toString(),
        name: (json['name'] ?? json['title'] ?? '').toString(),
      );

  @override
  bool operator ==(Object other) => other is Institution && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Signature for [AuthConfig.institutionsLoader].
typedef InstitutionLoader = Future<List<Institution>> Function();
