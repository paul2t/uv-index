import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/uv_data.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'uv_service.dart';
import 'widget_service.dart';

const String uvRefreshTaskName = 'uvRefreshTask';

/// One-off task that nudges the widget between scheduled API refreshes by
/// interpolating from cached history/forecast data — no network involved.
const String uvTickTaskName = 'uvTickTask';

/// Lower bound on how soon a tick can be scheduled, so a steep slope right
/// at a rounding boundary can't cause back-to-back wakeups.
const Duration _minTickDelay = Duration(seconds: 30);

/// Entry point for the background isolate. Must be a top-level function
/// annotated with `vm:entry-point` so the native side can find it after
/// the app process is killed.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case uvRefreshTaskName:
        await _runRefresh();
      case uvTickTaskName:
        await _runTick();
    }
    return true;
  });
}

Future<void> _runRefresh() async {
  try {
    final uvService = UvService();

    // Update the widget from cached data immediately — cheap and
    // network-free — before attempting the real (rate-limited) API call.
    final interpolated = await uvService.interpolateFromCache();
    if (interpolated != null) {
      await WidgetService.update(interpolated);
    }

    final locationResult = await LocationService().getCurrentLocation();
    if (locationResult is LocationSuccess) {
      final data =
          await uvService.fetch(locationResult.latitude, locationResult.longitude);
      // Interpolated, not data.now.uvi directly — see the matching comment
      // in home_screen.dart's _applySuccessfulFetch.
      await WidgetService.update(data.interpolatedNow);
      await NotificationService.initialize();
      await NotificationService.checkAndNotify(data);
      await BackgroundService.scheduleNextTick(data);
    }
  } catch (_) {
    // Best-effort refresh; a failure here just means the widget shows
    // last cached data until the next scheduled run.
  }
}

Future<void> _runTick() async {
  try {
    final cached = await UvService().loadCached();
    if (cached == null) return;
    await WidgetService.update(cached.data.interpolatedUvi(DateTime.now()));
    await BackgroundService.scheduleNextTick(cached.data);
  } catch (_) {
    // Best-effort; the next periodic refresh will re-sync everything.
  }
}

/// Schedules a periodic refresh of the home-screen widget, plus a chain of
/// one-off "tick" tasks that keep it accurate in between by interpolating
/// from cached data.
class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(backgroundCallbackDispatcher);
    final minutes = await SettingsService.getRefreshIntervalMinutes();
    await _registerPeriodicTask(minutes);

    // Resume the tick chain from whatever is already cached, in case the
    // app process was killed and the pending one-off task lost with it.
    final cached = await UvService().loadCached();
    if (cached != null) await scheduleNextTick(cached.data);
  }

  /// Re-registers the periodic task with a new interval. Safe to call
  /// repeatedly — [ExistingPeriodicWorkPolicy.update] replaces the pending
  /// schedule without restarting in-progress work.
  static Future<void> updateRefreshInterval(int minutes) async {
    await SettingsService.setRefreshIntervalMinutes(minutes);
    await _registerPeriodicTask(minutes);
  }

  static const String _nextTickKey = 'widget_next_tick_ms';

  /// Predicts when [data]'s interpolated UV index will next cross a
  /// rounding boundary and schedules a one-off tick task for that moment,
  /// replacing any tick already pending. Cancels the pending tick if no
  /// future change can be predicted (e.g. forecast data exhausted).
  static Future<void> scheduleNextTick(UvData data) async {
    final next = data.nextChangeTime(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    if (next == null) {
      await Workmanager().cancelByUniqueName(uvTickTaskName);
      await prefs.remove(_nextTickKey);
      return;
    }
    await prefs.setInt(_nextTickKey, next.millisecondsSinceEpoch);
    final delay = next.difference(DateTime.now());
    await Workmanager().registerOneOffTask(
      uvTickTaskName,
      uvTickTaskName,
      initialDelay: delay < _minTickDelay ? _minTickDelay : delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// The next moment a background tick is scheduled to push an updated
  /// value to the widget (the rounded-integer crossing, independent of the
  /// foreground app's finer-grained ticking). Debug-only.
  static Future<DateTime?> nextBackgroundTickTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_nextTickKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> _registerPeriodicTask(int minutes) async {
    await Workmanager().registerPeriodicTask(
      uvRefreshTaskName,
      uvRefreshTaskName,
      frequency: Duration(minutes: minutes),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
