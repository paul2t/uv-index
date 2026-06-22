import 'package:flutter/material.dart';
import '../utils/uv_scale.dart';

/// The big circular UV index display — number, color band, and risk label.
class UvDial extends StatelessWidget {
  final double uvi;

  const UvDial({super.key, required this.uvi});

  @override
  Widget build(BuildContext context) {
    final scale = UvScale.forValue(uvi);

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [scale.color.withValues(alpha: 0.95), scale.color],
        ),
        boxShadow: [
          BoxShadow(
            color: scale.color.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'UV INDEX',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            uvi.toStringAsFixed(uvi < 10 ? 1 : 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 76,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          Text(
            scale.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
