import 'package:workmanager/workmanager.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'uv_service.dart';
import 'widget_service.dart';

const String uvRefreshTaskName = 'uvRefreshTask';

/// Entry point for the background isolate. Must be a top-level function
/// annotated with `vm:entry-point` so the native side can find it after
/// the app process is killed.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == uvRefreshTaskName) {
      try {
        final locationResult = await LocationService().getCurrentLocation();
        if (locationResult is LocationSuccess) {
          final data = await UvService()
              .fetch(locationResult.latitude, locationResult.longitude);
          await WidgetService.update(data);
          await NotificationService.initialize();
          await NotificationService.checkAndNotify(data);
        }
      } catch (_) {
        // Best-effort refresh; a failure here just means the widget shows
        // last cached data until the next scheduled run.
      }
    }
    return true;
  });
}

/// Schedules a periodic background refresh of the home-screen widget.
class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(backgroundCallbackDispatcher);
    final minutes = await SettingsService.getRefreshIntervalMinutes();
    await _registerPeriodicTask(minutes);
  }

  /// Re-registers the periodic task with a new interval. Safe to call
  /// repeatedly — [ExistingPeriodicWorkPolicy.update] replaces the pending
  /// schedule without restarting in-progress work.
  static Future<void> updateRefreshInterval(int minutes) async {
    await SettingsService.setRefreshIntervalMinutes(minutes);
    await _registerPeriodicTask(minutes);
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
