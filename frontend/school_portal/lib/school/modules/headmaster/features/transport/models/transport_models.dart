// View-models for the Headmaster Transport screen (drivers, requests, fleet).

String _s(dynamic v) => v == null ? '' : '$v';

class DriverRow {
  final String id; // driver profile id
  final String userId; // login user id (used as driver_id on assignments/trips)
  final String fullName;
  final String email;
  final String? licenseNo;
  final String? phone;
  final String? assignedVehicleId;
  final String status;

  const DriverRow({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.licenseNo,
    this.phone,
    this.assignedVehicleId,
    this.status = 'active',
  });

  factory DriverRow.fromJson(Map<String, dynamic> j) => DriverRow(
        id: _s(j['id']),
        userId: _s(j['user_id']),
        fullName: _s(j['full_name']),
        email: _s(j['email']),
        licenseNo: j['license_no'] as String?,
        phone: j['phone'] as String?,
        assignedVehicleId: j['assigned_vehicle_id'] as String?,
        status: _s(j['status']).isEmpty ? 'active' : _s(j['status']),
      );
}

class OnlineDriver {
  final String driverId;
  final String fullName;
  final String? tripId;
  final bool online;

  const OnlineDriver({
    required this.driverId,
    required this.fullName,
    this.tripId,
    this.online = false,
  });

  factory OnlineDriver.fromJson(Map<String, dynamic> j) => OnlineDriver(
        driverId: _s(j['driver_id']),
        fullName: _s(j['full_name']),
        tripId: j['trip_id'] as String?,
        online: j['online'] == true,
      );
}

class TransportRequestRow {
  final String id;
  final String studentId;
  final String requestedBy;
  final String pickupAddress;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String status; // pending / approved / rejected
  final String? rejectReason;

  const TransportRequestRow({
    required this.id,
    required this.studentId,
    required this.requestedBy,
    required this.pickupAddress,
    this.latitude,
    this.longitude,
    this.notes,
    this.status = 'pending',
    this.rejectReason,
  });

  bool get isPending => status == 'pending';

  factory TransportRequestRow.fromJson(Map<String, dynamic> j) =>
      TransportRequestRow(
        id: _s(j['id']),
        studentId: _s(j['student_id']),
        requestedBy: _s(j['requested_by']),
        pickupAddress: _s(j['pickup_address']),
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        notes: j['notes'] as String?,
        status: _s(j['status']).isEmpty ? 'pending' : _s(j['status']),
        rejectReason: j['reject_reason'] as String?,
      );
}

class RouteOption {
  final String id;
  final String name;

  const RouteOption({required this.id, required this.name});

  factory RouteOption.fromJson(Map<String, dynamic> j) =>
      RouteOption(id: _s(j['id']), name: _s(j['name']));
}

class AssignmentRow {
  final String id;
  final String studentId;
  final String routeId;
  final String? driverId;
  final String? address;
  final String status;

  const AssignmentRow({
    required this.id,
    required this.studentId,
    required this.routeId,
    this.driverId,
    this.address,
    this.status = 'active',
  });

  factory AssignmentRow.fromJson(Map<String, dynamic> j) => AssignmentRow(
        id: _s(j['id']),
        studentId: _s(j['student_id']),
        routeId: _s(j['route_id']),
        driverId: j['driver_id'] as String?,
        address: j['address'] as String?,
        status: _s(j['status']).isEmpty ? 'active' : _s(j['status']),
      );
}

class TripRow {
  final String id;
  final String routeId;
  final String driverId;
  final String tripType;
  final String status;

  const TripRow({
    required this.id,
    required this.routeId,
    required this.driverId,
    required this.tripType,
    required this.status,
  });

  factory TripRow.fromJson(Map<String, dynamic> j) => TripRow(
        id: _s(j['id']),
        routeId: _s(j['route_id']),
        driverId: _s(j['driver_id']),
        tripType: _s(j['trip_type']),
        status: _s(j['status']),
      );
}
