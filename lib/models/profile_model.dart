// lib/models/profile_model.dart

class ProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final String? avatarUrl;
  final bool onboardingCompleted;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.avatarUrl,
    this.onboardingCompleted = false,
    required this.createdAt,
  });

  // ══════════════════════════════════════
  // FROM JSON (Supabase → Dart)
  // ══════════════════════════════════════
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ══════════════════════════════════════
  // TO JSON (Dart → Supabase)
  // ══════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'avatar_url': avatarUrl,
      'onboarding_completed': onboardingCompleted,
    };
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  bool get isPsychologist => role == 'psychologist';
  bool get isPatient => role == 'patient';

  ProfileModel copyWith({
    String? fullName,
    String? avatarUrl,
    bool? onboardingCompleted,
  }) {
    return ProfileModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
    );
  }
}