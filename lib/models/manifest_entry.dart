class ManifestEntry {
  final String bookingId;
  final String bookingRef;
  final String passengerName;
  final String? phone;
  final String? seatNumber;
  final bool isPrimary;
  final bool checkedIn;
  final String? checkedInAt;

  ManifestEntry({
    required this.bookingId, required this.bookingRef, required this.passengerName,
    this.phone, this.seatNumber, this.isPrimary = false, this.checkedIn = false,
    this.checkedInAt,
  });

  factory ManifestEntry.fromJson(Map<String, dynamic> json) => ManifestEntry(
    bookingId: json['booking_id'] ?? '',
    bookingRef: json['booking_ref'] ?? '',
    passengerName: json['passenger_name'] ?? '',
    phone: json['phone'],
    seatNumber: json['seat_number'],
    isPrimary: json['is_primary'] ?? false,
    checkedIn: json['checked_in'] ?? false,
    checkedInAt: json['checked_in_at'],
  );
}
