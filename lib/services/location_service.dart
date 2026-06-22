import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'settings_service.dart';

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
    final manual = await SettingsService.getManualLocation();
    if (manual != null) {
      return LocationSuccess(manual.latitude, manual.longitude);
    }

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
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationSuccess(position.latitude, position.longitude);
    } on TimeoutException {
      return LocationFailure('Timed out getting your location. Try again.');
    } catch (e) {
      return LocationFailure('Could not get location: $e');
    }
  }
}
