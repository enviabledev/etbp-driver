import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});
  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  Map<String, dynamic>? _trip;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(Endpoints.driverTripDetail(widget.tripId));
      setState(() { _trip = res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(Endpoints.driverTripStatus(widget.tripId), data: {'status': newStatus});
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    if (_trip == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Trip not found')));

    final t = _trip!;
    final route = t['route'] as Map<String, dynamic>? ?? {};
    final origin = (route['origin_terminal'] as Map<String, dynamic>?)?['city'] ?? '—';
    final dest = (route['destination_terminal'] as Map<String, dynamic>?)?['city'] ?? '—';
    final status = t['status'] as String? ?? 'scheduled';

    return Scaffold(
      appBar: AppBar(title: Text('$origin → $dest')),
      body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
        // Status
        Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(status.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)))),
        const SizedBox(height: 16),

        // Trip info card
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Trip Details', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _info('Route', route['name'] ?? '$origin → $dest'),
          _info('Date', t['departure_date'] ?? '—'),
          _info('Time', (t['departure_time'] as String?)?.substring(0, 5) ?? '—'),
          if (t['vehicle'] != null) _info('Vehicle', (t['vehicle'] as Map)['plate_number'] ?? '—'),
          _info('Total Seats', '${t['total_seats']}'),
        ]))),
        const SizedBox(height: 12),

        // Passengers card
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Passengers', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${t['passengers_booked'] ?? 0} booked · ${t['passengers_checked_in'] ?? 0} checked in', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/trips/${widget.tripId}/manifest'),
            icon: const Icon(Icons.list_alt, size: 18), label: const Text('View Full Manifest'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          ),
        ]))),
        const SizedBox(height: 16),

        // Action buttons
        if (status == 'scheduled' || status == 'boarding') ...[
          ElevatedButton.icon(onPressed: _updating ? null : () => _updateStatus('departed'),
            icon: const Icon(Icons.play_arrow), label: const Text('Mark Departed'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success)),
        ],
        if (status == 'departed') ...[
          ElevatedButton.icon(onPressed: _updating ? null : () => _updateStatus('en_route'),
            icon: const Icon(Icons.route), label: const Text('Mark En Route'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning)),
        ],
        if (status == 'en_route') ...[
          ElevatedButton.icon(onPressed: _updating ? null : () => _updateStatus('arrived'),
            icon: const Icon(Icons.flag), label: const Text('Mark Arrived')),
        ],
        if (status == 'arrived') ...[
          ElevatedButton.icon(onPressed: _updating ? null : () => _updateStatus('completed'),
            icon: const Icon(Icons.check_circle), label: const Text('Complete Trip'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success)),
        ],
      ])),
    );
  }

  Widget _info(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
    SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
  ]));
}
