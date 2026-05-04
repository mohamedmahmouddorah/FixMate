/// RepairRequest model - represents a device repair/maintenance request
/// Status flow: pending → accepted → done
class RepairRequest {
  final int id;
  String device;
  String category;
  String description;
  String location;
  String status; // 'pending', 'accepted', 'completed'
  final String clientEmail;
  final DateTime createdAt;
  final String? techNotes;
  final String? imagePath;

  RepairRequest({
    required this.id,
    required this.device,
    required this.category,
    required this.description,
    required this.location,
    this.status = 'pending',
    required this.clientEmail,
    this.techNotes,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy of this request with updated fields
  RepairRequest copyWith({
    String? device,
    String? category,
    String? description,
    String? location,
    String? status,
    String? techNotes,
    String? imagePath,
  }) {
    return RepairRequest(
      id: id,
      device: device ?? this.device,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      techNotes: techNotes ?? this.techNotes,
      imagePath: imagePath ?? this.imagePath,
      clientEmail: clientEmail,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device': device,
      'category': category,
      'description': description,
      'location': location,
      'status': status,
      'clientEmail': clientEmail,
      'techNotes': techNotes,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RepairRequest.fromJson(Map<String, dynamic> json) {
    return RepairRequest(
      id: json['id'],
      device: json['device'] ?? '',
      category: json['category'] ?? 'General',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? 'pending',
      clientEmail: json['clientEmail'] ?? '',
      techNotes: json['techNotes'],
      imagePath: json['imagePath'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
