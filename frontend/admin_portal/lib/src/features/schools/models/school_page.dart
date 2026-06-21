import 'school.dart';

/// One page of paginated school results plus the total page count.
class SchoolPage {
  final List<School> schools;
  final int page;
  final int totalPages;

  const SchoolPage({
    required this.schools,
    required this.page,
    required this.totalPages,
  });
}
