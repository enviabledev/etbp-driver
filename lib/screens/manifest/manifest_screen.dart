import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

class ManifestScreen extends ConsumerStatefulWidget {
  final String tripId;
  const ManifestScreen({super.key, required this.tripId});
  @override
  ConsumerState<ManifestScreen> createState() => _ManifestScreenState();
}

class _ManifestScreenState extends ConsumerState<ManifestScreen> {
  List<Map<String, dynamic>> _passengers = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(Endpoints.driverTripManifest(widget.tripId));
      setState(() { _passengers = List<Map<String, dynamic>>.from(res.data['passengers'] ?? []); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _checkin(String bookingId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post(Endpoints.driverCheckin(widget.tripId, bookingId));
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked in!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkedIn = _passengers.where((p) => p['checked_in'] == true).length;
    final filtered = _search.isEmpty ? _passengers : _passengers.where((p) => (p['passenger_name'] as String? ?? '').toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Manifest ($checkedIn/${_passengers.length})')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(hintText: 'Search passengers...', prefixIcon: const Icon(Icons.search, size: 20), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        )),
        if (_loading) const Expanded(child: Center(child: CircularProgressIndicator()))
        else Expanded(child: RefreshIndicator(onRefresh: _load, child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: filtered.length, separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = filtered[i];
            final isCheckedIn = p['checked_in'] == true;
            return ListTile(
              leading: CircleAvatar(backgroundColor: isCheckedIn ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.border, radius: 18,
                child: Text(p['seat_number'] ?? '?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isCheckedIn ? AppTheme.success : AppTheme.textPrimary))),
              title: Text(p['passenger_name'] ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text(p['phone'] ?? '', style: const TextStyle(fontSize: 12)),
              trailing: isCheckedIn
                ? const Icon(Icons.check_circle, color: AppTheme.success, size: 22)
                : IconButton(icon: const Icon(Icons.check_circle_outline), onPressed: () => _checkin(p['booking_id'])),
            );
          },
        ))),
      ]),
    );
  }
}
