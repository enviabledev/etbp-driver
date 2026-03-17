import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> _todayTrips = [];
  List<Map<String, dynamic>> _upcomingTrips = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final threeDaysOut = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 3)));

      // Single API call — fetch trips within the next 3 days
      final res = await api.get(Endpoints.driverTrips, queryParameters: {'date_from': today, 'date_to': threeDaysOut, 'limit': '20'});
      final allTrips = List<Map<String, dynamic>>.from(
        res.data is Map ? (res.data['items'] ?? []) : [],
      );

      // Client-side split: today vs tomorrow-to-3-days
      final todayItems = allTrips.where((t) => t['departure_date'] == today).toList();
      final futureItems = allTrips.where((t) => t['departure_date'] != today).toList();

      setState(() { _todayTrips = todayItems; _upcomingTrips = futureItems; _loading = false; });
    } catch (e) {
      debugPrint('HomeScreen._load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      appBar: AppBar(title: Text('$greeting, ${auth.driverName?.split(' ').first ?? 'Driver'}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text("Today's Trips", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_loading) const Center(child: CircularProgressIndicator())
          else if (_todayTrips.isEmpty) Container(
            padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
            child: const Column(children: [Icon(Icons.event_available, size: 48, color: AppTheme.textSecondary), SizedBox(height: 12), Text('No trips scheduled for today', style: TextStyle(color: AppTheme.textSecondary))]),
          )
          else ..._todayTrips.map((t) => _TripCard(trip: t, onTap: () => context.push('/trips/${t['id']}'))),

          // Upcoming section (next 3 days)
          if (!_loading) ...[
            const SizedBox(height: 24),
            const Text('Upcoming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_upcomingTrips.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No upcoming trips in the next 3 days', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)))
            else
              ..._upcomingTrips.map((t) => _TripCard(trip: t, onTap: () => context.push('/trips/${t['id']}'))),
            const SizedBox(height: 8),
            Center(child: TextButton(
              onPressed: () => context.go('/trips'),
              child: const Text('View All Trips', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            )),
          ],
        ]),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;
  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final route = trip['route'] as Map<String, dynamic>? ?? {};
    final status = trip['status'] as String? ?? 'scheduled';
    final statusColor = status == 'completed' ? AppTheme.success : status == 'departed' || status == 'en_route' ? AppTheme.warning : AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${route['origin'] ?? '—'} → ${route['destination'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text('${(trip['departure_time'] as String?)?.substring(0, 5) ?? '--:--'} • ${trip['passenger_count'] ?? 0} passengers', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
        ]),
      ),
    );
  }
}
