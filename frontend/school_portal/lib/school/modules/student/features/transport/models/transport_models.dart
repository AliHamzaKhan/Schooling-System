// Student transport view-models: own pickup request + live-trip tracking.

class MyTransportRequest {
  final String id;
  final String studentId;
  final String pickupAddress;
  final String status; // pending / approved / rejected
  final String? rejectReason;

  const MyTransportRequest({
    required this.id,
    required this.studentId,
    required this.pickupAddress,
    required this.status,
    this.rejectReason,
  });

  factory MyTransportRequest.fromJson(Map<String, dynamic> j) =>
      MyTransportRequest(
        id: '${j['id']}',
        studentId: '${j['student_id']}',
        pickupAddress: '${j['pickup_address'] ?? ''}',
        status: '${j['status'] ?? 'pending'}',
        rejectReason: j['reject_reason'] as String?,
      );
}

class ActiveTrip {
  final String id;
  final String routeId;
  final String tripType; // pickup / dropoff
  final String status;
  final String? driverName;
  final String? driverPhone;

  const ActiveTrip({
    required this.id,
    required this.routeId,
    required this.tripType,
    required this.status,
    this.driverName,
    this.driverPhone,
  });

  factory ActiveTrip.fromJson(Map<String, dynamic> j) => ActiveTrip(
        id: '${j['id']}',
        routeId: '${j['route_id']}',
        tripType: '${j['trip_type'] ?? ''}',
        status: '${j['status'] ?? ''}',
        driverName: j['driver_name'] as String?,
        driverPhone: j['driver_phone'] as String?,
      );
}

class TripLocation {
  final double latitude;
  final double longitude;
  final String? address;

  const TripLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory TripLocation.fromJson(Map<String, dynamic> j) => TripLocation(
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        address: j['address'] as String?,
      );
}

class TripEta {
  final double? distanceM;
  final double? etaMinutes;

  const TripEta({this.distanceM, this.etaMinutes});

  factory TripEta.fromJson(Map<String, dynamic> j) => TripEta(
        distanceM: (j['distance_m'] as num?)?.toDouble(),
        etaMinutes: (j['eta_minutes'] as num?)?.toDouble(),
      );

  String get pretty {
    if (distanceM == null) return 'Waiting for location…';
    final km = distanceM! / 1000;
    final dist = km >= 1 ? '${km.toStringAsFixed(1)} km' : '${distanceM!.round()} m';
    final eta = etaMinutes == null ? '' : ' · ~${etaMinutes!.round()} min away';
    return '$dist$eta';
  }
}
