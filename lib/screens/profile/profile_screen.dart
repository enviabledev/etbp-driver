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
    final rating = (p['rating_avg'] ?? 0).toDouble();
    final totalTrips = p['total_trips'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Avatar + name
        Center(child: CircleAvatar(
          radius: 40, backgroundColor: AppTheme.primary,
          child: Text(
            '${_initial(p['first_name'])}${_initial(p['last_name'])}',
            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )),
        const SizedBox(height: 8),
        Center(child: Text('${p['first_name'] ?? ''} ${p['last_name'] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Center(child: Text(p['email'] ?? '', style: const TextStyle(color: AppTheme.textSecondary))),
        if (p['phone'] != null) Center(child: Text(p['phone'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        const SizedBox(height: 20),

        // Performance section
        _sectionTitle('Performance'),
        Row(children: [
          _statCard('Rating', '${rating.toStringAsFixed(1)} ★', rating >= 4 ? AppTheme.success : rating >= 3 ? AppTheme.warning : AppTheme.error),
          const SizedBox(width: 12),
          _statCard('Trips', '$totalTrips', AppTheme.primary),
          const SizedBox(width: 12),
          _statCard('Status', p['is_available'] == true ? 'Active' : 'Offline', p['is_available'] == true ? AppTheme.success : AppTheme.textSecondary),
        ]),
        const SizedBox(height: 20),

        // Compliance section
        _sectionTitle('Compliance'),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          _complianceRow('License', p['license_number'] ?? '—', p['license_expiry']),
          const Divider(height: 16),
          _complianceRow('License Class', p['license_class'] ?? '—', null),
          const Divider(height: 16),
          _complianceRow('Medical Check', p['medical_check_expiry'] != null ? 'Valid' : 'Not recorded', p['medical_check_expiry']),
          const Divider(height: 16),
          _row('Experience', '${p['years_experience'] ?? 0} years'),
        ]))),
        const SizedBox(height: 20),

        // Terminal assignment
        if (terminal != null) ...[
          _sectionTitle('Assignment'),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            _row('Terminal', terminal['name'] ?? '—'),
            _row('City', terminal['city'] ?? '—'),
          ]))),
          const SizedBox(height: 20),
        ],

        // Logout
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authStateProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout, color: AppTheme.error),
          label: const Text('Logout', style: TextStyle(color: AppTheme.error)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error), minimumSize: const Size(double.infinity, 48)),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  String _initial(dynamic name) {
    final s = name as String? ?? '';
    return s.isNotEmpty ? s[0] : '';
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
  );

  Widget _statCard(String label, String value, Color color) => Expanded(
    child: Card(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    )),
  );

  Widget _complianceRow(String label, String value, String? expiryDate) {
    Color? statusColor;
    String? statusText;
    if (expiryDate != null) {
      try {
        final expiry = DateTime.parse(expiryDate);
        final daysUntil = expiry.difference(DateTime.now()).inDays;
        if (daysUntil < 0) { statusColor = AppTheme.error; statusText = 'EXPIRED'; }
        else if (daysUntil < 30) { statusColor = AppTheme.warning; statusText = 'Expiring soon'; }
        else { statusColor = AppTheme.success; statusText = 'Valid'; }
      } catch (_) {}
    }
    return Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      if (statusText != null) Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: statusColor?.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
      ),
    ]);
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
    ]),
  );
}
