import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

/// Persists user-configurable settings and threshold-notification state.
class SettingsService {
  static const refreshIntervalOptions = [30, 60, 120, 240];

  static const _skinTypeKey = 'settings_skin_type';
  static const _refreshIntervalKey = 'settings_refresh_interval_minutes';
  static const _notifyHighKey = 'settings_notify_high';
  static const _notifySafeKey = 'settings_notify_safe';
  static const _manualLatKey = 'settings_manual_lat';
  static const _manualLngKey = 'settings_manual_lng';
  static const _manualLabelKey = 'settings_manual_label';
  static const _wasAboveHighKey = 'state_was_above_high';
  static const _wasBelowSafeKey = 'state_was_below_safe';

  static Future<SkinType> getSkinType() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_skinTypeKey) ?? SkinType.iii.index;
    return SkinType.values[index.clamp(0, SkinType.values.length - 1)];
  }

  static Future<void> setSkinType(SkinType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_skinTypeKey, type.index);
  }

  static Future<int> getRefreshIntervalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_refreshIntervalKey) ?? 60;
  }

  static Future<void> setRefreshIntervalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_refreshIntervalKey, minutes);
  }

  static Future<bool> getNotifyHigh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifyHighKey) ?? true;
  }

  static Future<void> setNotifyHigh(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifyHighKey, value);
  }

  static Future<bool> getNotifySafe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifySafeKey) ?? true;
  }

  static Future<void> setNotifySafe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifySafeKey, value);
  }

  static Future<ManualLocation?> getManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_manualLatKey);
    final lng = prefs.getDouble(_manualLngKey);
    final label = prefs.getString(_manualLabelKey);
    if (lat == null || lng == null || label == null) return null;
    return ManualLocation(latitude: lat, longitude: lng, label: label);
  }

  static Future<void> setManualLocation(ManualLocation? location) async {
    final prefs = await SharedPreferences.getInstance();
    if (location == null) {
      await prefs.remove(_manualLatKey);
      await prefs.remove(_manualLngKey);
      await prefs.remove(_manualLabelKey);
    } else {
      await prefs.setDouble(_manualLatKey, location.latitude);
      await prefs.setDouble(_manualLngKey, location.longitude);
      await prefs.setString(_manualLabelKey, location.label);
    }
  }

  /// Null means "no prior reading" — used to skip notifying on first run.
  static Future<bool?> getWasAboveHigh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wasAboveHighKey);
  }

  static Future<void> setWasAboveHigh(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wasAboveHighKey, value);
  }

  static Future<bool?> getWasBelowSafe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wasBelowSafeKey);
  }

  static Future<void> setWasBelowSafe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wasBelowSafeKey, value);
  }
}
