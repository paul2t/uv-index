/// Models for the currentuvindex.com API response.
///
/// Example response:
/// {
///   "ok": true,
///   "latitude": 48.85,
///   "longitude": 2.35,
///   "now": { "time": "2026-06-22T13:00:00Z", "uvi": 6.9 },
///   "forecast": [ { "time": "...", "uvi": 8.3 }, ... ],
///   "history": [ { "time": "...", "uvi": 2.9 }, ... ]
/// }
library;

import '../utils/uv_scale.dart';

class UvReading {
  final DateTime time;
  final double uvi;

  UvReading({required this.time, required this.uvi});

  factory UvReading.fromJson(Map<String, dynamic> json) {
    return UvReading(
      time: DateTime.parse(json['time'] as String).toLocal(),
      uvi: (json['uvi'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time.toUtc().toIso8601String(),
        'uvi': uvi,
      };
}

class UvData {
  final double latitude;
  final double longitude;
  final UvReading now;
  final List<UvReading> forecast;

  UvData({
    required this.latitude,
    required this.longitude,
    required this.now,
    required this.forecast,
  });

  factory UvData.fromJson(Map<String, dynamic> json) {
    if (json['ok'] != true) {
      throw const FormatException('API returned ok=false');
    }
    final forecastList = (json['forecast'] as List<dynamic>? ?? [])
        .map((e) => UvReading.fromJson(e as Map<String, dynamic>))
        .toList();

    return UvData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      now: UvReading.fromJson(json['now'] as Map<String, dynamic>),
      forecast: forecastList,
    );
  }

  Map<String, dynamic> toJson() => {
        'ok': true,
        'latitude': latitude,
        'longitude': longitude,
        'now': now.toJson(),
        'forecast': forecast.map((e) => e.toJson()).toList(),
      };

  /// Forecast entries for the rest of today and tomorrow, hourly.
  List<UvReading> get upcomingHours {
    final cutoff = DateTime.now().add(const Duration(hours: 24));
    return forecast
        .where((r) => r.time.isAfter(DateTime.now()) && r.time.isBefore(cutoff))
        .toList();
  }

  /// Peak UV in the upcoming forecast window.
  UvReading? get peakToday {
    final today = DateTime.now();
    final todayReadings = forecast.where((r) =>
        r.time.year == today.year &&
        r.time.month == today.month &&
        r.time.day == today.day);
    if (todayReadings.isEmpty) return null;
    return todayReadings.reduce((a, b) => a.uvi >= b.uvi ? a : b);
  }

  /// The next upcoming hour (within 24h) where UV is expected to drop
  /// below [UvScale.safeThreshold], i.e. safe without sun protection.
  /// Returns null if it's already safe now, or stays unsafe all day.
  UvReading? get nextSafeReading {
    if (now.uvi < UvScale.safeThreshold) return null;
    for (final r in upcomingHours) {
      if (r.uvi < UvScale.safeThreshold) return r;
    }
    return null;
  }
}
