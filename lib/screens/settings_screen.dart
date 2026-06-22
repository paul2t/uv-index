import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/background_service.dart';
import '../services/geocoding_service.dart';
import '../services/settings_service.dart';

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
        setState(() => _searchError = 'No location found for that search.');
        return;
      }
      await SettingsService.setManualLocation(result);
      setState(() => _manualLocation = result);
    } catch (e) {
      setState(() => _searchError = 'Could not search for that location.');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionHeader('Location'),
                if (_manualLocation != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(_manualLocation!.label),
                    subtitle: const Text('Manual override — tap to clear'),
                    trailing: const Icon(Icons.close),
                    onTap: _clearManualLocation,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Using your device\'s current location.'),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          hintText: 'Search city or address',
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
                _SectionHeader('Skin type'),
                const Text(
                  'Used to estimate time-to-burn. Not medical advice.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                DropdownButton<SkinType>(
                  isExpanded: true,
                  value: _skinType,
                  items: SkinType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: _onSkinTypeChanged,
                ),
                const SizedBox(height: 24),
                _SectionHeader('Background refresh'),
                const Text(
                  'How often the home-screen widget updates in the background.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  isExpanded: true,
                  value: _refreshMinutes,
                  items: SettingsService.refreshIntervalOptions
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m < 60 ? '$m minutes' : '${m ~/ 60}h'),
                          ))
                      .toList(),
                  onChanged: _onRefreshIntervalChanged,
                ),
                const SizedBox(height: 24),
                _SectionHeader('Notifications'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('UV becomes High'),
                  subtitle: const Text('Notify when protection becomes essential'),
                  value: _notifyHigh,
                  onChanged: _onNotifyHighChanged,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Safe to go outside'),
                  subtitle: const Text('Notify when UV drops back to a safe level'),
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
