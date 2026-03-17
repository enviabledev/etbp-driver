import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(Endpoints.driverProfile);
      setState(() { _profile = res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _profile ?? {};
    final terminal = p['assigned_terminal'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Avatar
        Center(child: CircleAvatar(radius: 40, backgroundColor: AppTheme.primary, child: Text('${(p['first_name'] as String? ?? '').isNotEmpty ? (p['first_name'] as String)[0] : ''}${(p['last_name'] as String? ?? '').isNotEmpty ? (p['last_name'] as String)[0] : ''}', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)))),
        const SizedBox(height: 8),
        Center(child: Text('${p['first_name'] ?? ''} ${p['last_name'] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Center(child: Text(p['email'] ?? '', style: const TextStyle(color: AppTheme.textSecondary))),
        const SizedBox(height: 24),

        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Driver Details', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _row('License', p['license_number'] ?? '—'),
          _row('License Class', p['license_class'] ?? '—'),
          _row('License Expiry', p['license_expiry'] ?? '—'),
          _row('Medical Expiry', p['medical_check_expiry'] ?? '—'),
          _row('Experience', '${p['years_experience'] ?? 0} years'),
          _row('Rating', '${(p['rating_avg'] ?? 0.0).toStringAsFixed(1)} / 5'),
          _row('Total Trips', '${p['total_trips'] ?? 0}'),
          if (terminal != null) _row('Terminal', '${terminal['name']} (${terminal['city']})'),
        ]))),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: () async { await ref.read(authStateProvider.notifier).logout(); if (context.mounted) context.go('/login'); },
          icon: const Icon(Icons.logout, color: AppTheme.error), label: const Text('Logout', style: TextStyle(color: AppTheme.error)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error), minimumSize: const Size(double.infinity, 48)),
        ),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
    SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
  ]));
}
