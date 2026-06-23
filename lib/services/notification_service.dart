import 'dart:ui' as ui;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/uv_data.dart';
import '../utils/uv_scale.dart';
import 'settings_service.dart';

/// Fires local notifications on UV threshold transitions: entering the WHO
/// "High" band, and dropping back below the safe-without-protection level.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'uv_alerts';
  static const _highNotificationId = 1;
  static const _safeNotificationId = 2;

  // This runs from a context-free background isolate (workmanager), so the
  // generated AppLocalizations machinery (which needs a BuildContext) isn't
  // available — check the device locale directly instead.
  static bool get _isFrench =>
      ui.PlatformDispatcher.instance.locale.languageCode == 'fr';

  static String get _channelName => _isFrench ? 'Alertes UV' : 'UV alerts';

  static String get _highTitle =>
      _isFrench ? 'UV élevé' : 'UV is now High';

  static String _highBody(int value) => _isFrench
      ? 'Indice UV : $value — la protection est essentielle.'
      : 'UV index is $value — protection is essential.';

  static String get _safeTitle =>
      _isFrench ? 'Sortie sans risque' : 'Safe to go outside';

  static String _safeBody(int threshold) => _isFrench
      ? 'L\'indice UV est redescendu sous $threshold — aucune protection nécessaire.'
      : 'UV index has dropped below $threshold — no protection needed.';

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
        _highTitle,
        _highBody(data.now.uvi.round()),
      );
    }

    if (wasBelowSafe == false &&
        isBelowSafe &&
        await SettingsService.getNotifySafe()) {
      await _show(
        _safeNotificationId,
        _safeTitle,
        _safeBody(UvScale.safeThreshold.round()),
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
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName),
      ),
    );
  }
}
