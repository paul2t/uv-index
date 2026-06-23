import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/uv_data.dart';
import '../utils/uv_scale.dart';

/// Short hour label, locale-aware: 24h digits for French, 12h am/pm for
/// English and other locales.
String _shortHourLabel(BuildContext context, int hour) {
  if (Localizations.localeOf(context).languageCode == 'fr') {
    return '${hour}h';
  }
  if (hour == 0) return '12a';
  if (hour < 12) return '${hour}a';
  if (hour == 12) return '12p';
  return '${hour - 12}p';
}

const double _chartHeight = 100;
const double _barWidth = 14;
const double _itemWidth = 24;
const double _itemSpacing = 2;
const double _itemSpan = _itemWidth + _itemSpacing;

/// The x-offset (in pixels, from the left of the chart's scrollable content)
/// of the current moment, linearly interpolated between the two readings
/// that bracket it. Returns null if now falls outside the available range.
double? _nowOffsetX(List<UvReading> readings) {
  final now = DateTime.now();
  for (var i = 0; i < readings.length - 1; i++) {
    final a = readings[i];
    final b = readings[i + 1];
    if (!now.isBefore(a.time) && !now.isAfter(b.time)) {
      final spanMs = b.time.difference(a.time).inMilliseconds;
      final frac =
          spanMs == 0 ? 0.0 : now.difference(a.time).inMilliseconds / spanMs;
      final centerA = i * _itemSpan + _itemWidth / 2;
      return centerA + frac * _itemSpan;
    }
  }
  return null;
}

/// A horizontally scrolling histogram of history and upcoming hourly UV
/// readings, with a vertical line marking the current moment.
class ForecastRow extends StatefulWidget {
  final List<UvReading> readings;

  const ForecastRow({super.key, required this.readings});

  @override
  State<ForecastRow> createState() => _ForecastRowState();
}

class _ForecastRowState extends State<ForecastRow> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to "now" once, on first open — readings span 12h back and 24h
    // ahead, so without this the user would land on history and have to
    // scroll manually to see the current value and forecast.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
  }

  void _scrollToNow() {
    if (!mounted || !_scrollController.hasClients) return;
    final x = _nowOffsetX(widget.readings);
    if (x == null) return;
    final target =
        (x - 80).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.jumpTo(target);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isCurrentHour(DateTime t) {
    final now = DateTime.now();
    return t.year == now.year &&
        t.month == now.month &&
        t.day == now.day &&
        t.hour == now.hour;
  }

  @override
  Widget build(BuildContext context) {
    final readings = widget.readings;
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxUvi = readings.map((r) => r.uvi).reduce((a, b) => a > b ? a : b);
    // Round up to the next even number, with a floor of 11 (the "Very High"
    // ceiling) so the chart scale stays readable on typical days.
    final chartMax = maxUvi < 11 ? 11.0 : (maxUvi / 2).ceil() * 2.0;
    final totalWidth = readings.length * _itemSpan;
    final nowX = _nowOffsetX(readings);
    final chartAreaHeight = 20 + _chartHeight + 24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.next24Hours,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: chartAreaHeight,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              height: chartAreaHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    height: _chartHeight,
                    child: _GridLines(chartMax: chartMax),
                  ),
                  Row(
                    children: [
                      for (final reading in readings)
                        _HourBar(
                          reading: reading,
                          chartMax: chartMax,
                          isNow: _isCurrentHour(reading.time),
                        ),
                    ],
                  ),
                  if (nowX != null)
                    Positioned(
                      left: nowX - 0.75,
                      top: 20,
                      width: 1.5,
                      height: _chartHeight,
                      child: Container(color: Colors.black54),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Faint reference lines at the WHO band thresholds, behind the bars.
class _GridLines extends StatelessWidget {
  final double chartMax;
  const _GridLines({required this.chartMax});

  static const _thresholds = [3.0, 6.0, 8.0, 11.0];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _thresholds.where((t) => t <= chartMax).map((t) {
        return Positioned(
          bottom: (t / chartMax) * _chartHeight,
          left: 0,
          right: 0,
          child: Container(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        );
      }).toList(),
    );
  }
}

class _HourBar extends StatelessWidget {
  final UvReading reading;
  final double chartMax;
  final bool isNow;

  const _HourBar({
    required this.reading,
    required this.chartMax,
    required this.isNow,
  });

  @override
  Widget build(BuildContext context) {
    // Color is derived from the same rounded value shown in the label —
    // not the raw reading — so two hours both displaying "8" never end up
    // on opposite sides of a band boundary (e.g. 7.6 and 8.3 both round to
    // "8" but fall in different WHO bands when read at full precision).
    final displayedValue = reading.uvi.round();
    final scale =
        UvScale.forValue(displayedValue.toDouble(), AppLocalizations.of(context)!);
    final hour = reading.time.hour;
    final label = _shortHourLabel(context, hour);

    final barHeight =
        ((reading.uvi / chartMax).clamp(0.0, 1.0) * _chartHeight)
            .clamp(4.0, _chartHeight);
    // Only label every 3rd hour to keep the axis readable at tight spacing,
    // but always label the current hour.
    final showLabel = hour % 3 == 0 || isNow;

    return SizedBox(
      width: _itemSpan,
      child: Padding(
        padding: const EdgeInsets.only(right: _itemSpacing),
        child: Column(
          children: [
            Text(
              '$displayedValue',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                color: isNow ? scale.color : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: _chartHeight - 20,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: _barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: scale.color.withValues(alpha: isNow ? 1.0 : 0.55),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                    border: isNow ? Border.all(color: scale.color, width: 1.5) : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              showLabel ? label : '',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                color: isNow ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
