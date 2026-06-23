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

  /// Past readings, oldest first. The API only returns a short recent
  /// window of these; [mergedWithPrevious] folds in readings carried over
  /// from earlier fetches so a rolling window survives across requests.
  final List<UvReading> history;

  UvData({
    required this.latitude,
    required this.longitude,
    required this.now,
    required this.forecast,
    this.history = const [],
  });

  factory UvData.fromJson(Map<String, dynamic> json) {
    if (json['ok'] != true) {
      throw const FormatException('API returned ok=false');
    }
    final forecastList = (json['forecast'] as List<dynamic>? ?? [])
        .map((e) => UvReading.fromJson(e as Map<String, dynamic>))
        .toList();
    final historyList = (json['history'] as List<dynamic>? ?? [])
        .map((e) => UvReading.fromJson(e as Map<String, dynamic>))
        .toList();

    return UvData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      now: UvReading.fromJson(json['now'] as Map<String, dynamic>),
      forecast: forecastList,
      history: historyList,
    );
  }

  Map<String, dynamic> toJson() => {
        'ok': true,
        'latitude': latitude,
        'longitude': longitude,
        'now': now.toJson(),
        'forecast': forecast.map((e) => e.toJson()).toList(),
        'history': history.map((e) => e.toJson()).toList(),
      };

  /// Returns a copy whose [history] also includes [previous]'s history and
  /// its old `now` reading (now superseded by this fetch), deduplicated by
  /// timestamp and pruned to the last [window] (default 12 hours) relative
  /// to this reading's `now` time. This keeps a rolling window of readings
  /// available for [interpolatedUvi] even though the API itself only
  /// returns a short recent slice on each call.
  UvData mergedWithPrevious(UvData? previous,
      {Duration window = const Duration(hours: 12)}) {
    final cutoff = now.time.subtract(window);
    final byTime = <int, UvReading>{};
    if (previous != null) {
      for (final r in previous.history) {
        byTime[r.time.millisecondsSinceEpoch] = r;
      }
      byTime[previous.now.time.millisecondsSinceEpoch] = previous.now;
    }
    for (final r in history) {
      byTime[r.time.millisecondsSinceEpoch] = r;
    }
    final merged = byTime.values.where((r) => r.time.isAfter(cutoff)).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return UvData(
      latitude: latitude,
      longitude: longitude,
      now: now,
      forecast: forecast,
      history: merged,
    );
  }

  /// Past readings, the current reading, and forecast readings, sorted by
  /// time. The shared timeline used for interpolation. Deduplicated by
  /// timestamp — history and forecast can both include the same hour (e.g.
  /// a previous fetch's `now` carried into history, re-reported by a fresh
  /// fetch's `forecast`) — preferring the freshest source (forecast over
  /// `now` over history) so the chart doesn't show the same hour twice.
  List<UvReading> get _timeline {
    final byTime = <int, UvReading>{};
    for (final r in history) {
      byTime[r.time.millisecondsSinceEpoch] = r;
    }
    byTime[now.time.millisecondsSinceEpoch] = now;
    for (final r in forecast) {
      byTime[r.time.millisecondsSinceEpoch] = r;
    }
    final points = byTime.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return points;
  }

  /// Estimates the UV index at an arbitrary [time] by linearly interpolating
  /// between the two nearest known readings (history/now/forecast) that
  /// bracket it. Falls back to the nearest known reading if [time] is
  /// outside the available range.
  double interpolatedUvi(DateTime time) {
    UvReading? before;
    UvReading? after;
    for (final point in _timeline) {
      if (!point.time.isAfter(time)) {
        before = point;
      } else {
        after = point;
        break;
      }
    }
    if (before == null) return after!.uvi;
    if (after == null) return before.uvi;
    final spanMs = after.time.difference(before.time).inMilliseconds;
    if (spanMs == 0) return before.uvi;
    final t = time.difference(before.time).inMilliseconds / spanMs;
    return before.uvi + (after.uvi - before.uvi) * t;
  }

  /// Predicts the next moment after [from] at which the rounded UV index
  /// (i.e. the integer shown on the widget) would change, by walking
  /// forward through the piecewise-linear history/forecast timeline.
  /// Returns null if the available data doesn't show a future crossing
  /// (e.g. the forecast window has been exhausted).
  DateTime? nextChangeTime(DateTime from) {
    final currentRounded = interpolatedUvi(from).round();
    final upperBound = currentRounded + 0.5;
    final lowerBound = currentRounded - 0.5;
    final points = _timeline;

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (!b.time.isAfter(from)) continue;

      final spanMs = b.time.difference(a.time).inMilliseconds;
      if (spanMs == 0 || a.uvi == b.uvi) continue;

      double? frac;
      if (b.uvi > a.uvi && b.uvi >= upperBound) {
        frac = (upperBound - a.uvi) / (b.uvi - a.uvi);
      } else if (b.uvi < a.uvi && b.uvi <= lowerBound) {
        frac = (lowerBound - a.uvi) / (b.uvi - a.uvi);
      }
      if (frac == null) continue;

      final crossing = a.time.add(Duration(milliseconds: (spanMs * frac).round()));
      if (crossing.isAfter(from)) return crossing;
    }
    return null;
  }

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

  /// History and forecast readings for the histogram: from 12 hours ago
  /// through 24 hours ahead.
  List<UvReading> get chartReadings {
    final from = DateTime.now().subtract(const Duration(hours: 12));
    final to = DateTime.now().add(const Duration(hours: 24));
    return _timeline.where((r) => r.time.isAfter(from) && r.time.isBefore(to)).toList();
  }

  /// Today's predicted protection window — the interpolated, minute-
  /// precision start and end of the period during which UV is at or above
  /// [UvScale.safeThreshold]. [end] is always present (falling back to
  /// midnight tonight if UV is predicted to stay above the threshold for
  /// the rest of the day). [start] is null when it can't actually be
  /// grounded in known data — e.g. a 12-hour history window doesn't reach
  /// far enough back to cover this morning's rise, or there's no history
  /// at all yet (a fresh install) — rather than guessing midnight or
  /// "now" from a flat extrapolation.
  ({DateTime? start, DateTime end}) get todaysProtectionWindow {
    final threshold = UvScale.safeThreshold;
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final timeline = _timeline;
    final earliestKnown = timeline.isEmpty ? null : timeline.first.time;

    DateTime? start;
    if (earliestKnown != null &&
        !earliestKnown.isAfter(dayStart) &&
        interpolatedUvi(dayStart) >= threshold) {
      // Data genuinely reaches back to midnight and it was already unsafe.
      start = dayStart;
    } else {
      // A genuine rising crossing found within the known timeline.
      start = _nextThresholdCrossing(dayStart, threshold, risingThrough: true);
    }

    final end = _nextThresholdCrossing(start ?? now, threshold, risingThrough: false) ??
        dayEnd;
    return (start: start, end: end.isBefore(dayEnd) ? end : dayEnd);
  }

  /// The current UV index interpolated for this instant, rather than the
  /// API's `now` reading — which is itself timestamped to the start of
  /// whichever hour it was computed for, and can lag the real time by up
  /// to an hour.
  double get interpolatedNow => interpolatedUvi(DateTime.now());

  /// The next moment, with minute precision, at which UV is predicted to
  /// drop below [UvScale.safeThreshold] (safe without sun protection),
  /// found by interpolating across the history/forecast timeline. Returns
  /// null if already safe, or if it's predicted to stay unsafe for the
  /// rest of the available forecast.
  DateTime? get nextSafeTime {
    final from = DateTime.now();
    if (interpolatedUvi(from) < UvScale.safeThreshold) return null;
    return _nextThresholdCrossing(from, UvScale.safeThreshold,
        risingThrough: false);
  }

  /// The next moment, with minute precision, at which UV is predicted to
  /// rise back to or above [UvScale.safeThreshold] (protection becomes
  /// needed again). Returns null if already unsafe, or if it's predicted
  /// to stay safe for the rest of the available forecast.
  DateTime? get nextUnsafeTime {
    final from = DateTime.now();
    if (interpolatedUvi(from) >= UvScale.safeThreshold) return null;
    return _nextThresholdCrossing(from, UvScale.safeThreshold,
        risingThrough: true);
  }

  /// Finds the next time after [from] at which the timeline crosses
  /// [threshold] — rising through it if [risingThrough] is true, falling
  /// through it otherwise.
  DateTime? _nextThresholdCrossing(DateTime from, double threshold,
      {required bool risingThrough}) {
    final points = _timeline;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (!b.time.isAfter(from)) continue;
      if (a.uvi == b.uvi) continue;

      final crosses = risingThrough
          ? a.uvi < threshold && b.uvi >= threshold
          : a.uvi >= threshold && b.uvi < threshold;
      if (!crosses) continue;

      final spanMs = b.time.difference(a.time).inMilliseconds;
      final frac = (threshold - a.uvi) / (b.uvi - a.uvi);
      final crossing =
          a.time.add(Duration(milliseconds: (spanMs * frac).round()));
      if (crossing.isAfter(from)) return crossing;
    }
    return null;
  }
}
