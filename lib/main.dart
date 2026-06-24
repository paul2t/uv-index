import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const UvIndexApp());

  // Best-effort: run after the UI is already up so a stuck permission
  // dialog (e.g. POST_NOTIFICATIONS on Android 13+) or a slow platform
  // channel call can never block the app from showing its first frame.
  unawaited(_initBackgroundServices());
}

Future<void> _initBackgroundServices() async {
  try {
    await BackgroundService.initialize();
    await NotificationService.initialize();
  } catch (_) {
    // Background widget refresh / notifications are best-effort.
  }
}

// Material 3 defaults to a "stretch" overscroll effect on Android; this
// restores the classic glow indicator instead.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    switch (getPlatform(context)) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return GlowingOverscrollIndicator(
          axisDirection: details.direction,
          color: Theme.of(context).colorScheme.secondary,
          child: child,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return child;
    }
  }
}

class UvIndexApp extends StatelessWidget {
  const UvIndexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      scrollBehavior: _AppScrollBehavior(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
