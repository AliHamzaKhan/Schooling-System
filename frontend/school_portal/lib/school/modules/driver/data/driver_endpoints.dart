/// Central registry of every backend path used by the Driver module.
class DriverEndpoints {
  DriverEndpoints._();

  static String _base(String schoolId) => '/schools/$schoolId/transport';

  static String myAssignments(String schoolId) => '${_base(schoolId)}/me/assignments';
  static String routes(String schoolId) => '${_base(schoolId)}/routes';
  static String tripsActive(String schoolId) => '${_base(schoolId)}/trips/active';
  static String tripsStart(String schoolId) => '${_base(schoolId)}/trips/start';
  static String trip(String schoolId, String tripId) =>
      '${_base(schoolId)}/trips/$tripId';
  static String tripEnd(String schoolId, String tripId) =>
      '${_base(schoolId)}/trips/$tripId/end';
  static String tripStopOrder(String schoolId, String tripId) =>
      '${_base(schoolId)}/trips/$tripId/stop-order';
  static String tripStudentStatus(String schoolId, String tripId, String studentId) =>
      '${_base(schoolId)}/trips/$tripId/students/$studentId/status';
  static String tripLocation(String schoolId, String tripId) =>
      '${_base(schoolId)}/trips/$tripId/location';
}
