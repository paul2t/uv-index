import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../services/background_service.dart';
import '../services/geocoding_service.dart';
import '../services/settings_service.dart';

String _skinTypeLabel(AppLocalizations l10n, SkinType type) {
  switch (type) {
    case SkinType.i:
      return l10n.skinType1;
    case SkinType.ii:
      return l10n.skinType2;
    case SkinType.iii:
      return l10n.skinType3;
    case SkinType.iv:
      return l10n.skinType4;
    case SkinType.v:
      return l10n.skinType5;
    case SkinType.vi:
      return l10n.skinType6;
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _locationController = TextEditingController();

  bool _loading = true;
  SkinType _skinType = SkinType.iii;
  int _refreshMinutes = 60;
  bool _notifyHigh = true;
  bool _notifySafe = true;
  ManualLocation? _manualLocation;
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final skinType = await SettingsService.getSkinType();
    final refreshMinutes = await SettingsService.getRefreshIntervalMinutes();
    final notifyHigh = await SettingsService.getNotifyHigh();
    final notifySafe = await SettingsService.getNotifySafe();
    final manualLocation = await SettingsService.getManualLocation();
    if (!mounted) return;
    setState(() {
      _skinType = skinType;
      _refreshMinutes = refreshMinutes;
      _notifyHigh = notifyHigh;
      _notifySafe = notifySafe;
      _manualLocation = manualLocation;
      _loading = false;
    });
  }

  Future<void> _onSkinTypeChanged(SkinType? type) async {
    if (type == null) return;
    await SettingsService.setSkinType(type);
    setState(() => _skinType = type);
  }

  Future<void> _onRefreshIntervalChanged(int? minutes) async {
    if (minutes == null) return;
    await BackgroundService.updateRefreshInterval(minutes);
    setState(() => _refreshMinutes = minutes);
  }

  Future<void> _onNotifyHighChanged(bool value) async {
    await SettingsService.setNotifyHigh(value);
    setState(() => _notifyHigh = value);
  }

  Future<void> _onNotifySafeChanged(bool value) async {
    await SettingsService.setNotifySafe(value);
    setState(() => _notifySafe = value);
  }

  Future<void> _searchLocation() async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final result = await GeocodingService.search(_locationController.text);
      if (result == null) {
        if (mounted) {
          setState(() =>
              _searchError = AppLocalizations.of(context)!.noLocationFound);
        }
        return;
      }
      await SettingsService.setManualLocation(result);
      setState(() => _manualLocation = result);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _searchError = AppLocalizations.of(context)!.locationSearchError);
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _clearManualLocation() async {
    await SettingsService.setManualLocation(null);
    setState(() {
      _manualLocation = null;
      _locationController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionHeader(l10n.locationSection),
                if (_manualLocation != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(_manualLocation!.label),
                    subtitle: Text(l10n.manualLocationSubtitle),
                    trailing: const Icon(Icons.close),
                    onTap: _clearManualLocation,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(l10n.usingCurrentLocation),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: l10n.searchLocationHint,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _searching
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _searchLocation,
                          ),
                  ],
                ),
                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_searchError!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 24),
                _SectionHeader(l10n.skinTypeSection),
                Text(
                  l10n.skinTypeDescription,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                DropdownButton<SkinType>(
                  isExpanded: true,
                  value: _skinType,
                  items: SkinType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_skinTypeLabel(l10n, t)),
                          ))
                      .toList(),
                  onChanged: _onSkinTypeChanged,
                ),
                const SizedBox(height: 24),
                _SectionHeader(l10n.refreshSection),
                Text(
                  l10n.refreshDescription,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  isExpanded: true,
                  value: _refreshMinutes,
                  items: SettingsService.refreshIntervalOptions
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m < 60
                                ? l10n.minutesOption(m)
                                : l10n.hoursOption(m ~/ 60)),
                          ))
                      .toList(),
                  onChanged: _onRefreshIntervalChanged,
                ),
                const SizedBox(height: 24),
                _SectionHeader(l10n.notificationsSection),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notifyHighTitle),
                  subtitle: Text(l10n.notifyHighSubtitle),
                  value: _notifyHigh,
                  onChanged: _onNotifyHighChanged,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notifySafeTitle),
                  subtitle: Text(l10n.notifySafeSubtitle),
                  value: _notifySafe,
                  onChanged: _onNotifySafeChanged,
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}
