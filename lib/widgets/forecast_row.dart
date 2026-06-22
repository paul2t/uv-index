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

/// A horizontally scrolling histogram of upcoming hourly UV readings.
class ForecastRow extends StatelessWidget {
  final List<UvReading> readings;

  const ForecastRow({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxUvi = readings.map((r) => r.uvi).reduce((a, b) => a > b ? a : b);
    // Round up to the next even number, with a floor of 11 (the "Very High"
    // ceiling) so the chart scale stays readable on typical days.
    final chartMax = maxUvi < 11 ? 11.0 : (maxUvi / 2).ceil() * 2.0;
    final now = DateTime.now();

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
          height: 20 + _chartHeight + 24,
          child: Stack(
            children: [
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                height: _chartHeight,
                child: _GridLines(chartMax: chartMax),
              ),
              ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: readings.length,
                separatorBuilder: (_, __) => const SizedBox(width: 2),
                itemBuilder: (context, i) {
                  final reading = readings[i];
                  final isNow = reading.time.year == now.year &&
                      reading.time.month == now.month &&
                      reading.time.day == now.day &&
                      reading.time.hour == now.hour;
                  return _HourBar(
                    reading: reading,
                    chartMax: chartMax,
                    isNow: isNow,
                  );
                },
              ),
            ],
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
    final scale = UvScale.forValue(reading.uvi, AppLocalizations.of(context)!);
    final hour = reading.time.hour;
    final label = _shortHourLabel(context, hour);

    final barHeight =
        ((reading.uvi / chartMax).clamp(0.0, 1.0) * _chartHeight)
            .clamp(4.0, _chartHeight);
    // Only label every 3rd hour to keep the axis readable at tight spacing,
    // but always label the current hour.
    final showLabel = hour % 3 == 0 || isNow;

    return SizedBox(
      width: _itemWidth,
      child: Column(
        children: [
          Text(
            reading.uvi.toStringAsFixed(0),
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
    );
  }
}
