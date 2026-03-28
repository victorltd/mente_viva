// lib/models/checkin_model.dart

class CheckinModel {
  final String id;
  final String patientId;
  final int moodScore;
  final String primaryEmotion;
  final int? energyLevel;
  final int? sleepQuality;
  final String? notes;
  final DateTime createdAt;

  CheckinModel({
    required this.id,
    required this.patientId,
    required this.moodScore,
    required this.primaryEmotion,
    this.energyLevel,
    this.sleepQuality,
    this.notes,
    required this.createdAt,
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    return CheckinModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      moodScore: json['mood_score'] as int,
      primaryEmotion: json['primary_emotion'] as String,
      energyLevel: json['energy_level'] as int?,
      sleepQuality: json['sleep_quality'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'mood_score': moodScore,
      'primary_emotion': primaryEmotion,
      'energy_level': energyLevel,
      'sleep_quality': sleepQuality,
      'notes': notes,
    };
  }
}