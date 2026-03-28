// lib/models/task_response_model.dart

class TaskResponseModel {
  final String id;
  final String taskId;
  final String patientId;
  final Map<String, dynamic> responseData;
  final int? durationSeconds;
  final DateTime completedAt;
  final DateTime createdAt;

  TaskResponseModel({
    required this.id,
    required this.taskId,
    required this.patientId,
    required this.responseData,
    this.durationSeconds,
    required this.completedAt,
    required this.createdAt,
  });

  // ══════════════════════════════════════
  // HELPERS: Respiração
  // ══════════════════════════════════════
  int? get breathingCycles => responseData['cycles'] as int?;
  String? get breathingPattern => responseData['pattern'] as String?;
  int? get breathingFeeling => responseData['feeling_after'] as int?;

  // ══════════════════════════════════════
  // HELPERS: Registro de Pensamento (TCC)
  // ══════════════════════════════════════
  String? get situation => responseData['situation'] as String?;
  String? get automaticThought => responseData['automatic_thought'] as String?;
  String? get emotion => responseData['emotion'] as String?;
  int? get emotionIntensity => responseData['emotion_intensity'] as int?;
  String? get evidenceFor => responseData['evidence_for'] as String?;
  String? get evidenceAgainst => responseData['evidence_against'] as String?;
  String? get alternativeThought =>
      responseData['alternative_thought'] as String?;
  int? get newEmotionIntensity =>
      responseData['new_emotion_intensity'] as int?;

  // ══════════════════════════════════════
  // HELPERS: Journaling
  // ══════════════════════════════════════
  String? get journalEntry => responseData['entry'] as String?;
  String? get journalPrompt => responseData['prompt'] as String?;
  String? get journalMood => responseData['mood'] as String?;

  // ══════════════════════════════════════
  // FROM JSON (Supabase → Dart)
  // ══════════════════════════════════════
  factory TaskResponseModel.fromJson(Map<String, dynamic> json) {
    return TaskResponseModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      patientId: json['patient_id'] as String,
      responseData: (json['response_data'] as Map<String, dynamic>?) ?? {},
      durationSeconds: json['duration_seconds'] as int?,
      completedAt: DateTime.parse(json['completed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ══════════════════════════════════════
  // TO JSON (Dart → Supabase)
  // ══════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'patient_id': patientId,
      'response_data': responseData,
      'duration_seconds': durationSeconds,
      'completed_at': completedAt.toIso8601String(),
    };
  }
}