import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

class TripSummaryScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripSummaryScreen({super.key, required this.tripId});
  @override
  ConsumerState<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends ConsumerState<TripSummaryScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(Endpoints.driverTripSummary(widget.tripId));
      setState(() { _summary = res.data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Trip Summary')), body: const Center(child: CircularProgressIndicator()));
    if (_summary == null) return Scaffold(appBar: AppBar(title: const Text('Trip Summary')), body: const Center(child: Text('Summary not available')));

    final s = _summary!;
    final passengers = s['passengers'] as Map<String, dynamic>? ?? {};
    final timing = s['timing'] as Map<String, dynamic>? ?? {};
    final revenue = s['revenue'] as Map<String, dynamic>? ?? {};
    final incidents = s['incidents'] as Map<String, dynamic>? ?? {};
    final inspection = s['inspection'] as Map<String, dynamic>? ?? {};
    final score = s['performance_score'] ?? 0;

    Color scoreColor = score >= 80 ? AppTheme.success : score >= 60 ? AppTheme.warning : AppTheme.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Complete'), backgroundColor: AppTheme.success, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Header
        Center(child: Column(children: [
          const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
          const SizedBox(height: 8),
          Text(s['route_name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(s['departure_date'] ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
        ])),
        const SizedBox(height: 20),

        // Performance Score
        Center(child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scoreColor, width: 4)),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$score', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: scoreColor)),
            Text('/100', style: TextStyle(fontSize: 12, color: scoreColor)),
          ])),
        )),
        const SizedBox(height: 20),

        // Stat cards
        Row(children: [
          Expanded(child: _statCard('Passengers', '${passengers['total_booked'] ?? 0}/${passengers['total_booked'] != null ? passengers['total_booked'] : 0}', '${passengers['occupancy_rate'] ?? 0}% occupancy')),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Checked In', '${passengers['checked_in'] ?? 0}', null)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard('No Shows', '${passengers['no_shows'] ?? 0}', null, color: (passengers['no_shows'] ?? 0) > 0 ? AppTheme.warning : null)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('On Time', timing['on_time'] == true ? 'Yes' : '${(timing['delay_minutes'] ?? 0).toStringAsFixed(0)} min late',
            null, color: timing['on_time'] == true ? AppTheme.success : AppTheme.warning)),
        ]),
        const SizedBox(height: 16),

        // Timing
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Timing', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _infoRow('Duration', '${(timing['trip_duration_minutes'] ?? 0).toStringAsFixed(0)} min'),
          if (incidents['count'] != null) _infoRow('Incidents', '${incidents['count']}'),
          _infoRow('Inspection', inspection['completed'] == true ? (inspection['all_passed'] == true ? 'Passed' : 'Issues found') : 'Not done'),
        ]))),
        const SizedBox(height: 12),

        // Revenue
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          const Text('Revenue', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('\u20A6${(revenue['total'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ]))),
        const SizedBox(height: 24),

        ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Done')),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _statCard(String label, String value, String? sub, {Color? color}) {
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      if (sub != null) Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ])));
  }

  Widget _infoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ]));
  }
}
