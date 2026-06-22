import 'package:home_widget/home_widget.dart';
import '../models/uv_data.dart';
import '../utils/uv_scale.dart';

/// Pushes the latest UV reading to the Android home-screen widget.
class WidgetService {
  static const String _androidWidgetName = 'UvWidgetProvider';

  static Future<void> update(UvData data) async {
    final scale = UvScale.forValue(data.now.uvi);
    final now = DateTime.now();

    await HomeWidget.saveWidgetData<int>('uv_value', data.now.uvi.round());
    await HomeWidget.saveWidgetData<String>('uv_label', scale.label);
    await HomeWidget.saveWidgetData<int>('uv_color', scale.color.toARGB32());
    await HomeWidget.saveWidgetData<String>(
        'uv_updated_at', _formatTime(now));

    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }

  static String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'am' : 'pm';
    return 'Updated $h:$m$ampm';
  }
}
