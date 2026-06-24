// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'UV Index';

  @override
  String get uvIndexLabel => 'UV INDEX';

  @override
  String get uvLow => 'Low';

  @override
  String get uvModerate => 'Moderate';

  @override
  String get uvHigh => 'High';

  @override
  String get uvVeryHigh => 'Very High';

  @override
  String get uvExtreme => 'Extreme';

  @override
  String get adviceLow => 'No protection needed. Safe to be outside.';

  @override
  String get adviceModerate => 'Wear sunscreen and seek shade around midday.';

  @override
  String adviceModerateWindow(String start, String end) {
    return 'Wear sunscreen and seek shade $start–$end.';
  }

  @override
  String adviceModerateUntil(String end) {
    return 'Wear sunscreen and seek shade until $end.';
  }

  @override
  String get adviceHigh =>
      'Protection essential. Hat, sunscreen, shade around midday.';

  @override
  String adviceHighWindow(String start, String end) {
    return 'Protection essential. Hat, sunscreen, shade $start–$end.';
  }

  @override
  String adviceHighUntil(String end) {
    return 'Protection essential. Hat, sunscreen, shade until $end.';
  }

  @override
  String get adviceVeryHigh =>
      'Extra protection. Avoid sun midday. Reapply sunscreen.';

  @override
  String adviceVeryHighWindow(String start, String end) {
    return 'Extra protection. Avoid sun $start–$end. Reapply sunscreen.';
  }

  @override
  String adviceVeryHighUntil(String end) {
    return 'Extra protection. Avoid sun until $end. Reapply sunscreen.';
  }

  @override
  String get adviceExtreme =>
      'Take all precautions. Avoid being outside midday.';

  @override
  String adviceExtremeWindow(String start, String end) {
    return 'Take all precautions. Avoid being outside $start–$end.';
  }

  @override
  String adviceExtremeUntil(String end) {
    return 'Take all precautions. Avoid being outside until $end.';
  }

  @override
  String minutesToBurn(int minutes) {
    return '~$minutes min to burn (unprotected)';
  }

  @override
  String safeNowWithNext(String time) {
    return 'Safe to be outside without protection now. Protection needed again after $time.';
  }

  @override
  String get safeNowAllDay =>
      'Safe to be outside without protection for the next 24 hours.';

  @override
  String safeAfter(String time) {
    return 'Safe without protection after $time.';
  }

  @override
  String get staysUnsafeAllDay =>
      'Stays above safe levels for the next 24 hours.';

  @override
  String todaysPeak(String value, String time) {
    return 'Today\'s peak: $value around $time';
  }

  @override
  String get next24Hours => 'History & forecast';

  @override
  String updatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String offlineUpdatedAt(String time) {
    return 'Offline — last updated $time';
  }

  @override
  String get dataAttribution => 'Data: currentuvindex.com';

  @override
  String get somethingWrong => 'Something went wrong.';

  @override
  String get retry => 'Retry';

  @override
  String get locationServicesOff =>
      'Location services are off. Enable them in settings.';

  @override
  String get locationPermissionDenied => 'Location permission denied.';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission permanently denied. Enable it in app settings.';

  @override
  String get locationTimeout => 'Timed out getting your location. Try again.';

  @override
  String locationError(String error) {
    return 'Could not get location: $error';
  }

  @override
  String get networkError => 'Network error. Showing last known data.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get locationSection => 'Location';

  @override
  String get usingCurrentLocation => 'Using your device\'s current location.';

  @override
  String get manualLocationSubtitle => 'Manual override — tap to clear';

  @override
  String get searchLocationHint => 'Search city or address';

  @override
  String get noLocationFound => 'No location found for that search.';

  @override
  String get locationSearchError => 'Could not search for that location.';

  @override
  String get skinTypeSection => 'Skin type';

  @override
  String get skinTypeDescription =>
      'Used to estimate time-to-burn. Not medical advice.';

  @override
  String get skinType1 => 'Type I — Very fair, always burns';

  @override
  String get skinType2 => 'Type II — Fair, burns easily';

  @override
  String get skinType3 => 'Type III — Medium, sometimes burns';

  @override
  String get skinType4 => 'Type IV — Olive, rarely burns';

  @override
  String get skinType5 => 'Type V — Brown, very rarely burns';

  @override
  String get skinType6 => 'Type VI — Dark brown/black, never burns';

  @override
  String get refreshSection => 'Background refresh';

  @override
  String get refreshDescription =>
      'How often the home-screen widget updates in the background.';

  @override
  String minutesOption(int minutes) {
    return '$minutes minutes';
  }

  @override
  String hoursOption(int hours) {
    return '${hours}h';
  }

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get notifyHighTitle => 'UV becomes High';

  @override
  String get notifyHighSubtitle => 'Notify when protection becomes essential';

  @override
  String get notifySafeTitle => 'Safe to go outside';

  @override
  String get notifySafeSubtitle => 'Notify when UV drops back to a safe level';
}
