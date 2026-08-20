import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// A captured device location: coordinates plus a best-effort readable address.
class PickedLocation {
  final double latitude;
  final double longitude;
  final String? address;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

/// Thin wrapper over `geolocator` (GPS + permissions) and `geocoding` (reverse
/// lookup). No maps API key is involved — geocoding uses the OS geocoder.
class LocationService {
  const LocationService();

  /// Ensures location services + permission are available, then returns the
  /// current position with a reverse-geocoded address. Throws a
  /// [LocationException] with a user-readable message on any failure so callers
  /// can surface it directly.
  Future<PickedLocation> capture() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('Location services are turned off.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException('Location permission was denied.');
    }

    final pos = await Geolocator.getCurrentPosition();
    final address = await _reverseGeocode(pos.latitude, pos.longitude);
    return PickedLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      address: address,
    );
  }

  /// Best-effort reverse geocode; returns null (never throws) if it can't
  /// resolve an address, so a coordinate is still usable.
  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return null;
      final m = marks.first;
      final parts = <String?>[
        m.name,
        m.subLocality,
        m.locality,
        m.administrativeArea,
      ].where((p) => p != null && p.trim().isNotEmpty).toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
  @override
  String toString() => message;
}
