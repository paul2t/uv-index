import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'UV Index'**
  String get appTitle;

  /// No description provided for @uvIndexLabel.
  ///
  /// In en, this message translates to:
  /// **'UV INDEX'**
  String get uvIndexLabel;

  /// No description provided for @uvLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get uvLow;

  /// No description provided for @uvModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get uvModerate;

  /// No description provided for @uvHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get uvHigh;

  /// No description provided for @uvVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get uvVeryHigh;

  /// No description provided for @uvExtreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get uvExtreme;

  /// No description provided for @adviceLow.
  ///
  /// In en, this message translates to:
  /// **'No protection needed. Safe to be outside.'**
  String get adviceLow;

  /// No description provided for @adviceModerate.
  ///
  /// In en, this message translates to:
  /// **'Wear sunscreen and seek shade around midday.'**
  String get adviceModerate;

  /// No description provided for @adviceModerateWindow.
  ///
  /// In en, this message translates to:
  /// **'Wear sunscreen and seek shade {start}–{end}.'**
  String adviceModerateWindow(String start, String end);

  /// No description provided for @adviceModerateUntil.
  ///
  /// In en, this message translates to:
  /// **'Wear sunscreen and seek shade until {end}.'**
  String adviceModerateUntil(String end);

  /// No description provided for @adviceHigh.
  ///
  /// In en, this message translates to:
  /// **'Protection essential. Hat, sunscreen, shade around midday.'**
  String get adviceHigh;

  /// No description provided for @adviceHighWindow.
  ///
  /// In en, this message translates to:
  /// **'Protection essential. Hat, sunscreen, shade {start}–{end}.'**
  String adviceHighWindow(String start, String end);

  /// No description provided for @adviceHighUntil.
  ///
  /// In en, this message translates to:
  /// **'Protection essential. Hat, sunscreen, shade until {end}.'**
  String adviceHighUntil(String end);

  /// No description provided for @adviceVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Extra protection. Avoid sun midday. Reapply sunscreen.'**
  String get adviceVeryHigh;

  /// No description provided for @adviceVeryHighWindow.
  ///
  /// In en, this message translates to:
  /// **'Extra protection. Avoid sun {start}–{end}. Reapply sunscreen.'**
  String adviceVeryHighWindow(String start, String end);

  /// No description provided for @adviceVeryHighUntil.
  ///
  /// In en, this message translates to:
  /// **'Extra protection. Avoid sun until {end}. Reapply sunscreen.'**
  String adviceVeryHighUntil(String end);

  /// No description provided for @adviceExtreme.
  ///
  /// In en, this message translates to:
  /// **'Take all precautions. Avoid being outside midday.'**
  String get adviceExtreme;

  /// No description provided for @adviceExtremeWindow.
  ///
  /// In en, this message translates to:
  /// **'Take all precautions. Avoid being outside {start}–{end}.'**
  String adviceExtremeWindow(String start, String end);

  /// No description provided for @adviceExtremeUntil.
  ///
  /// In en, this message translates to:
  /// **'Take all precautions. Avoid being outside until {end}.'**
  String adviceExtremeUntil(String end);

  /// No description provided for @minutesToBurn.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min to burn (unprotected)'**
  String minutesToBurn(int minutes);

  /// No description provided for @safeNowWithNext.
  ///
  /// In en, this message translates to:
  /// **'Safe to be outside without protection now. Protection needed again after {time}.'**
  String safeNowWithNext(String time);

  /// No description provided for @safeNowAllDay.
  ///
  /// In en, this message translates to:
  /// **'Safe to be outside without protection for the next 24 hours.'**
  String get safeNowAllDay;

  /// No description provided for @safeAfter.
  ///
  /// In en, this message translates to:
  /// **'Safe without protection after {time}.'**
  String safeAfter(String time);

  /// No description provided for @staysUnsafeAllDay.
  ///
  /// In en, this message translates to:
  /// **'Stays above safe levels for the next 24 hours.'**
  String get staysUnsafeAllDay;

  /// No description provided for @todaysPeak.
  ///
  /// In en, this message translates to:
  /// **'Today\'s peak: {value} around {time}'**
  String todaysPeak(String value, String time);

  /// No description provided for @next24Hours.
  ///
  /// In en, this message translates to:
  /// **'History & forecast'**
  String get next24Hours;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedAt(String time);

  /// No description provided for @offlineUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Offline — last updated {time}'**
  String offlineUpdatedAt(String time);

  /// No description provided for @dataAttribution.
  ///
  /// In en, this message translates to:
  /// **'Data: currentuvindex.com'**
  String get dataAttribution;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWrong;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @locationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off. Enable them in settings.'**
  String get locationServicesOff;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Enable it in app settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timed out getting your location. Try again.'**
  String get locationTimeout;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get location: {error}'**
  String locationError(String error);

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Showing last known data.'**
  String get networkError;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @locationSection.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSection;

  /// No description provided for @usingCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Using your device\'s current location.'**
  String get usingCurrentLocation;

  /// No description provided for @manualLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manual override — tap to clear'**
  String get manualLocationSubtitle;

  /// No description provided for @searchLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Search city or address'**
  String get searchLocationHint;

  /// No description provided for @noLocationFound.
  ///
  /// In en, this message translates to:
  /// **'No location found for that search.'**
  String get noLocationFound;

  /// No description provided for @locationSearchError.
  ///
  /// In en, this message translates to:
  /// **'Could not search for that location.'**
  String get locationSearchError;

  /// No description provided for @skinTypeSection.
  ///
  /// In en, this message translates to:
  /// **'Skin type'**
  String get skinTypeSection;

  /// No description provided for @skinTypeDescription.
  ///
  /// In en, this message translates to:
  /// **'Used to estimate time-to-burn. Not medical advice.'**
  String get skinTypeDescription;

  /// No description provided for @skinType1.
  ///
  /// In en, this message translates to:
  /// **'Type I — Very fair, always burns'**
  String get skinType1;

  /// No description provided for @skinType2.
  ///
  /// In en, this message translates to:
  /// **'Type II — Fair, burns easily'**
  String get skinType2;

  /// No description provided for @skinType3.
  ///
  /// In en, this message translates to:
  /// **'Type III — Medium, sometimes burns'**
  String get skinType3;

  /// No description provided for @skinType4.
  ///
  /// In en, this message translates to:
  /// **'Type IV — Olive, rarely burns'**
  String get skinType4;

  /// No description provided for @skinType5.
  ///
  /// In en, this message translates to:
  /// **'Type V — Brown, very rarely burns'**
  String get skinType5;

  /// No description provided for @skinType6.
  ///
  /// In en, this message translates to:
  /// **'Type VI — Dark brown/black, never burns'**
  String get skinType6;

  /// No description provided for @refreshSection.
  ///
  /// In en, this message translates to:
  /// **'Background refresh'**
  String get refreshSection;

  /// No description provided for @refreshDescription.
  ///
  /// In en, this message translates to:
  /// **'How often the home-screen widget updates in the background.'**
  String get refreshDescription;

  /// No description provided for @minutesOption.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String minutesOption(int minutes);

  /// No description provided for @hoursOption.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String hoursOption(int hours);

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @notifyHighTitle.
  ///
  /// In en, this message translates to:
  /// **'UV becomes High'**
  String get notifyHighTitle;

  /// No description provided for @notifyHighSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when protection becomes essential'**
  String get notifyHighSubtitle;

  /// No description provided for @notifySafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe to go outside'**
  String get notifySafeTitle;

  /// No description provided for @notifySafeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when UV drops back to a safe level'**
  String get notifySafeSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
