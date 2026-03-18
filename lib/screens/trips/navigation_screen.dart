import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  final String tripId;
  const NavigationScreen({super.key, required this.tripId});
  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  List<Map<String, dynamic>> _stops = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(Endpoints.driverNavigation(widget.tripId));
      setState(() { _stops = List<Map<String, dynamic>>.from(res.data['stops'] ?? []); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _navigateTo(double lat, double lng) {
    launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('Route Navigation')), body: const Center(child: CircularProgressIndicator()));
    }

    final validStops = _stops.where((s) => s['latitude'] != null && s['longitude'] != null).toList();
    if (validStops.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Route Navigation')), body: const Center(child: Text('No route data available')));
    }

    final points = validStops.map((s) => LatLng((s['latitude'] as num).toDouble(), (s['longitude'] as num).toDouble())).toList();
    final bounds = LatLngBounds.fromPoints(points);
    final nextStop = validStops.firstWhere((s) => s['status'] == 'upcoming', orElse: () => validStops.last);

    return Scaffold(
      appBar: AppBar(title: const Text('Route Navigation')),
      body: Column(children: [
        // Map
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: FlutterMap(
            options: MapOptions(initialCameraFit: CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40))),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'ng.enviabletransport.etbp_driver'),
              PolylineLayer(polylines: [Polyline(points: points, strokeWidth: 3, color: AppTheme.primary)]),
              MarkerLayer(markers: validStops.map((s) {
                final lat = (s['latitude'] as num).toDouble();
                final lng = (s['longitude'] as num).toDouble();
                final type = s['type'] ?? '';
                final status = s['status'] ?? 'upcoming';
                Color color = Colors.grey;
                if (type == 'origin') color = Colors.blue;
                else if (type == 'destination') color = Colors.red;
                else if (status == 'completed') color = AppTheme.success;
                else if (status == 'current') color = Colors.orange;
                return Marker(point: LatLng(lat, lng), width: 30, height: 30, child: Icon(Icons.location_on, color: color, size: 30));
              }).toList()),
            ],
          ),
        ),

        // Stop list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _stops.length,
            itemBuilder: (_, i) {
              final s = _stops[i];
              final status = s['status'] ?? 'upcoming';
              final isCurrent = status == 'current';
              Color dotColor = status == 'completed' ? AppTheme.success : isCurrent ? Colors.orange : Colors.grey[300]!;

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: isCurrent ? Border(left: BorderSide(color: AppTheme.primary, width: 3)) : null,
                  color: isCurrent ? AppTheme.primary.withValues(alpha: 0.05) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                    child: status == 'completed' ? const Icon(Icons.check, color: Colors.white, size: 14) : Center(child: Text('${s['order'] ?? i}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['name'] ?? 'Stop', style: TextStyle(fontSize: 14, fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500)),
                    if (s['estimated_minutes'] != null) Text('${s['estimated_minutes']} min from origin', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    if (s['notes'] != null) Text(s['notes'], style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                  ])),
                  if (s['latitude'] != null && s['longitude'] != null)
                    IconButton(icon: const Icon(Icons.navigation, size: 20, color: AppTheme.primary),
                      onPressed: () => _navigateTo((s['latitude'] as num).toDouble(), (s['longitude'] as num).toDouble())),
                ]),
              );
            },
          ),
        ),
      ]),

      // Bottom button
      bottomNavigationBar: nextStop['latitude'] != null ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: () => _navigateTo((nextStop['latitude'] as num).toDouble(), (nextStop['longitude'] as num).toDouble()),
            icon: const Icon(Icons.navigation),
            label: Text('Navigate to ${nextStop['name'] ?? 'Next Stop'}'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          ),
        ),
      ) : null,
    );
  }
}
