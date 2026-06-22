import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/uv_data.dart';

/// Fetches UV index data from currentuvindex.com (no API key required)
/// and caches the last successful result for offline display.
class UvService {
  static const String _baseUrl = 'https://currentuvindex.com/api/v1/uvi';
  static const String _cacheKey = 'cached_uv_data';
  static const String _cacheTimeKey = 'cached_uv_time';

  /// Fetches current UV data for the given coordinates.
  /// On network failure, throws — callers can fall back to [loadCached].
  Future<UvData> fetch(double latitude, double longitude) async {
    final uri = Uri.parse('$_baseUrl?latitude=$latitude&longitude=$longitude');

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('UV API error: HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = UvData.fromJson(json);

    await _cache(response.body);
    return data;
  }

  Future<void> _cache(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, rawJson);
    await prefs.setInt(
        _cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns the last cached reading, or null if none exists.
  Future<({UvData data, DateTime fetchedAt})?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    final timeMs = prefs.getInt(_cacheTimeKey);
    if (raw == null || timeMs == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        data: UvData.fromJson(json),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(timeMs),
      );
    } catch (_) {
      return null;
    }
  }
}
