import 'package:home_widget/home_widget.dart';
import '../utils/uv_scale.dart';

/// Pushes the latest UV reading to the Android home-screen widget. [uvi]
/// may come from a fresh API fetch or from a cheap local interpolation
/// between known readings, so the widget can be refreshed more often than
/// the API is actually called.
class WidgetService {
  static const String _androidWidgetName = 'UvWidgetSmallProvider';

  static Future<void> update(double uvi) async {
    // Color is derived from the same rounded value shown on the widget —
    // not the raw reading — so e.g. 7.6 (which rounds to "8") doesn't show
    // the "High" color band for a value displayed as the "Very High" band.
    final displayedValue = uvi.round();
    final color = UvScale.colorForValue(displayedValue.toDouble());

    await HomeWidget.saveWidgetData<int>('uv_value', displayedValue);
    await HomeWidget.saveWidgetData<int>('uv_color', color.toARGB32());

    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }
}
