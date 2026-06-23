// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Indice UV';

  @override
  String get uvIndexLabel => 'INDICE UV';

  @override
  String get uvLow => 'Faible';

  @override
  String get uvModerate => 'Modéré';

  @override
  String get uvHigh => 'Élevé';

  @override
  String get uvVeryHigh => 'Très élevé';

  @override
  String get uvExtreme => 'Extrême';

  @override
  String get adviceLow =>
      'Aucune protection nécessaire. Vous pouvez sortir sans risque.';

  @override
  String get adviceModerate =>
      'Portez de la crème solaire et recherchez l\'ombre à la mi-journée.';

  @override
  String get adviceHigh =>
      'Protection indispensable. Chapeau, crème solaire, ombre à la mi-journée.';

  @override
  String adviceHighWindow(String start, String end) {
    return 'Protection indispensable. Chapeau, crème solaire, ombre de $start à $end.';
  }

  @override
  String adviceHighUntil(String end) {
    return 'Protection indispensable. Chapeau, crème solaire, ombre jusqu\'à $end.';
  }

  @override
  String get adviceVeryHigh =>
      'Protection renforcée. Évitez le soleil à la mi-journée. Renouvelez la crème solaire.';

  @override
  String get adviceExtreme =>
      'Prenez toutes les précautions. Évitez de sortir à la mi-journée.';

  @override
  String minutesToBurn(int minutes) {
    return '~$minutes min avant coup de soleil (sans protection)';
  }

  @override
  String safeNowWithNext(String time) {
    return 'Vous pouvez sortir sans protection maintenant. Protection à nouveau nécessaire après $time.';
  }

  @override
  String get safeNowAllDay =>
      'Vous pouvez sortir sans protection pendant les prochaines 24 heures.';

  @override
  String safeAfter(String time) {
    return 'Sans protection après $time.';
  }

  @override
  String get staysUnsafeAllDay =>
      'Reste au-dessus du seuil de sécurité pour les prochaines 24 heures.';

  @override
  String todaysPeak(String value, String time) {
    return 'Pic du jour : $value vers $time';
  }

  @override
  String get next24Hours => 'Historique et prévisions';

  @override
  String updatedAt(String time) {
    return 'Mis à jour à $time';
  }

  @override
  String offlineUpdatedAt(String time) {
    return 'Hors ligne — dernière mise à jour à $time';
  }

  @override
  String get dataAttribution => 'Données : currentuvindex.com';

  @override
  String get somethingWrong => 'Une erreur est survenue.';

  @override
  String get retry => 'Réessayer';

  @override
  String get locationServicesOff =>
      'La localisation est désactivée. Activez-la dans les paramètres.';

  @override
  String get locationPermissionDenied =>
      'Autorisation de localisation refusée.';

  @override
  String get locationPermissionDeniedForever =>
      'Autorisation de localisation refusée définitivement. Activez-la dans les paramètres de l\'application.';

  @override
  String get locationTimeout =>
      'Délai dépassé pour obtenir votre position. Réessayez.';

  @override
  String locationError(String error) {
    return 'Impossible d\'obtenir la position : $error';
  }

  @override
  String get networkError =>
      'Erreur réseau. Affichage des dernières données connues.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get locationSection => 'Localisation';

  @override
  String get usingCurrentLocation =>
      'Utilisation de la position actuelle de votre appareil.';

  @override
  String get manualLocationSubtitle =>
      'Position manuelle — appuyez pour effacer';

  @override
  String get searchLocationHint => 'Rechercher une ville ou une adresse';

  @override
  String get noLocationFound => 'Aucun lieu trouvé pour cette recherche.';

  @override
  String get locationSearchError => 'Impossible de rechercher ce lieu.';

  @override
  String get skinTypeSection => 'Type de peau';

  @override
  String get skinTypeDescription =>
      'Utilisé pour estimer le temps avant coup de soleil. Ne constitue pas un avis médical.';

  @override
  String get skinType1 => 'Type I — Très claire, brûle toujours';

  @override
  String get skinType2 => 'Type II — Claire, brûle facilement';

  @override
  String get skinType3 => 'Type III — Moyenne, brûle parfois';

  @override
  String get skinType4 => 'Type IV — Mate, brûle rarement';

  @override
  String get skinType5 => 'Type V — Brune, brûle très rarement';

  @override
  String get skinType6 => 'Type VI — Brun foncé/noire, ne brûle jamais';

  @override
  String get refreshSection => 'Actualisation en arrière-plan';

  @override
  String get refreshDescription =>
      'Fréquence de mise à jour du widget d\'écran d\'accueil en arrière-plan.';

  @override
  String minutesOption(int minutes) {
    return '$minutes minutes';
  }

  @override
  String hoursOption(int hours) {
    return '$hours h';
  }

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get notifyHighTitle => 'L\'indice UV devient élevé';

  @override
  String get notifyHighSubtitle =>
      'Avertir lorsque la protection devient indispensable';

  @override
  String get notifySafeTitle => 'Sortie sans risque';

  @override
  String get notifySafeSubtitle =>
      'Avertir quand l\'indice UV redescend à un niveau sûr';
}
