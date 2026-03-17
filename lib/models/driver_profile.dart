class DriverProfile {
  final String id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String licenseNumber;
  final String? licenseExpiry;
  final String? licenseClass;
  final int? yearsExperience;
  final String? medicalCheckExpiry;
  final double ratingAvg;
  final int totalTrips;
  final bool isAvailable;
  final DriverTerminal? assignedTerminal;

  DriverProfile({
    required this.id, required this.userId, this.firstName, this.lastName,
    this.email, this.phone, required this.licenseNumber, this.licenseExpiry,
    this.licenseClass, this.yearsExperience, this.medicalCheckExpiry,
    this.ratingAvg = 0, this.totalTrips = 0, this.isAvailable = true,
    this.assignedTerminal,
  });

  String get fullName => [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
  String get initials => '${(firstName ?? '').isNotEmpty ? firstName![0] : ''}${(lastName ?? '').isNotEmpty ? lastName![0] : ''}'.toUpperCase();

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
    id: json['id'] ?? '', userId: json['user_id'] ?? '',
    firstName: json['first_name'], lastName: json['last_name'],
    email: json['email'], phone: json['phone'],
    licenseNumber: json['license_number'] ?? '',
    licenseExpiry: json['license_expiry'],
    licenseClass: json['license_class'],
    yearsExperience: json['years_experience'],
    medicalCheckExpiry: json['medical_check_expiry'],
    ratingAvg: (json['rating_avg'] ?? 0).toDouble(),
    totalTrips: json['total_trips'] ?? 0,
    isAvailable: json['is_available'] ?? true,
    assignedTerminal: json['assigned_terminal'] != null ? DriverTerminal.fromJson(json['assigned_terminal']) : null,
  );
}

class DriverTerminal {
  final String id;
  final String name;
  final String city;

  DriverTerminal({required this.id, required this.name, required this.city});

  factory DriverTerminal.fromJson(Map<String, dynamic> json) => DriverTerminal(
    id: json['id'] ?? '', name: json['name'] ?? '', city: json['city'] ?? '',
  );
}
