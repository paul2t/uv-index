import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/uv_data.dart';
import '../services/background_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/uv_service.dart';
import '../services/widget_service.dart';
import '../utils/uv_scale.dart';
import '../widgets/uv_dial.dart';
import '../widgets/forecast_row.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Status { loading, ready, error }

class _HomeScreenState extends State<HomeScreen> {
  final _uvService = UvService();
  final _locationService = LocationService();

  _Status _status = _Status.loading;
  UvData? _data;
  String? _errorMessage;
  DateTime? _fetchedAt;
  bool _isStale = false; // true when showing cached data after a failure
  bool _refreshing = false; // a fetch is in flight while data is already shown
  SkinType _skinType = SkinType.iii;
  Timer? _uiTickTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _uiTickTimer?.cancel();
    super.dispose();
  }

  /// Refreshes the displayed UV value, advice, and safe/unsafe predictions
  /// by re-running the linear interpolation against the current time — no
  /// network involved. Scheduled for exactly the next moment the
  /// interpolated value would change by [_uiTickStep] (matching UvDial's
  /// one-decimal display — finer than the widget's rounded-integer ticks),
  /// then reschedules itself from there.
  static const _uiTickStep = 0.1;
  static const _minUiTickDelay = Duration(seconds: 5);

  void _scheduleUiTick() {
    _uiTickTimer?.cancel();
    final data = _data;
    if (data == null) return;
    final next = data.nextChangeTime(DateTime.now(), step: _uiTickStep);
    if (next == null) return;
    final delay = next.difference(DateTime.now());
    _uiTickTimer = Timer(delay < _minUiTickDelay ? _minUiTickDelay : delay, () {
      if (!mounted) return;
      setState(() {});
      // Keep the home-screen widget in sync too — otherwise it only
      // refreshes via the separate, coarser background tick chain, which
      // can lag behind while the app sits open and visibly ticking.
      final current = _data;
      if (current != null) {
        unawaited(WidgetService.update(current.interpolatedNow));
      }
      _scheduleUiTick();
    });
  }

  // GPS often takes a while to lock on. Rather than make the user wait the
  // full time on every open, try briefly first; if that times out, use
  // where we were last time (logged in the cached data) to fetch right
  // away, and only fall all the way back to waiting on a fresh location if
  // we have no previous position at all.
  static const _quickLocationTimeout = Duration(seconds: 2);
  static const _fullLocationTimeout = Duration(seconds: 15);

  // Below this, a better location fix isn't worth a second, visible fetch
  // — UV index doesn't vary meaningfully over short distances.
  static const _significantMoveMeters = 20000.0;

  Future<void> _load() async {
    // Only blank the screen to a spinner on the very first load. If we
    // already have data on screen (e.g. returning from Settings, or a
    // pull-to-refresh), keep showing it and refresh quietly in the
    // background instead.
    final hasDataAlready = _data != null;
    setState(() {
      if (!hasDataAlready) _status = _Status.loading;
      _refreshing = true;
    });

    _skinType = await SettingsService.getSkinType();

    // Nudge the widget from cached history/forecast data right away —
    // cheap and network-free — before attempting the real API fetch below.
    final cached = await _uvService.loadCached();
    if (cached != null) {
      unawaited(WidgetService.update(
          cached.data.interpolatedUvi(DateTime.now())));
    }

    var locationResult =
        await _locationService.getCurrentLocation(timeout: _quickLocationTimeout);

    if (locationResult is LocationFailure &&
        locationResult.reason == LocationFailureReason.timeout) {
      if (cached != null) {
        locationResult =
            LocationSuccess(cached.data.latitude, cached.data.longitude);
        unawaited(_refineLocationInBackground(
            cached.data.latitude, cached.data.longitude));
      } else {
        // No previous position to fall back to — give it more time.
        locationResult = await _locationService
            .getCurrentLocation(timeout: _fullLocationTimeout);
      }
    }

    if (locationResult is LocationFailure) {
      if (!mounted) return;
      final reason = _locationErrorMessage(locationResult);
      _showFetchError(reason);
      await _fallbackToCache(reason);
      if (mounted) setState(() => _refreshing = false);
      return;
    }

    final loc = locationResult as LocationSuccess;
    try {
      final data = await _uvService.fetch(loc.latitude, loc.longitude);
      await _applySuccessfulFetch(data);
    } catch (e) {
      if (!mounted) return;
      _showFetchError('${AppLocalizations.of(context)!.networkError}\n$e');
      await _fallbackToCache(AppLocalizations.of(context)!.networkError);
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// Quietly checks for a more accurate position after we've already shown
  /// data for the last-known one — no progress indicator, since the user
  /// already has something on screen. Only triggers a second, visible
  /// fetch if the better fix turns out to be at least
  /// [_significantMoveMeters] away from the position we just used.
  Future<void> _refineLocationInBackground(double oldLat, double oldLng) async {
    final refined = await _locationService
        .getCurrentLocation(timeout: _fullLocationTimeout);
    if (refined is! LocationSuccess) return;

    final movedMeters = LocationService.distanceBetween(
        oldLat, oldLng, refined.latitude, refined.longitude);
    if (movedMeters < _significantMoveMeters) return;

    if (!mounted) return;
    setState(() => _refreshing = true);
    try {
      final data = await _uvService.fetch(refined.latitude, refined.longitude);
      await _applySuccessfulFetch(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _refreshing = false);
    }
  }

  Future<void> _applySuccessfulFetch(UvData data) async {
    unawaited(WidgetService.update(data.now.uvi));
    unawaited(NotificationService.checkAndNotify(data));
    unawaited(BackgroundService.scheduleNextTick(data));
    if (!mounted) return;
    setState(() {
      _data = data;
      _fetchedAt = DateTime.now();
      _isStale = false;
      _status = _Status.ready;
      _refreshing = false;
    });
    _scheduleUiTick();
  }

  /// Surfaces the exact failure reason in a SnackBar so it's visible
  /// without attaching a debugger — useful in release builds, where the
  /// existing inline "offline" banner intentionally only shows a generic,
  /// localized message.
  void _showFetchError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _locationErrorMessage(LocationFailure failure) {
    final l10n = AppLocalizations.of(context)!;
    switch (failure.reason) {
      case LocationFailureReason.servicesDisabled:
        return l10n.locationServicesOff;
      case LocationFailureReason.permissionDenied:
        return l10n.locationPermissionDenied;
      case LocationFailureReason.permissionDeniedForever:
        return l10n.locationPermissionDeniedForever;
      case LocationFailureReason.timeout:
        return l10n.locationTimeout;
      case LocationFailureReason.unknown:
        return l10n.locationError(failure.detail ?? '');
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    _load();
  }

  Future<void> _fallbackToCache(String reason) async {
    final cached = await _uvService.loadCached();
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _data = cached.data;
        _fetchedAt = cached.fetchedAt;
        _isStale = true;
        _status = _Status.ready;
      });
      _scheduleUiTick();
    } else {
      setState(() {
        _errorMessage = reason;
        _status = _Status.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
        bottom: _refreshing && _status == _Status.ready
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _Status.loading:
        return const Center(child: CircularProgressIndicator());
      case _Status.error:
        return _ErrorView(
            message: _errorMessage ?? AppLocalizations.of(context)!.somethingWrong,
            onRetry: _load);
      case _Status.ready:
        return _buildContent();
    }
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;
    final data = _data!;
    final currentUvi = data.interpolatedNow;
    final window = data.todaysProtectionWindow;
    // Color, label, and advice come from the rounded value — matching the
    // dial and the widget — so the card's tint never disagrees with the
    // number shown just above it.
    final scale = UvScale.forValue(currentUvi.roundToDouble(), l10n,
        protectionStart:
            window.start != null ? _formatTime(context, window.start!) : null,
        protectionEnd: _formatTime(context, window.end));
    final burnMins =
        UvScale.minutesToBurn(currentUvi, skinFactor: _skinType.burnFactor);
    final peak = data.peakToday;
    final nextSafeTime = data.nextSafeTime;
    final nextUnsafeTime = data.nextUnsafeTime;
    final isSafeNow = currentUvi < UvScale.safeThreshold;

    return ListView(
      // AlwaysScrollable so pull-to-refresh works even when content is short.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${data.latitude.toStringAsFixed(2)}, ${data.longitude.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        Center(child: UvDial(uvi: currentUvi)),
        const SizedBox(height: 24),
        Card(
          color: scale.color.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scale.advice,
                    style: const TextStyle(fontSize: 15, height: 1.4)),
                if (burnMins != null) ...[
                  const SizedBox(height: 8),
                  Text(l10n.minutesToBurn(burnMins),
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 8),
                Text(
                  isSafeNow
                      ? nextUnsafeTime != null
                          ? l10n.safeNowWithNext(
                              _formatTime(context, nextUnsafeTime))
                          : l10n.safeNowAllDay
                      : nextSafeTime != null
                          ? l10n.safeAfter(
                              _formatTime(context, nextSafeTime))
                          : l10n.staysUnsafeAllDay,
                  style: TextStyle(
                      color: Colors.grey[700], fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        if (peak != null) ...[
          const SizedBox(height: 16),
          Text(
            l10n.todaysPeak(peak.uvi.toStringAsFixed(0),
                _formatHour(context, peak.time.hour)),
            style: const TextStyle(fontSize: 15),
          ),
        ],
        const SizedBox(height: 24),
        ForecastRow(readings: data.chartReadings),
        const SizedBox(height: 20),
        if (_fetchedAt != null)
          Center(
            child: Text(
              _isStale
                  ? l10n.offlineUpdatedAt(_formatTime(context, _fetchedAt!))
                  : l10n.updatedAt(_formatTime(context, _fetchedAt!)),
              style: TextStyle(
                  fontSize: 12,
                  color: _isStale ? Colors.orange[800] : Colors.grey[500]),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: Text(l10n.dataAttribution,
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ),
      ],
    );
  }

  /// Locale-aware hour formatting: 24h digits for French, 12h am/pm short
  /// form for English and other locales.
  String _formatHour(BuildContext context, int hour) {
    if (Localizations.localeOf(context).languageCode == 'fr') {
      return '${hour}h';
    }
    if (hour == 0) return '12am';
    if (hour < 12) return '${hour}am';
    if (hour == 12) return '12pm';
    return '${hour - 12}pm';
  }

  String _formatTime(BuildContext context, DateTime t) {
    final m = t.minute.toString().padLeft(2, '0');
    if (Localizations.localeOf(context).languageCode == 'fr') {
      final h = t.hour.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour < 12 ? 'am' : 'pm';
    return '$h:$m$ampm';
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Icon(Icons.wb_sunny_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry)),
        ),
      ],
    );
  }
}
