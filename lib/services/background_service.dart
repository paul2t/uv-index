import 'package:workmanager/workmanager.dart';
import 'location_service.dart';
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
    await Workmanager().registerPeriodicTask(
      uvRefreshTaskName,
      uvRefreshTaskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
