import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/uv_scale.dart';

typedef WidgetUpdateEntry = ({
  DateTime time,
  int? previousValue,
  int newValue,
  double exactValue,
});

/// Pushes the latest UV reading to the Android home-screen widget. [uvi]
/// may come from a fresh API fetch or from a cheap local interpolation
/// between known readings, so the widget can be refreshed more often than
/// the API is actually called.
class WidgetService {
  static const String _androidWidgetName = 'UvWidgetSmallProvider';
  static const String _lastUpdateKey = 'widget_last_update_ms';
  static const String _updateHistoryKey = 'widget_update_history';
  static const Duration _historyWindow = Duration(hours: 24);

  static Future<void> update(double uvi) async {
    // Color is derived from the same rounded value shown on the widget —
    // not the raw reading — so e.g. 7.6 (which rounds to "8") doesn't show
    // the "High" color band for a value displayed as the "Very High" band.
    final displayedValue = uvi.round();
    final color = UvScale.colorForValue(displayedValue.toDouble());

    await HomeWidget.saveWidgetData<int>('uv_value', displayedValue);
    await HomeWidget.saveWidgetData<int>('uv_color', color.toARGB32());

    await HomeWidget.updateWidget(androidName: _androidWidgetName);

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt(_lastUpdateKey, now.millisecondsSinceEpoch);
    await _recordHistory(prefs, now, displayedValue, uvi);
  }

  /// The last time [update] actually pushed data to the widget, from any
  /// source (a foreground tick, a background tick, or a fresh fetch).
  /// Debug-only — surfaced in the UI to verify the update scheduling.
  static Future<DateTime?> lastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastUpdateKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Every time [update] actually pushed to the widget in the last 24
  /// hours, oldest first — the rounded value before and after the push
  /// (null [previousValue] if it's the oldest entry on record) plus the
  /// exact interpolated value that was rounded. Debug-only — lets you see
  /// gaps or delays in the push schedule, not just the most recent push.
  static Future<List<WidgetUpdateEntry>> updateHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(_historyWindow);
    return _decodeHistory(prefs.getStringList(_updateHistoryKey) ?? [])
        .where((e) => e.time.isAfter(cutoff))
        .toList();
  }

  static Future<void> _recordHistory(
      SharedPreferences prefs, DateTime time, int newValue, double exactValue) async {
    final cutoff = time.subtract(_historyWindow);
    final entries = _decodeHistory(prefs.getStringList(_updateHistoryKey) ?? [])
        .where((e) => e.time.isAfter(cutoff))
        .toList();
    final previousValue = entries.isEmpty ? null : entries.last.newValue;
    entries.add((
      time: time,
      previousValue: previousValue,
      newValue: newValue,
      exactValue: exactValue,
    ));
    await prefs.setStringList(_updateHistoryKey, entries.map(_encode).toList());
  }

  static String _encode(WidgetUpdateEntry e) {
    final prev = e.previousValue?.toString() ?? '';
    return '${e.time.millisecondsSinceEpoch}:$prev:${e.newValue}:${e.exactValue}';
  }

  static List<WidgetUpdateEntry> _decodeHistory(List<String> raw) {
    final entries = <WidgetUpdateEntry>[];
    for (final line in raw) {
      final parts = line.split(':');
      if (parts.length != 4) continue;
      final ms = int.tryParse(parts[0]);
      final previousValue = parts[1].isEmpty ? null : int.tryParse(parts[1]);
      final newValue = int.tryParse(parts[2]);
      final exactValue = double.tryParse(parts[3]);
      if (ms == null || newValue == null || exactValue == null) continue;
      entries.add((
        time: DateTime.fromMillisecondsSinceEpoch(ms),
        previousValue: previousValue,
        newValue: newValue,
        exactValue: exactValue,
      ));
    }
    return entries;
  }
}
