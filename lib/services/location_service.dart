import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'settings_service.dart';

/// Result of a location request, including a machine-readable error reason
/// (the UI maps this to a localized message).
sealed class LocationResult {}

class LocationSuccess extends LocationResult {
  final double latitude;
  final double longitude;
  LocationSuccess(this.latitude, this.longitude);
}

enum LocationFailureReason {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationFailure extends LocationResult {
  final LocationFailureReason reason;
  final String? detail;
  LocationFailure(this.reason, {this.detail});
}

/// Wraps geolocator with permission handling. Coarse accuracy is enough
/// for UV index — it only varies over tens of kilometres.
class LocationService {
  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final manual = await SettingsService.getManualLocation();
    if (manual != null) {
      return LocationSuccess(manual.latitude, manual.longitude);
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationFailure(LocationFailureReason.servicesDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationFailure(LocationFailureReason.permissionDenied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationFailure(LocationFailureReason.permissionDeniedForever);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low, // coarse is plenty for UV
          timeLimit: timeout,
        ),
      );
      return LocationSuccess(position.latitude, position.longitude);
    } on TimeoutException {
      return LocationFailure(LocationFailureReason.timeout);
    } catch (e) {
      return LocationFailure(LocationFailureReason.unknown, detail: '$e');
    }
  }

  /// Great-circle distance between two coordinates, in meters.
  static double distanceBetween(
          double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}
