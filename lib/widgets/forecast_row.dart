import 'package:flutter/material.dart';
import '../models/uv_data.dart';
import '../utils/uv_scale.dart';

/// A horizontally scrolling row of upcoming hourly UV readings.
class ForecastRow extends StatelessWidget {
  final List<UvReading> readings;

  const ForecastRow({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Next 24 hours',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: readings.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _HourTile(reading: readings[i]),
          ),
        ),
      ],
    );
  }
}

class _HourTile extends StatelessWidget {
  final UvReading reading;
  const _HourTile({required this.reading});

  @override
  Widget build(BuildContext context) {
    final scale = UvScale.forValue(reading.uvi);
    final hour = reading.time.hour;
    final label = hour == 0
        ? '12a'
        : hour < 12
            ? '${hour}a'
            : hour == 12
                ? '12p'
                : '${hour - 12}p';

    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: scale.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scale.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scale.color,
              shape: BoxShape.circle,
            ),
            child: Text(
              reading.uvi.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(scale.label,
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
