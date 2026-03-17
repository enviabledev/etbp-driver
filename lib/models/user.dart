class User {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String role;

  User({required this.id, this.email, this.firstName, this.lastName, this.role = 'driver'});

  String get fullName => [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] ?? '', email: json['email'],
    firstName: json['first_name'], lastName: json['last_name'],
    role: json['role'] ?? 'driver',
  );
}
