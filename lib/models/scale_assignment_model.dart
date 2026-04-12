// lib/models/scale_assignment_model.dart

// ═══════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════

enum ScaleFrequency {
  once,
  weekly,
  biweekly,
  monthly,
  custom;

  String get label {
    switch (this) {
      case ScaleFrequency.once:
        return 'Única vez';
      case ScaleFrequency.weekly:
        return 'Semanal';
      case ScaleFrequency.biweekly:
        return 'Quinzenal';
      case ScaleFrequency.monthly:
        return 'Mensal';
      case ScaleFrequency.custom:
        return 'Personalizada';
    }
  }

  String get description {
    switch (this) {
      case ScaleFrequency.once:
        return 'Aplicação única, sem recorrência';
      case ScaleFrequency.weekly:
        return 'Repete toda semana';
      case ScaleFrequency.biweekly:
        return 'Repete a cada 2 semanas';
      case ScaleFrequency.monthly:
        return 'Repete todo mês';
      case ScaleFrequency.custom:
        return 'Intervalo personalizado';
    }
  }
}

enum AssignmentStatus {
  active,
  paused,
  completed;

  String get label {
    switch (this) {
      case AssignmentStatus.active:
        return 'Ativa';
      case AssignmentStatus.paused:
        return 'Pausada';
      case AssignmentStatus.completed:
        return 'Concluída';
    }
  }
}

// ═══════════════════════════════════════════════════════
// SCALE ASSIGNMENT MODEL
// ═══════════════════════════════════════════════════════

class ScaleAssignmentModel {
  final String id;
  final String patientId;
  final String psychologistId;

  // Referência a uma OU outra escala (exclusivo)
  final String? scaleTemplateId;
  final String? customScaleId;

  final ScaleFrequency frequency;
  final AssignmentStatus status;

  final DateTime startDate;
  final DateTime? nextDueDate;
  final DateTime? lastCompletedAt;

  final bool notifyPatient;
  final String? customInstructions;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ScaleAssignmentModel({
    required this.id,
    required this.patientId,
    required this.psychologistId,
    this.scaleTemplateId,
    this.customScaleId,
    this.frequency = ScaleFrequency.once,
    this.status = AssignmentStatus.active,
    required this.startDate,
    this.nextDueDate,
    this.lastCompletedAt,
    this.notifyPatient = true,
    this.customInstructions,
    required this.createdAt,
    required this.updatedAt,
  });

  // ══════════════════════════════════════
  // FROM JSON (Supabase → Dart)
  // ══════════════════════════════════════
  factory ScaleAssignmentModel.fromJson(Map<String, dynamic> json) {
    return ScaleAssignmentModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      psychologistId: json['psychologist_id'] as String,
      scaleTemplateId: json['scale_template_id'] as String?,
      customScaleId: json['custom_scale_id'] as String?,
      frequency: _parseFrequency(json['frequency'] as String? ?? 'once'),
      status: _parseStatus(json['status'] as String? ?? 'active'),
      startDate: DateTime.parse(json['start_date'] as String),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      lastCompletedAt: json['last_completed_at'] != null
          ? DateTime.parse(json['last_completed_at'] as String)
          : null,
      notifyPatient: json['notify_patient'] as bool? ?? true,
      customInstructions: json['custom_instructions'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ══════════════════════════════════════
  // TO JSON (Dart → Supabase)
  // ══════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'psychologist_id': psychologistId,
      'scale_template_id': scaleTemplateId,
      'custom_scale_id': customScaleId,
      'frequency': frequency.name,
      'status': status.name,
      'start_date': startDate.toIso8601String().split('T').first,
      'next_due_date': nextDueDate?.toIso8601String().split('T').first,
      'last_completed_at': lastCompletedAt?.toIso8601String(),
      'notify_patient': notifyPatient,
      'custom_instructions': customInstructions,
    };
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════

  /// Retorna true se usa um template padrão
  bool get isTemplate => scaleTemplateId != null;

  /// Retorna o ID da escala (template ou custom)
  String get scaleId => scaleTemplateId ?? customScaleId ?? '';

  /// Retorna true se está pendente (ativa e com due_date vencida)
  bool get isPending {
    if (status != AssignmentStatus.active) return false;
    // Se nunca foi respondida, está pendente
    if (lastCompletedAt == null) return true;
    // Se já foi respondida e é escala única (sem nextDueDate): NÃO está pendente
    if (nextDueDate == null) return false;
    // Se tem próxima data: está pendente se a data já venceu
    return nextDueDate!.isBefore(DateTime.now()) ||
        nextDueDate!.isAtSameMomentAs(DateTime.now());
  }

  /// Retorna true se está atrasada
  bool get isOverdue {
    if (status != AssignmentStatus.active) return false;
    if (nextDueDate == null) return false;
    return nextDueDate!.isBefore(DateTime.now());
  }

  /// Label amigável da escala
  String get scaleLabel => isTemplate ? scaleTemplateId! : 'Escala personalizada';

  ScaleAssignmentModel copyWith({
    String? id,
    String? patientId,
    String? psychologistId,
    String? scaleTemplateId,
    String? customScaleId,
    ScaleFrequency? frequency,
    AssignmentStatus? status,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? lastCompletedAt,
    bool? notifyPatient,
    String? customInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScaleAssignmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      psychologistId: psychologistId ?? this.psychologistId,
      scaleTemplateId: scaleTemplateId ?? this.scaleTemplateId,
      customScaleId: customScaleId ?? this.customScaleId,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      notifyPatient: notifyPatient ?? this.notifyPatient,
      customInstructions: customInstructions ?? this.customInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static ScaleFrequency _parseFrequency(String value) {
    switch (value) {
      case 'once':
        return ScaleFrequency.once;
      case 'weekly':
        return ScaleFrequency.weekly;
      case 'biweekly':
        return ScaleFrequency.biweekly;
      case 'monthly':
        return ScaleFrequency.monthly;
      case 'custom':
        return ScaleFrequency.custom;
      default:
        return ScaleFrequency.once;
    }
  }

  static AssignmentStatus _parseStatus(String value) {
    switch (value) {
      case 'active':
        return AssignmentStatus.active;
      case 'paused':
        return AssignmentStatus.paused;
      case 'completed':
        return AssignmentStatus.completed;
      default:
        return AssignmentStatus.active;
    }
  }
}
