// lib/models/psychologist_model.dart

class PsychologistFeatures {
  final bool tasks;
  final bool chat;

  const PsychologistFeatures({
    this.tasks = false,
    this.chat = false,
  });

  factory PsychologistFeatures.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PsychologistFeatures();
    return PsychologistFeatures(
      tasks: json['tasks'] as bool? ?? false,
      chat: json['chat'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tasks': tasks,
      'chat': chat,
    };
  }

  PsychologistFeatures copyWith({
    bool? tasks,
    bool? chat,
  }) {
    return PsychologistFeatures(
      tasks: tasks ?? this.tasks,
      chat: chat ?? this.chat,
    );
  }
}

class PsychologistModel {
  final String id;
  final String crp;
  final List<String> approach;
  final String? bio;
  final String? phone;
  final int sessionDuration;
  final Map<String, dynamic> messageSettings;
  final PsychologistFeatures features;

  PsychologistModel({
    required this.id,
    required this.crp,
    this.approach = const [],
    this.bio,
    this.phone,
    this.sessionDuration = 50,
    this.messageSettings = const {},
    this.features = const PsychologistFeatures(),
  });

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  bool get hasTasksEnabled => features.tasks;
  bool get hasChatEnabled => features.chat;

  // ══════════════════════════════════════
  // FROM JSON (Supabase → Dart)
  // ══════════════════════════════════════
  factory PsychologistModel.fromJson(Map<String, dynamic> json) {
    return PsychologistModel(
      id: json['id'] as String,
      crp: json['crp'] as String,
      approach: List<String>.from(json['approach'] ?? []),
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      sessionDuration: json['session_duration'] as int? ?? 50,
      messageSettings:
          json['message_settings'] as Map<String, dynamic>? ?? {},
      features: PsychologistFeatures.fromJson(
        json['features'] as Map<String, dynamic>?,
      ),
    );
  }

  // ══════════════════════════════════════
  // TO JSON (Dart → Supabase)
  // ══════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crp': crp,
      'approach': approach,
      'bio': bio,
      'phone': phone,
      'session_duration': sessionDuration,
      'message_settings': messageSettings,
      'features': features.toJson(),
    };
  }

  PsychologistModel copyWith({
    String? crp,
    List<String>? approach,
    String? bio,
    String? phone,
    int? sessionDuration,
    PsychologistFeatures? features,
  }) {
    return PsychologistModel(
      id: id,
      crp: crp ?? this.crp,
      approach: approach ?? this.approach,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      messageSettings: messageSettings,
      features: features ?? this.features,
    );
  }
}