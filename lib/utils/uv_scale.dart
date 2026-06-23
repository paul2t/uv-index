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

  /// Returns the scale category for a given UV index value. [protectionStart]
  /// and [protectionEnd] are pre-formatted, locale-aware time strings for
  /// today's protection window (see [UvData.todaysProtectionWindow]) — when
  /// given, the "High" advice names the actual predicted window instead of a
  /// generic time of day. [protectionStart] may be null (the window's start
  /// isn't reliably known from available data) while [protectionEnd] is
  /// given, in which case the advice only mentions the end.
  static UvScale forValue(double uvi, AppLocalizations l10n,
      {String? protectionStart, String? protectionEnd}) {
    if (uvi < 3) {
      return UvScale._(l10n.uvLow, colorForValue(uvi), l10n.adviceLow);
    } else if (uvi < 6) {
      return UvScale._(
          l10n.uvModerate, colorForValue(uvi), l10n.adviceModerate);
    } else if (uvi < 8) {
      final String advice;
      if (protectionStart != null && protectionEnd != null) {
        advice = l10n.adviceHighWindow(protectionStart, protectionEnd);
      } else if (protectionEnd != null) {
        advice = l10n.adviceHighUntil(protectionEnd);
      } else {
        advice = l10n.adviceHigh;
      }
      return UvScale._(l10n.uvHigh, colorForValue(uvi), advice);
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
  /// comes from [SkinType.burnFactor] — higher values burn slower, so this
  /// scales the baseline time *up* for higher factors (not down). Calibrated
  /// against the app's default skin factor (3.0, Type III) so that default
  /// case matches the original heuristic exactly. Simplified heuristic for
  /// display only, not medical advice.
  static int? minutesToBurn(double uvi, {double skinFactor = 3.0}) {
    if (uvi < 1) return null;
    const defaultFactor = 3.0;
    final baselineMinutes = 200 / (uvi * defaultFactor);
    final minutes = (baselineMinutes * skinFactor / defaultFactor).round();
    return minutes.clamp(5, 240);
  }
}
