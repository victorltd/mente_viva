// lib/models/patient_model.dart

class PatientModel {
  final String id;
  final String? userId;
  final String psychologistId;
  final String fullName;
  final String? email;
  final String? phone;
  final String status;
  final String? inviteCode;
  final String? notes;
  final DateTime? startedAt;
  final DateTime createdAt;

  PatientModel({
    required this.id,
    this.userId,
    required this.psychologistId,
    required this.fullName,
    this.email,
    this.phone,
    this.status = 'pending',
    this.inviteCode,
    this.notes,
    this.startedAt,
    required this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      psychologistId: json['psychologist_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'pending',
      inviteCode: json['invite_code'] as String?,
      notes: json['notes'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'psychologist_id': psychologistId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'status': status,
      'notes': notes,
    };
  }

  bool get isLinked => userId != null;
  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
}