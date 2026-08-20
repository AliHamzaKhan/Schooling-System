/// Route name constants owned by the Driver module. Pages live in
/// [DriverPages] — see `driver_pages.dart`.
class DriverRoutes {
  DriverRoutes._();

  static const _base = '/driver';

  /// The driver's single home screen (today's trip). No bottom nav — a driver
  /// has exactly one job at a time.
  static const shell = _base;
}
