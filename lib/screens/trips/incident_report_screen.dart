import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';

const _incidentTypes = ['Breakdown', 'Accident', 'Passenger Issue', 'Road Blockage', 'Delay', 'Other'];

class IncidentReportScreen extends ConsumerStatefulWidget {
  final String tripId;
  const IncidentReportScreen({super.key, required this.tripId});
  @override
  ConsumerState<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends ConsumerState<IncidentReportScreen> {
  String _type = 'Delay';
  String _severity = 'low';
  final _descC = TextEditingController();
  bool _submitting = false;
  String? _successId;

  Future<void> _submit() async {
    if (_descC.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Description must be at least 10 characters')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post('${Endpoints.driverTripDetail(widget.tripId)}/incidents', data: {
        'type': _type.toLowerCase().replaceAll(' ', '_'),
        'description': _descC.text.trim(),
        'severity': _severity,
      });
      setState(() => _successId = res.data['id']);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() { _descC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_successId != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident Reported')),
        body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 64, color: AppTheme.success),
          const SizedBox(height: 16),
          const Text('Incident Reported', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Operations has been notified.', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Trip')),
        ]))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Type
        const Text('Incident Type', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _incidentTypes.map((t) {
          final selected = _type == t;
          return ChoiceChip(label: Text(t), selected: selected, onSelected: (_) => setState(() => _type = t),
            selectedColor: AppTheme.primary.withValues(alpha: 0.15),
            labelStyle: TextStyle(color: selected ? AppTheme.primary : AppTheme.textPrimary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal));
        }).toList()),
        const SizedBox(height: 20),

        // Severity
        const Text('Severity', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'low', label: Text('Low')),
            ButtonSegment(value: 'medium', label: Text('Medium')),
            ButtonSegment(value: 'high', label: Text('High')),
          ],
          selected: {_severity},
          onSelectionChanged: (s) => setState(() => _severity = s.first),
        ),
        const SizedBox(height: 20),

        // Description
        const Text('Description', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(controller: _descC, maxLines: 5, decoration: const InputDecoration(hintText: 'Describe the incident in detail...', border: OutlineInputBorder())),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Report'),
        ),
      ]),
    );
  }
}
