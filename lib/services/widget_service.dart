import 'package:home_widget/home_widget.dart';
import '../utils/uv_scale.dart';

/// Pushes the latest UV reading to the Android home-screen widget. [uvi]
/// may come from a fresh API fetch or from a cheap local interpolation
/// between known readings, so the widget can be refreshed more often than
/// the API is actually called.
class WidgetService {
  static const String _androidWidgetName = 'UvWidgetSmallProvider';

  static Future<void> update(double uvi) async {
    final color = UvScale.colorForValue(uvi);

    await HomeWidget.saveWidgetData<int>('uv_value', uvi.round());
    await HomeWidget.saveWidgetData<int>('uv_color', color.toARGB32());

    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }
}
