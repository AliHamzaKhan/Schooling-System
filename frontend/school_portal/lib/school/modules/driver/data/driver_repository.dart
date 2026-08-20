import 'package:shared/shared.dart';

import 'driver_api_service.dart';
import 'driver_models.dart';

/// The Driver module's single data gateway. Controllers depend on this, never
/// on [DriverApiService] directly.
class DriverRepository {
  final DriverApiService _api;
  DriverRepository({DriverApiService? api}) : _api = api ?? DriverApiService();

  Future<ApiResponse<List<DriverAssignment>>> loadMyAssignments() =>
      _api.fetchMyAssignments();

  Future<ApiResponse<List<DriverRouteOption>>> loadRoutes() => _api.fetchRoutes();

  Future<ApiResponse<List<DriverTrip>>> loadActiveTrips() =>
      _api.fetchActiveTrips();

  Future<ApiResponse<DriverTrip>> startTrip({
    required String routeId,
    required String tripType,
  }) =>
      _api.startTrip(routeId: routeId, tripType: tripType);

  Future<ApiResponse<DriverTrip>> loadTrip(String tripId) =>
      _api.fetchTrip(tripId);

  Future<ApiResponse<DriverTrip>> endTrip(String tripId) => _api.endTrip(tripId);

  Future<ApiResponse<DriverTrip>> updateStopOrder(
          String tripId, List<String> order) =>
      _api.updateStopOrder(tripId, order);

  Future<ApiResponse<DriverTrip>> setStudentStatus({
    required String tripId,
    required String studentId,
    required String status,
    double? latitude,
    double? longitude,
  }) =>
      _api.setStudentStatus(
        tripId: tripId, studentId: studentId, status: status,
        latitude: latitude, longitude: longitude,
      );

  Future<ApiResponse<dynamic>> postLocation({
    required String tripId,
    required double latitude,
    required double longitude,
    String? address,
    double? speed,
    double? heading,
  }) =>
      _api.postLocation(
        tripId: tripId, latitude: latitude, longitude: longitude,
        address: address, speed: speed, heading: heading,
      );
}
