// lib/models/scale_response_model.dart

import 'scale_template_model.dart';

// ═══════════════════════════════════════════════════════
// SCALE RESPONSE MODEL
// Resposta de um paciente a uma escala atribuída
// ═══════════════════════════════════════════════════════

class ScaleResponseModel {
  final String id;
  final String assignmentId;
  final String patientId;

  final Map<String, int> answers; // {"q1": 2, "q2": 1, ...}
  final int totalScore;
  final String? severityLevel;
  final Map<String, double> subscaleScores;

  final List<CriticalFlag> criticalFlags;
  final bool hasCriticalItem;

  final DateTime completedAt;
  final int? durationSeconds;
  final DateTime createdAt;

  const ScaleResponseModel({
    this.id = '',
    required this.assignmentId,
    required this.patientId,
    required this.answers,
    required this.totalScore,
    this.severityLevel,
    this.subscaleScores = const {},
    this.criticalFlags = const [],
    this.hasCriticalItem = false,
    required this.completedAt,
    this.durationSeconds,
    required this.createdAt,
  });

  // ══════════════════════════════════════
  // FROM JSON (Supabase → Dart)
  // ══════════════════════════════════════
  factory ScaleResponseModel.fromJson(Map<String, dynamic> json) {
    // Parse answers: JSONB {"q1": 2, "q2": 1, ...}
    final answersRaw = json['answers'] as Map<String, dynamic>? ?? {};
    final answers = <String, int>{};
    for (final entry in answersRaw.entries) {
      answers[entry.key] = (entry.value as num).toInt();
    }

    // Parse subscale_scores: JSONB {"anhedonia": 8.0, "mood": 4.0}
    final subscaleRaw = json['subscale_scores'] as Map<String, dynamic>? ?? {};
    final subscaleScores = <String, double>{};
    for (final entry in subscaleRaw.entries) {
      subscaleScores[entry.key] = (entry.value as num).toDouble();
    }

    // Parse critical_flags: JSONB array
    final criticalRaw = json['critical_flags'] as List<dynamic>? ?? [];
    final criticalFlags = criticalRaw
        .map((f) => CriticalFlag.fromJson(f as Map<String, dynamic>))
        .toList();

    return ScaleResponseModel(
      id: json['id'] as String? ?? '',
      assignmentId: json['assignment_id'] as String,
      patientId: json['patient_id'] as String,
      answers: answers,
      totalScore: json['total_score'] as int,
      severityLevel: json['severity_level'] as String?,
      subscaleScores: subscaleScores,
      criticalFlags: criticalFlags,
      hasCriticalItem: json['has_critical_item'] as bool? ?? false,
      completedAt: DateTime.parse(json['completed_at'] as String),
      durationSeconds: json['duration_seconds'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // ══════════════════════════════════════
  // TO JSON (Dart → Supabase)
  // ══════════════════════════════════════
  Map<String, dynamic> toJson() {
    // Convert answers to JSONB
    final answersJson = <String, dynamic>{};
    for (final entry in answers.entries) {
      answersJson[entry.key] = entry.value;
    }

    // Convert subscale_scores to JSONB
    final subscaleJson = <String, dynamic>{};
    for (final entry in subscaleScores.entries) {
      subscaleJson[entry.key] = entry.value;
    }

    // Convert critical_flags to JSONB
    final criticalJson = criticalFlags.map((f) => f.toJson()).toList();

    return {
      'assignment_id': assignmentId,
      'patient_id': patientId,
      'answers': answersJson,
      'total_score': totalScore,
      'severity_level': severityLevel,
      'subscale_scores': subscaleJson,
      'critical_flags': criticalJson,
      'has_critical_item': hasCriticalItem,
      'completed_at': completedAt.toIso8601String(),
      'duration_seconds': durationSeconds,
    };
  }

  // ══════════════════════════════════════
  // FACTORY: Criar resposta calculando tudo automaticamente
  // ══════════════════════════════════════

  factory ScaleResponseModel.calculate({
    required String assignmentId,
    required String patientId,
    required Map<String, int> answers,
    required int totalScore,
    required String severityLevel,
    Map<String, double> subscaleScores = const {},
    List<CriticalFlag> criticalFlags = const [],
    int? durationSeconds,
  }) {
    return ScaleResponseModel(
      assignmentId: assignmentId,
      patientId: patientId,
      answers: answers,
      totalScore: totalScore,
      severityLevel: severityLevel,
      subscaleScores: subscaleScores,
      criticalFlags: criticalFlags,
      hasCriticalItem: criticalFlags.isNotEmpty,
      completedAt: DateTime.now(),
      durationSeconds: durationSeconds,
      createdAt: DateTime.now(),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════

  /// Retorna true se a resposta tem algum item crítico
  bool get isCritical => criticalFlags.isNotEmpty || hasCriticalItem;

  /// Retorna a label da severidade
  String get severityLabel {
    if (severityLevel == null) return 'N/A';
    return SeverityLevel.fromString(severityLevel!).label;
  }

  /// Retorna o tempo gasto formatado
  String get durationFormatted {
    if (durationSeconds == null) return 'N/A';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Retorna true se foi respondida hoje
  bool get isToday {
    final now = DateTime.now();
    return completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day;
  }

  /// Retorna as respostas não nulas (perguntas respondidas)
  int get answeredCount => answers.length;

  ScaleResponseModel copyWith({
    String? id,
    String? assignmentId,
    String? patientId,
    Map<String, int>? answers,
    int? totalScore,
    String? severityLevel,
    Map<String, double>? subscaleScores,
    List<CriticalFlag>? criticalFlags,
    bool? hasCriticalItem,
    DateTime? completedAt,
    int? durationSeconds,
    DateTime? createdAt,
  }) {
    return ScaleResponseModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      patientId: patientId ?? this.patientId,
      answers: answers ?? this.answers,
      totalScore: totalScore ?? this.totalScore,
      severityLevel: severityLevel ?? this.severityLevel,
      subscaleScores: subscaleScores ?? this.subscaleScores,
      criticalFlags: criticalFlags ?? this.criticalFlags,
      hasCriticalItem: hasCriticalItem ?? this.hasCriticalItem,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ═══════════════════════════════════════════════════════
// SCALE EVOLUTION DATA POINT
// Usado para gráficos de evolução
// ═══════════════════════════════════════════════════════

class ScaleEvolutionPoint {
  final DateTime date;
  final int score;
  final String severityLevel;
  final String severityLabel;
  final String responseId;

  const ScaleEvolutionPoint({
    required this.date,
    required this.score,
    required this.severityLevel,
    required this.severityLabel,
    required this.responseId,
  });

  factory ScaleEvolutionPoint.fromResponse(ScaleResponseModel response) {
    return ScaleEvolutionPoint(
      date: response.completedAt,
      score: response.totalScore,
      severityLevel: response.severityLevel ?? 'minimal',
      severityLabel: response.severityLabel,
      responseId: response.id,
    );
  }
}

// ═══════════════════════════════════════════════════════
// SUBSCALE EVOLUTION
// Evolução de uma subescala específica
// ═══════════════════════════════════════════════════════

class SubscaleEvolution {
  final String subscaleId;
  final String subscaleName;
  final List<ScaleEvolutionPoint> points;

  const SubscaleEvolution({
    required this.subscaleId,
    required this.subscaleName,
    required this.points,
  });

  /// Retorna a tendência (positiva = melhorando, negativa = piorando)
  double get trend {
    if (points.length < 2) return 0;
    final first = points.first.score.toDouble();
    final last = points.last.score.toDouble();
    return last - first; // Negativo = melhorando (score menor é melhor)
  }
}
