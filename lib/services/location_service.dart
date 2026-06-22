import 'package:geolocator/geolocator.dart';

/// Result of a location request, including a human-readable error reason.
sealed class LocationResult {}

class LocationSuccess extends LocationResult {
  final double latitude;
  final double longitude;
  LocationSuccess(this.latitude, this.longitude);
}

class LocationFailure extends LocationResult {
  final String message;
  LocationFailure(this.message);
}

/// Wraps geolocator with permission handling. Coarse accuracy is enough
/// for UV index — it only varies over tens of kilometres.
class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationFailure(
          'Location services are off. Enable them in settings.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationFailure('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationFailure(
          'Location permission permanently denied. Enable it in app settings.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // coarse is plenty for UV
        ),
      );
      return LocationSuccess(position.latitude, position.longitude);
    } catch (e) {
      return LocationFailure('Could not get location: $e');
    }
  }
}
