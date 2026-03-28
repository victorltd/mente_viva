// lib/models/task_model.dart

// ══════════════════════════════════════
// ENUMS
// ══════════════════════════════════════
enum TaskType {
  breathing,
  thoughtRecord,
  journaling,
  mindfulness,
  behavioral,
  custom;

  String get value {
    switch (this) {
      case TaskType.breathing:
        return 'breathing';
      case TaskType.thoughtRecord:
        return 'thought_record';
      case TaskType.journaling:
        return 'journaling';
      case TaskType.mindfulness:
        return 'mindfulness';
      case TaskType.behavioral:
        return 'behavioral';
      case TaskType.custom:
        return 'custom';
    }
  }

  String get label {
    switch (this) {
      case TaskType.breathing:
        return 'Exercício de Respiração';
      case TaskType.thoughtRecord:
        return 'Registro de Pensamento';
      case TaskType.journaling:
        return 'Diário / Journaling';
      case TaskType.mindfulness:
        return 'Mindfulness';
      case TaskType.behavioral:
        return 'Atividade Comportamental';
      case TaskType.custom:
        return 'Personalizada';
    }
  }

  String get emoji {
    switch (this) {
      case TaskType.breathing:
        return '🫁';
      case TaskType.thoughtRecord:
        return '📝';
      case TaskType.journaling:
        return '📓';
      case TaskType.mindfulness:
        return '🧘';
      case TaskType.behavioral:
        return '🎯';
      case TaskType.custom:
        return '✨';
    }
  }

  static TaskType fromString(String value) {
    switch (value) {
      case 'breathing':
        return TaskType.breathing;
      case 'thought_record':
        return TaskType.thoughtRecord;
      case 'journaling':
        return TaskType.journaling;
      case 'mindfulness':
        return TaskType.mindfulness;
      case 'behavioral':
        return TaskType.behavioral;
      case 'custom':
      default:
        return TaskType.custom;
    }
  }
}

enum TaskStatus {
  pending,
  completed,
  skipped,
  expired;

  String get value {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.skipped:
        return 'skipped';
      case TaskStatus.expired:
        return 'expired';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pendente';
      case TaskStatus.completed:
        return 'Concluída';
      case TaskStatus.skipped:
        return 'Pulada';
      case TaskStatus.expired:
        return 'Expirada';
    }
  }

  static TaskStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return TaskStatus.completed;
      case 'skipped':
        return TaskStatus.skipped;
      case 'expired':
        return TaskStatus.expired;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }
}

// ══════════════════════════════════════
// MODEL
// ══════════════════════════════════════
class TaskModel {
  final String id;
  final String psychologistId;
  final String patientId;
  final String title;
  final String? description;
  final TaskType taskType;
  final Map<String, dynamic> taskConfig;
  final DateTime dueDate;
  final bool isRecurring;
  final String? recurrencePattern;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    required this.psychologistId,
    required this.patientId,
    required this.title,
    this.description,
    required this.taskType,
    this.taskConfig = const {},
    required this.dueDate,
    this.isRecurring = false,
    this.recurrencePattern,
    this.status = TaskStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  bool get isPending => status == TaskStatus.pending;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isSkipped => status == TaskStatus.skipped;
  bool get isExpired => status == TaskStatus.expired;

  String get typeEmoji => taskType.emoji;
  String get typeLabel => taskType.label;

  bool get isOverdue {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return isPending && dueDate.isBefore(today);
  }

  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  // ══════════════════════════════════════
  // FROM JSON (Supabase → Dart)
  // ══════════════════════════════════════
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      psychologistId: json['psychologist_id'] as String,
      patientId: json['patient_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      taskType: TaskType.fromString(json['task_type'] as String),
      taskConfig: (json['task_config'] as Map<String, dynamic>?) ?? {},
      dueDate: DateTime.parse(json['due_date'] as String),
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: json['recurrence_pattern'] as String?,
      status: TaskStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // ══════════════════════════════════════
  // TO JSON (Dart → Supabase)
  // ══════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'psychologist_id': psychologistId,
      'patient_id': patientId,
      'title': title,
      'description': description,
      'task_type': taskType.value,
      'task_config': taskConfig,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'status': status.value,
    };
  }

  // ══════════════════════════════════════
  // COPY WITH
  // ══════════════════════════════════════
  TaskModel copyWith({
    String? id,
    String? psychologistId,
    String? patientId,
    String? title,
    String? description,
    TaskType? taskType,
    Map<String, dynamic>? taskConfig,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurrencePattern,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      psychologistId: psychologistId ?? this.psychologistId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      taskConfig: taskConfig ?? this.taskConfig,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}