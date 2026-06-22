import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

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
  static UvScale forValue(double uvi, AppLocalizations l10n) {
    if (uvi < 3) {
      return UvScale._(l10n.uvLow, colorForValue(uvi), l10n.adviceLow);
    } else if (uvi < 6) {
      return UvScale._(
          l10n.uvModerate, colorForValue(uvi), l10n.adviceModerate);
    } else if (uvi < 8) {
      return UvScale._(l10n.uvHigh, colorForValue(uvi), l10n.adviceHigh);
    } else if (uvi < 11) {
      return UvScale._(
          l10n.uvVeryHigh, colorForValue(uvi), l10n.adviceVeryHigh);
    } else {
      return UvScale._(l10n.uvExtreme, colorForValue(uvi), l10n.adviceExtreme);
    }
  }

  /// Color band only — usable without [AppLocalizations] (e.g. the
  /// home-screen widget, updated from a context-free background isolate).
  static Color colorForValue(double uvi) {
    if (uvi < 3) return const Color(0xFF558B2F); // green
    if (uvi < 6) return const Color(0xFFF9A825); // yellow
    if (uvi < 8) return const Color(0xFFEF6C00); // orange
    if (uvi < 11) return const Color(0xFFD32F2F); // red
    return const Color(0xFF7B1FA2); // purple
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
