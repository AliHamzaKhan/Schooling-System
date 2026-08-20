import 'package:get/get.dart';
import 'package:shared/shared.dart';

import 'driver_endpoints.dart';
import 'driver_models.dart';

/// Live backend access for the Driver module. Every path is scoped to the
/// signed-in driver's school; trip actions are further scoped to the driver on
/// the backend.
class DriverApiService {
  final ApiService _api;
  DriverApiService({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  String get _sid => Get.find<AuthService>().schoolId ?? '';

  Future<ApiResponse<List<DriverAssignment>>> fetchMyAssignments() {
    return _api.request<List<DriverAssignment>>(
      method: HttpMethod.get,
      path: DriverEndpoints.myAssignments(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(DriverAssignment.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<List<DriverRouteOption>>> fetchRoutes() {
    return _api.request<List<DriverRouteOption>>(
      method: HttpMethod.get,
      path: DriverEndpoints.routes(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(DriverRouteOption.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<List<DriverTrip>>> fetchActiveTrips() {
    return _api.request<List<DriverTrip>>(
      method: HttpMethod.get,
      path: DriverEndpoints.tripsActive(_sid),
      parser: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(DriverTrip.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<DriverTrip>> startTrip({
    required String routeId,
    required String tripType,
  }) {
    return _api.request<DriverTrip>(
      method: HttpMethod.post,
      path: DriverEndpoints.tripsStart(_sid),
      body: {'route_id': routeId, 'trip_type': tripType},
      parser: (json) => DriverTrip.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<DriverTrip>> fetchTrip(String tripId) {
    return _api.request<DriverTrip>(
      method: HttpMethod.get,
      path: DriverEndpoints.trip(_sid, tripId),
      parser: (json) => DriverTrip.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<DriverTrip>> endTrip(String tripId) {
    return _api.request<DriverTrip>(
      method: HttpMethod.post,
      path: DriverEndpoints.tripEnd(_sid, tripId),
      parser: (json) => DriverTrip.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<DriverTrip>> updateStopOrder(
    String tripId,
    List<String> order,
  ) {
    return _api.request<DriverTrip>(
      method: HttpMethod.put,
      path: DriverEndpoints.tripStopOrder(_sid, tripId),
      body: {'stop_order': order},
      parser: (json) => DriverTrip.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<DriverTrip>> setStudentStatus({
    required String tripId,
    required String studentId,
    required String status,
    double? latitude,
    double? longitude,
  }) {
    return _api.request<DriverTrip>(
      method: HttpMethod.post,
      path: DriverEndpoints.tripStudentStatus(_sid, tripId, studentId),
      body: {
        'status': status,
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
      parser: (json) => DriverTrip.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> postLocation({
    required String tripId,
    required double latitude,
    required double longitude,
    String? address,
    double? speed,
    double? heading,
  }) {
    return _api.request<dynamic>(
      method: HttpMethod.post,
      path: DriverEndpoints.tripLocation(_sid, tripId),
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'address': ?address,
        'speed': ?speed,
        'heading': ?heading,
      },
      parser: (json) => json,
    );
  }
}
