import 'package:flutter/material.dart';

/// WHO UV Index categories: color bands, risk labels, and safety advice.
class UvScale {
  final String label;
  final Color color;
  final String advice;

  const UvScale._(this.label, this.color, this.advice);

  /// Below this, it's considered safe to be outside without sun protection.
  static const double safeThreshold = 2.5;

  /// At and above this, the WHO "High" band begins — protection essential.
  static const double highThreshold = 6;

  /// Returns the scale category for a given UV index value.
  static UvScale forValue(double uvi) {
    if (uvi < 3) {
      return const UvScale._(
        'Low',
        Color(0xFF558B2F), // green
        'No protection needed. Safe to be outside.',
      );
    } else if (uvi < 6) {
      return const UvScale._(
        'Moderate',
        Color(0xFFF9A825), // yellow
        'Wear sunscreen and seek shade around midday.',
      );
    } else if (uvi < 8) {
      return const UvScale._(
        'High',
        Color(0xFFEF6C00), // orange
        'Protection essential. Hat, sunscreen, shade 11am–4pm.',
      );
    } else if (uvi < 11) {
      return const UvScale._(
        'Very High',
        Color(0xFFD32F2F), // red
        'Extra protection. Avoid sun midday. Reapply sunscreen.',
      );
    } else {
      return const UvScale._(
        'Extreme',
        Color(0xFF7B1FA2), // purple
        'Take all precautions. Avoid being outside midday.',
      );
    }
  }

  /// Rough "minutes to burn" estimate for an unprotected user. [skinFactor]
  /// comes from [SkinType.burnFactor] — higher values burn slower. This is a
  /// simplified heuristic for display only, not medical advice.
  static int? minutesToBurn(double uvi, {double skinFactor = 3.0}) {
    if (uvi < 1) return null;
    // Common approximation: ~ 200 / (UVI * skin_factor).
    final minutes = (200 / (uvi * skinFactor)).round();
    return minutes.clamp(5, 240);
  }
}
