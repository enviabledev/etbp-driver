import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

const _inspectionItems = [
  'Tyres', 'Brakes', 'Lights', 'Engine Oil', 'Coolant', 'AC / Heating',
  'Mirrors', 'Horn', 'Fire Extinguisher', 'First Aid Kit', 'Seat Belts',
  'Windshield / Wipers', 'Doors', 'Emergency Exits',
];

class InspectionScreen extends ConsumerStatefulWidget {
  final String tripId;
  final Map<String, dynamic>? existingData;
  const InspectionScreen({super.key, required this.tripId, this.existingData});
  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  final Map<String, String> _statuses = {}; // item -> pass/fail
  final Map<String, String> _notes = {};
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _submitted = true;
      for (final item in (widget.existingData!['items'] as List? ?? [])) {
        _statuses[item['name']] = item['status'];
        if (item['notes'] != null) _notes[item['name']] = item['notes'];
      }
    }
  }

  bool get _allChecked => _inspectionItems.every((i) => _statuses.containsKey(i.toLowerCase()));
  int get _failCount => _statuses.values.where((s) => s == 'fail').length;

  Future<void> _submit() async {
    if (_failCount > 0) {
      final proceed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
        title: const Text('Items Failed'),
        content: Text('$_failCount item(s) failed inspection. Submit anyway?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit Anyway', style: TextStyle(color: AppTheme.warning))),
        ],
      ));
      if (proceed != true) return;
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(Endpoints.driverTripDetail(widget.tripId).replaceFirst(RegExp(r'$'), '/inspection'), data: {
        'items': _inspectionItems.map((name) => {
          'name': name.toLowerCase(),
          'status': _statuses[name.toLowerCase()] ?? 'fail',
          'notes': _notes[name.toLowerCase()],
        }).toList(),
      });
      setState(() => _submitted = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inspection submitted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Trip Inspection')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ..._inspectionItems.map((name) {
          final key = name.toLowerCase();
          final status = _statuses[key];
          final isFail = status == 'fail';
          return Card(
            color: isFail ? AppTheme.error.withValues(alpha: 0.05) : null,
            child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                if (!_submitted) ...[
                  _toggleBtn(key, 'pass', Icons.check_circle, AppTheme.success),
                  const SizedBox(width: 8),
                  _toggleBtn(key, 'fail', Icons.cancel, AppTheme.error),
                ] else ...[
                  Icon(status == 'pass' ? Icons.check_circle : Icons.cancel,
                    color: status == 'pass' ? AppTheme.success : AppTheme.error, size: 24),
                ],
              ]),
              if (!_submitted && isFail) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Notes (optional)', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  onChanged: (v) => _notes[key] = v,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (_submitted && _notes[key] != null && _notes[key]!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(_notes[key]!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
            ])),
          );
        }),
        const SizedBox(height: 16),
        if (!_submitted) ElevatedButton(
          onPressed: _allChecked && !_submitting ? _submit : null,
          child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Inspection'),
        ),
      ]),
    );
  }

  Widget _toggleBtn(String key, String value, IconData icon, Color color) {
    final selected = _statuses[key] == value;
    return GestureDetector(
      onTap: () => setState(() => _statuses[key] = value),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : AppTheme.border),
        ),
        child: Icon(icon, color: selected ? color : AppTheme.textSecondary, size: 22),
      ),
    );
  }
}
