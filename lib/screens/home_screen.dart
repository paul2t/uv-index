import 'dart:async';

import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/uv_data.dart';
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
  SkinType _skinType = SkinType.iii;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = _Status.loading;
      _isStale = false;
    });

    _skinType = await SettingsService.getSkinType();

    final locationResult = await _locationService.getCurrentLocation();

    if (locationResult is LocationFailure) {
      await _fallbackToCache(locationResult.message);
      return;
    }

    final loc = locationResult as LocationSuccess;
    try {
      final data = await _uvService.fetch(loc.latitude, loc.longitude);
      unawaited(WidgetService.update(data));
      unawaited(NotificationService.checkAndNotify(data));
      if (!mounted) return;
      setState(() {
        _data = data;
        _fetchedAt = DateTime.now();
        _status = _Status.ready;
      });
    } catch (e) {
      await _fallbackToCache('Network error. Showing last known data.');
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
        title: const Text('UV Index'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
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
        return _ErrorView(message: _errorMessage ?? 'Something went wrong.',
            onRetry: _load);
      case _Status.ready:
        return _buildContent();
    }
  }

  Widget _buildContent() {
    final data = _data!;
    final scale = UvScale.forValue(data.now.uvi);
    final burnMins =
        UvScale.minutesToBurn(data.now.uvi, skinFactor: _skinType.burnFactor);
    final peak = data.peakToday;
    final safeReading = data.nextSafeReading;
    final unsafeReading = data.nextUnsafeReading;
    final isSafeNow = data.now.uvi < UvScale.safeThreshold;

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
        Center(child: UvDial(uvi: data.now.uvi)),
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
                  Text('~$burnMins min to burn (unprotected)',
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 8),
                Text(
                  isSafeNow
                      ? unsafeReading != null
                          ? 'Safe to be outside without protection now. '
                              'Protection needed again after '
                              '${_formatHour(unsafeReading.time.hour)}.'
                          : 'Safe to be outside without protection for the '
                              'next 24 hours.'
                      : safeReading != null
                          ? 'Safe without protection after '
                              '${_formatHour(safeReading.time.hour)}.'
                          : 'Stays above safe levels for the next 24 hours.',
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
            "Today's peak: ${peak.uvi.toStringAsFixed(0)} "
            "around ${_formatHour(peak.time.hour)}",
            style: const TextStyle(fontSize: 15),
          ),
        ],
        const SizedBox(height: 24),
        ForecastRow(readings: data.upcomingHours),
        const SizedBox(height: 20),
        if (_fetchedAt != null)
          Center(
            child: Text(
              _isStale
                  ? 'Offline — last updated ${_formatTime(_fetchedAt!)}'
                  : 'Updated ${_formatTime(_fetchedAt!)}',
              style: TextStyle(
                  fontSize: 12,
                  color: _isStale ? Colors.orange[800] : Colors.grey[500]),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: Text('Data: currentuvindex.com',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ),
      ],
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12am';
    if (hour < 12) return '${hour}am';
    if (hour == 12) return '12pm';
    return '${hour - 12}pm';
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
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
          child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}
