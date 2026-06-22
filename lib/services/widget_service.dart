import 'package:home_widget/home_widget.dart';
import '../models/uv_data.dart';
import '../utils/uv_scale.dart';

/// Pushes the latest UV reading to the Android home-screen widget.
class WidgetService {
  static const String _androidWidgetName = 'UvWidgetSmallProvider';

  static Future<void> update(UvData data) async {
    final scale = UvScale.forValue(data.now.uvi);

    await HomeWidget.saveWidgetData<int>('uv_value', data.now.uvi.round());
    await HomeWidget.saveWidgetData<int>('uv_color', scale.color.toARGB32());

    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }
}
