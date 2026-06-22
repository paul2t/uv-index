import 'package:geocoding/geocoding.dart';
import '../models/app_settings.dart';

/// Resolves a typed address/city into coordinates for a manual location
/// override. Uses the device's built-in geocoder — no API key needed.
class GeocodingService {
  static Future<ManualLocation?> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    final results = await locationFromAddress(trimmed);
    if (results.isEmpty) return null;

    final first = results.first;
    return ManualLocation(
      latitude: first.latitude,
      longitude: first.longitude,
      label: trimmed,
    );
  }
}
