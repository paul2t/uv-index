import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/uv_data.dart';
import '../services/background_service.dart';
import '../services/widget_service.dart';

/// Diagnostic screen for verifying the interpolation/scheduling pipeline
/// against the real device clock and GPS. Developer tool, not localized.
class DebugScreen extends StatefulWidget {
  final UvData data;

  /// When the in-app foreground tick [Timer] is next due to fire — only
  /// known to [HomeScreen]'s live state, not recomputable here, since it
  /// reflects when that timer was actually scheduled, not just the math.
  final DateTime? nextForegroundTick;

  const DebugScreen({
    super.key,
    required this.data,
    required this.nextForegroundTick,
  });

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  DateTime? _lastWidgetPush;
  DateTime? _nextBackgroundTick;
  List<WidgetUpdateEntry> _updateHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lastWidgetPush = await WidgetService.lastUpdateTime();
    final nextBackgroundTick = await BackgroundService.nextBackgroundTickTime();
    final updateHistory = await WidgetService.updateHistory();
    if (!mounted) return;
    setState(() {
      _lastWidgetPush = lastWidgetPush;
      _nextBackgroundTick = nextBackgroundTick;
      _updateHistory = updateHistory;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final now = DateTime.now();
    final precise = data.interpolatedUvi(now);
    final lastRoundedChange = data.lastChangeTime(now);
    final nextRoundedChange = data.nextChangeTime(now);
    final nextPushCandidates = [widget.nextForegroundTick, _nextBackgroundTick]
        .whereType<DateTime>()
        .toList()
      ..sort();
    final nextPush = nextPushCandidates.isEmpty ? null : nextPushCandidates.first;
    final rawJson = const JsonEncoder.withIndent('  ').convert(data.toJson());

    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('UV index', [
                  _row('Precise (interpolated now)', precise.toStringAsFixed(6)),
                  _row('Rounded (displayed)', precise.round().toString()),
                ]),
                _section('Rounded-value timing', [
                  _row('Last changed', _formatTime(lastRoundedChange)),
                  _row('Next change (predicted)', _formatTime(nextRoundedChange)),
                  _row('Next push (foreground or background)', _formatTime(nextPush)),
                  _row('  via foreground tick', _formatTime(widget.nextForegroundTick)),
                  _row('  via background tick', _formatTime(_nextBackgroundTick)),
                  _row('Last actual widget push', _formatTime(_lastWidgetPush)),
                ]),
                _section('Location', [
                  _row('Latitude', data.latitude.toString()),
                  _row('Longitude', data.longitude.toString()),
                ]),
                _section('History (${data.history.length} readings)', [
                  for (final r in data.history) _row(_formatFull(r.time), r.uvi.toString()),
                ]),
                _section('Widget update history (last 24h, ${_updateHistory.length})', [
                  for (final e in _updateHistory.reversed)
                    _row(
                      _formatFull(e.time),
                      '${e.previousValue ?? '—'} → ${e.newValue}  (${e.exactValue.toStringAsFixed(3)})',
                    ),
                ]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Raw cached data',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: rawJson));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(rawJson,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                ),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text('$label: $value',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
    );
  }

  String _formatTime(DateTime? t) {
    if (t == null) return '—';
    return '${_pad(t.hour)}:${_pad(t.minute)}:${_pad(t.second)}';
  }

  String _formatFull(DateTime t) {
    return '${t.year}-${_pad(t.month)}-${_pad(t.day)} ${_formatTime(t)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
