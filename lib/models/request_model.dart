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
  final String? techEmail;
  final String? techNotes;
  final List<String> imagePaths;
  final DateTime? acceptedAt;
  final int? estimatedDays;

  RepairRequest({
    required this.id,
    required this.device,
    required this.category,
    required this.description,
    required this.location,
    this.status = 'pending',
    required this.clientEmail,
    this.techEmail,
    this.techNotes,
    this.imagePaths = const [],
    DateTime? createdAt,
    this.acceptedAt,
    this.estimatedDays,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy of this request with updated fields
  RepairRequest copyWith({
    String? device,
    String? category,
    String? description,
    String? location,
    String? status,
    String? techEmail,
    String? techNotes,
    List<String>? imagePaths,
    DateTime? acceptedAt,
    int? estimatedDays,
  }) {
    return RepairRequest(
      id: id,
      device: device ?? this.device,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      techEmail: techEmail ?? this.techEmail,
      techNotes: techNotes ?? this.techNotes,
      imagePaths: imagePaths ?? this.imagePaths,
      clientEmail: clientEmail,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      estimatedDays: estimatedDays ?? this.estimatedDays,
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
      'techEmail': techEmail,
      'techNotes': techNotes,
      'imagePaths': imagePaths,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'estimatedDays': estimatedDays,
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
      techEmail: json['techEmail'],
      techNotes: json['techNotes'],
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      estimatedDays: json['estimatedDays'],
    );
  }

  /// Check if the repair duration has exceeded the estimated days
  bool get isExpired {
    if (acceptedAt == null || estimatedDays == null || status == 'completed') {
      return false;
    }
    final deadline = acceptedAt!.add(Duration(days: estimatedDays!));
    return DateTime.now().isAfter(deadline);
  }
}
