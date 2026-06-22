import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/uv_data.dart';
import '../utils/uv_scale.dart';
import 'settings_service.dart';

/// Fires local notifications on UV threshold transitions: entering the WHO
/// "High" band, and dropping back below the safe-without-protection level.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'uv_alerts';
  static const _channelName = 'UV alerts';
  static const _highNotificationId = 1;
  static const _safeNotificationId = 2;

  static Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Compares [data]'s current UV band against the last known band and
  /// fires a notification on a threshold crossing, if enabled. The first
  /// ever call just records a baseline without notifying.
  static Future<void> checkAndNotify(UvData data) async {
    final isAboveHigh = data.now.uvi >= UvScale.highThreshold;
    final isBelowSafe = data.now.uvi < UvScale.safeThreshold;

    final wasAboveHigh = await SettingsService.getWasAboveHigh();
    final wasBelowSafe = await SettingsService.getWasBelowSafe();

    if (wasAboveHigh == false &&
        isAboveHigh &&
        await SettingsService.getNotifyHigh()) {
      await _show(
        _highNotificationId,
        'UV is now High',
        'UV index is ${data.now.uvi.round()} — protection is essential.',
      );
    }

    if (wasBelowSafe == false &&
        isBelowSafe &&
        await SettingsService.getNotifySafe()) {
      await _show(
        _safeNotificationId,
        'Safe to go outside',
        'UV index has dropped below '
            '${UvScale.safeThreshold.round()} — no protection needed.',
      );
    }

    await SettingsService.setWasAboveHigh(isAboveHigh);
    await SettingsService.setWasBelowSafe(isBelowSafe);
  }

  static Future<void> _show(int id, String title, String body) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName),
      ),
    );
  }
}
