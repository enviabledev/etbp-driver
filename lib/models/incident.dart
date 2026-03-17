class TripIncident {
  final String id;
  final String type;
  final String? description;
  final String severity;
  final String reportedAt;
  final String? resolvedAt;

  TripIncident({
    required this.id, required this.type, this.description,
    this.severity = 'low', required this.reportedAt, this.resolvedAt,
  });

  factory TripIncident.fromJson(Map<String, dynamic> json) => TripIncident(
    id: json['id'] ?? '', type: json['type'] ?? '',
    description: json['description'], severity: json['severity'] ?? 'low',
    reportedAt: json['reported_at'] ?? '', resolvedAt: json['resolved_at'],
  );
}
