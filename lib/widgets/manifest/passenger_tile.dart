import 'package:flutter/material.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/models/manifest_entry.dart';

class PassengerTile extends StatelessWidget {
  final ManifestEntry entry;
  final VoidCallback? onCheckin;

  const PassengerTile({super.key, required this.entry, this.onCheckin});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: entry.checkedIn
            ? AppTheme.success.withValues(alpha: 0.1)
            : AppTheme.border,
        radius: 18,
        child: Text(
          entry.seatNumber ?? '?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: entry.checkedIn ? AppTheme.success : AppTheme.textPrimary,
          ),
        ),
      ),
      title: Text(entry.passengerName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(entry.phone ?? '', style: const TextStyle(fontSize: 12)),
      trailing: entry.checkedIn
          ? const Icon(Icons.check_circle, color: AppTheme.success, size: 22)
          : IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: onCheckin,
            ),
    );
  }
}
