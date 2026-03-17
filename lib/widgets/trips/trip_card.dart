import 'package:flutter/material.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/models/trip.dart';

class TripCard extends StatelessWidget {
  final DriverTrip trip;
  final VoidCallback onTap;

  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (trip.status) {
      'completed' => AppTheme.success,
      'departed' || 'en_route' => AppTheme.warning,
      'cancelled' => AppTheme.error,
      _ => AppTheme.primary,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${trip.origin ?? '—'} → ${trip.destination ?? '—'}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text('${trip.departureTime.substring(0, 5)} • ${trip.passengerCount}/${trip.totalSeats} pax',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(trip.status.replaceAll('_', ' '),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ]),
      ),
    );
  }
}
