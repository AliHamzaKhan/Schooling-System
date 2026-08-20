// Driver module view-models: assignments, routes, and the active trip manifest.

class DriverAssignment {
  final String studentId;
  final String routeId;
  final String? address;
  final double? latitude;
  final double? longitude;

  const DriverAssignment({
    required this.studentId,
    required this.routeId,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory DriverAssignment.fromJson(Map<String, dynamic> j) => DriverAssignment(
        studentId: '${j['student_id']}',
        routeId: '${j['route_id']}',
        address: j['address'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
      );
}

class DriverRouteOption {
  final String id;
  final String name;

  const DriverRouteOption({required this.id, required this.name});

  factory DriverRouteOption.fromJson(Map<String, dynamic> j) =>
      DriverRouteOption(id: '${j['id']}', name: '${j['name'] ?? ''}');
}

class TripStudentEvent {
  final String studentId;
  final String status; // pending / boarded / absent / dropped

  const TripStudentEvent({required this.studentId, required this.status});

  factory TripStudentEvent.fromJson(Map<String, dynamic> j) => TripStudentEvent(
        studentId: '${j['student_id']}',
        status: '${j['status'] ?? 'pending'}',
      );
}

class DriverTrip {
  final String id;
  final String routeId;
  final String tripType; // pickup / dropoff
  final String status; // scheduled / in_progress / completed / cancelled
  final List<String> stopOrder;
  final String? nextStudentId;
  final List<TripStudentEvent> events;

  const DriverTrip({
    required this.id,
    required this.routeId,
    required this.tripType,
    required this.status,
    this.stopOrder = const [],
    this.nextStudentId,
    this.events = const [],
  });

  bool get inProgress => status == 'in_progress';

  String statusFor(String studentId) =>
      events.firstWhere(
        (e) => e.studentId == studentId,
        orElse: () => const TripStudentEvent(studentId: '', status: 'pending'),
      ).status;

  factory DriverTrip.fromJson(Map<String, dynamic> j) => DriverTrip(
        id: '${j['id']}',
        routeId: '${j['route_id']}',
        tripType: '${j['trip_type'] ?? ''}',
        status: '${j['status'] ?? ''}',
        stopOrder: (j['stop_order'] as List?)?.map((e) => '$e').toList() ??
            const [],
        nextStudentId: j['next_student_id'] as String?,
        events: (j['events'] as List?)
                ?.cast<Map<String, dynamic>>()
                .map(TripStudentEvent.fromJson)
                .toList() ??
            const [],
      );
}
