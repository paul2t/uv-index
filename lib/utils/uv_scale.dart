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

  /// At and above this, the WHO "Moderate" band begins.
  static const double moderateThreshold = 3;

  /// At and above this, the WHO "High" band begins — protection essential.
  static const double highThreshold = 6;

  /// At and above this, the WHO "Very High" band begins.
  static const double veryHighThreshold = 8;

  /// At and above this, the WHO "Extreme" band begins.
  static const double extremeThreshold = 11;

  /// The raw value below which an already-rounded [roundedValue] would round
  /// down into the next lower band — i.e. the threshold to pass to
  /// [UvData.todaysProtectionWindow] so its `end` reports exactly when the
  /// band currently being described stops applying. Null for the "Low" band,
  /// which has no protection deadline to report.
  static double? protectionThresholdFor(double roundedValue) {
    if (roundedValue >= extremeThreshold) return extremeThreshold - 0.5;
    if (roundedValue >= veryHighThreshold) return veryHighThreshold - 0.5;
    if (roundedValue >= highThreshold) return highThreshold - 0.5;
    if (roundedValue >= moderateThreshold) return moderateThreshold - 0.5;
    return null;
  }

  /// Returns the scale category for a given UV index value. [protectionStart]
  /// and [protectionEnd] are pre-formatted, locale-aware time strings for
  /// the window during which the current band applies (see
  /// [UvData.todaysProtectionWindow] with [protectionThresholdFor]) — when
  /// given, the advice names the actual predicted window/end time instead of
  /// a generic time of day. [protectionStart] may be null (the window's
  /// start isn't reliably known from available data) while [protectionEnd]
  /// is given, in which case the advice only mentions the end.
  static UvScale forValue(double uvi, AppLocalizations l10n,
      {String? protectionStart, String? protectionEnd}) {
    if (uvi < moderateThreshold) {
      return UvScale._(l10n.uvLow, colorForValue(uvi), l10n.adviceLow);
    } else if (uvi < highThreshold) {
      return UvScale._(
          l10n.uvModerate,
          colorForValue(uvi),
          _protectionAdvice(
            start: protectionStart,
            end: protectionEnd,
            window: l10n.adviceModerateWindow,
            until: l10n.adviceModerateUntil,
            generic: l10n.adviceModerate,
          ));
    } else if (uvi < veryHighThreshold) {
      return UvScale._(
          l10n.uvHigh,
          colorForValue(uvi),
          _protectionAdvice(
            start: protectionStart,
            end: protectionEnd,
            window: l10n.adviceHighWindow,
            until: l10n.adviceHighUntil,
            generic: l10n.adviceHigh,
          ));
    } else if (uvi < extremeThreshold) {
      return UvScale._(
          l10n.uvVeryHigh,
          colorForValue(uvi),
          _protectionAdvice(
            start: protectionStart,
            end: protectionEnd,
            window: l10n.adviceVeryHighWindow,
            until: l10n.adviceVeryHighUntil,
            generic: l10n.adviceVeryHigh,
          ));
    } else {
      return UvScale._(
          l10n.uvExtreme,
          colorForValue(uvi),
          _protectionAdvice(
            start: protectionStart,
            end: protectionEnd,
            window: l10n.adviceExtremeWindow,
            until: l10n.adviceExtremeUntil,
            generic: l10n.adviceExtreme,
          ));
    }
  }

  static String _protectionAdvice({
    required String? start,
    required String? end,
    required String Function(String start, String end) window,
    required String Function(String end) until,
    required String generic,
  }) {
    if (start != null && end != null) return window(start, end);
    if (end != null) return until(end);
    return generic;
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
