import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});
  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabC;
  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _completed = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _tabC = TabController(length: 2, vsync: this); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiClientProvider);

      // Fetch upcoming trips (default: departure_date >= today)
      final upRes = await api.get(Endpoints.driverTrips, queryParameters: {'limit': '50'});
      final upItems = upRes.data is Map ? (upRes.data['items'] ?? []) : [];

      // Fetch completed trips
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final pastRes = await api.get(Endpoints.driverTrips, queryParameters: {'date_to': today, 'status': 'completed', 'limit': '50'});
      final pastItems = pastRes.data is Map ? (pastRes.data['items'] ?? []) : [];

      setState(() {
        _upcoming = List<Map<String, dynamic>>.from(upItems);
        _completed = List<Map<String, dynamic>>.from(pastItems);
        _loading = false;
      });
    } catch (e) {
      debugPrint('TripsScreen error: $e');
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Trips'), bottom: TabBar(controller: _tabC, tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Completed')])),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ]))
            : TabBarView(controller: _tabC, children: [_buildList(_upcoming), _buildList(_completed)]),
  );

  Widget _buildList(List<Map<String, dynamic>> trips) {
    if (trips.isEmpty) return const Center(child: Text('No trips', style: TextStyle(color: AppTheme.textSecondary)));
    return RefreshIndicator(onRefresh: _load, child: ListView.separated(
      padding: const EdgeInsets.all(16), itemCount: trips.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = trips[i]; final route = t['route'] as Map<String, dynamic>? ?? {};
        return InkWell(
          onTap: () => context.push('/trips/${t['id']}'),
          child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${route['origin'] ?? '—'} → ${route['destination'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text((t['status'] as String? ?? '').replaceAll('_', ' '), style: const TextStyle(fontSize: 11, color: AppTheme.primary))),
              ]),
              const SizedBox(height: 6),
              Text('${t['departure_date']} • ${(t['departure_time'] as String?)?.substring(0, 5) ?? ''} • ${t['passenger_count'] ?? 0} pax', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
          ),
        );
      },
    ));
  }
}
