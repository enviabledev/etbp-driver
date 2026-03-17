class DriverTrip {
  final String id;
  final String departureDate;
  final String departureTime;
  final String status;
  final String? routeName;
  final String? origin;
  final String? destination;
  final String? vehiclePlate;
  final String? vehicleType;
  final int passengerCount;
  final int totalSeats;

  DriverTrip({
    required this.id, required this.departureDate, required this.departureTime,
    this.status = 'scheduled', this.routeName, this.origin, this.destination,
    this.vehiclePlate, this.vehicleType, this.passengerCount = 0, this.totalSeats = 0,
  });

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>? ?? {};
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    return DriverTrip(
      id: json['id'] ?? '', departureDate: json['departure_date'] ?? '',
      departureTime: json['departure_time'] ?? '', status: json['status'] ?? 'scheduled',
      routeName: route['name'], origin: route['origin'] as String?,
      destination: route['destination'] as String?,
      vehiclePlate: vehicle?['plate_number'],
      vehicleType: vehicle?['type'],
      passengerCount: json['passenger_count'] ?? 0,
      totalSeats: json['total_seats'] ?? 0,
    );
  }
}

class TripDetail {
  final String id;
  final String departureDate;
  final String departureTime;
  final String status;
  final String? actualDepartureAt;
  final String? actualArrivalAt;
  final String? notes;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final Map<String, dynamic>? route;
  final Map<String, dynamic>? vehicle;
  final int passengersBooked;
  final int passengersCheckedIn;
  final Map<String, dynamic>? inspectionData;

  TripDetail({
    required this.id, required this.departureDate, required this.departureTime,
    this.status = 'scheduled', this.actualDepartureAt, this.actualArrivalAt,
    this.notes, this.price = 0, this.totalSeats = 0, this.availableSeats = 0,
    this.route, this.vehicle, this.passengersBooked = 0, this.passengersCheckedIn = 0,
    this.inspectionData,
  });

  factory TripDetail.fromJson(Map<String, dynamic> json) => TripDetail(
    id: json['id'] ?? '', departureDate: json['departure_date'] ?? '',
    departureTime: json['departure_time'] ?? '', status: json['status'] ?? 'scheduled',
    actualDepartureAt: json['actual_departure_at'],
    actualArrivalAt: json['actual_arrival_at'],
    notes: json['notes'], price: (json['price'] ?? 0).toDouble(),
    totalSeats: json['total_seats'] ?? 0, availableSeats: json['available_seats'] ?? 0,
    route: json['route'], vehicle: json['vehicle'],
    passengersBooked: json['passengers_booked'] ?? 0,
    passengersCheckedIn: json['passengers_checked_in'] ?? 0,
    inspectionData: json['inspection_data'],
  );
}
