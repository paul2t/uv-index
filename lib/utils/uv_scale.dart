import 'package:flutter/material.dart';

/// WHO UV Index categories: color bands, risk labels, and safety advice.
class UvScale {
  final String label;
  final Color color;
  final String advice;

  const UvScale._(this.label, this.color, this.advice);

  /// Below this, it's considered safe to be outside without sun protection.
  static const double safeThreshold = 2.5;

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

  /// Rough "minutes to burn" estimate for an unprotected, fair-to-medium
  /// skin type. This is a simplified heuristic for display only — real burn
  /// time depends heavily on individual skin type.
  static int? minutesToBurn(double uvi) {
    if (uvi < 1) return null;
    // Common approximation: ~ 200 / (UVI * skin_factor). Using factor ~3
    // for a typical skin type gives a usable ballpark.
    final minutes = (200 / (uvi * 3)).round();
    return minutes.clamp(5, 240);
  }
}
