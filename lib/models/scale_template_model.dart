// lib/models/scale_template_model.dart

// ═══════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════

enum ScaleCategory {
  depression,
  anxiety,
  progress,
  general;

  String get label {
    switch (this) {
      case ScaleCategory.depression:
        return 'Depressão';
      case ScaleCategory.anxiety:
        return 'Ansiedade';
      case ScaleCategory.progress:
        return 'Progresso';
      case ScaleCategory.general:
        return 'Geral';
    }
  }

  String get emoji {
    switch (this) {
      case ScaleCategory.depression:
        return '🌧️';
      case ScaleCategory.anxiety:
        return '⚡';
      case ScaleCategory.progress:
        return '📈';
      case ScaleCategory.general:
        return '📋';
    }
  }
}

enum SeverityLevel {
  minimal,
  mild,
  moderate,
  moderately_severe,
  severe;

  String get label {
    switch (this) {
      case SeverityLevel.minimal:
        return 'Mínimo';
      case SeverityLevel.mild:
        return 'Leve';
      case SeverityLevel.moderate:
        return 'Moderado';
      case SeverityLevel.moderately_severe:
        return 'Moderadamente Grave';
      case SeverityLevel.severe:
        return 'Grave';
    }
  }

  static SeverityLevel fromString(String value) {
    switch (value) {
      case 'minimal':
        return SeverityLevel.minimal;
      case 'mild':
        return SeverityLevel.mild;
      case 'moderate':
        return SeverityLevel.moderate;
      case 'moderately_severe':
        return SeverityLevel.moderately_severe;
      case 'severe':
        return SeverityLevel.severe;
      default:
        return SeverityLevel.minimal;
    }
  }
}

// ═══════════════════════════════════════════════════════
// RESPONSE OPTION
// ═══════════════════════════════════════════════════════

class ResponseOption {
  final int value;
  final String label;

  const ResponseOption({
    required this.value,
    required this.label,
  });

  factory ResponseOption.fromJson(Map<String, dynamic> json) {
    return ResponseOption(
      value: json['value'] as int,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
      };
}

// ═══════════════════════════════════════════════════════
// SCALE QUESTION
// ═══════════════════════════════════════════════════════

class ScaleQuestion {
  final String id;
  final int order;
  final String text;
  final bool required;
  final String? subscale;
  final bool isCritical;
  final int? alertThreshold;

  const ScaleQuestion({
    required this.id,
    required this.order,
    required this.text,
    this.required = true,
    this.subscale,
    this.isCritical = false,
    this.alertThreshold,
  });

  factory ScaleQuestion.fromJson(Map<String, dynamic> json) {
    return ScaleQuestion(
      id: json['id'] as String,
      order: json['order'] as int,
      text: json['text'] as String,
      required: json['required'] as bool? ?? true,
      subscale: json['subscale'] as String?,
      isCritical: json['is_critical'] as bool? ?? false,
      alertThreshold: json['alert_threshold'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order': order,
        'text': text,
        'required': required,
        'subscale': subscale,
        'is_critical': isCritical,
        'alert_threshold': alertThreshold,
      };

  ScaleQuestion copyWith({
    String? id,
    int? order,
    String? text,
    bool? required,
    String? subscale,
    bool? isCritical,
    int? alertThreshold,
  }) {
    return ScaleQuestion(
      id: id ?? this.id,
      order: order ?? this.order,
      text: text ?? this.text,
      required: required ?? this.required,
      subscale: subscale ?? this.subscale,
      isCritical: isCritical ?? this.isCritical,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }
}

// ═══════════════════════════════════════════════════════
// SEVERITY RANGE
// ═══════════════════════════════════════════════════════

class SeverityRange {
  final int min;
  final int max;
  final String level;
  final String label;
  final String color;

  const SeverityRange({
    required this.min,
    required this.max,
    required this.level,
    required this.label,
    required this.color,
  });

  factory SeverityRange.fromJson(Map<String, dynamic> json) {
    return SeverityRange(
      min: json['min'] as int,
      max: json['max'] as int,
      level: json['level'] as String,
      label: json['label'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'min': min,
        'max': max,
        'level': level,
        'label': label,
        'color': color,
      };

  static SeverityRange fromScore(int score, List<SeverityRange> ranges) {
    if (ranges.isEmpty) {
      // Se não há ranges definidos, retorna um range padrão
      return const SeverityRange(
        min: 0,
        max: 100,
        level: 'unknown',
        label: 'N/A',
        color: 'grey',
      );
    }
    
    return ranges.firstWhere(
      (r) => score >= r.min && score <= r.max,
      orElse: () => ranges.first,
    );
  }
}

// ═══════════════════════════════════════════════════════
// SCORING CONFIG
// ═══════════════════════════════════════════════════════

class ScoringConfig {
  final String method;
  final int minScore;
  final int maxScore;
  final List<String> reverseItems;
  final List<SeverityRange> severityRanges;
  final int? clinicalCutoff;
  final String? clinicalCutoffDescription;

  const ScoringConfig({
    this.method = 'sum',
    this.minScore = 0,
    required this.maxScore,
    this.reverseItems = const [],
    required this.severityRanges,
    this.clinicalCutoff,
    this.clinicalCutoffDescription,
  });

  factory ScoringConfig.fromJson(Map<String, dynamic> json) {
    final ranges = (json['severity_ranges'] as List<dynamic>?)
            ?.map((r) => SeverityRange.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return ScoringConfig(
      method: json['method'] as String? ?? 'sum',
      minScore: json['min_score'] as int? ?? 0,
      maxScore: json['max_score'] as int,
      reverseItems: (json['reverse_items'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      severityRanges: ranges,
      clinicalCutoff: json['clinical_cutoff'] as int?,
      clinicalCutoffDescription: json['clinical_cutoff_description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'min_score': minScore,
        'max_score': maxScore,
        'reverse_items': reverseItems,
        'severity_ranges': severityRanges.map((r) => r.toJson()).toList(),
        'clinical_cutoff': clinicalCutoff,
        'clinical_cutoff_description': clinicalCutoffDescription,
      };

  SeverityRange getSeverityLevel(int score) {
    return SeverityRange.fromScore(score, severityRanges);
  }

  ScoringConfig copyWith({
    String? method,
    int? minScore,
    int? maxScore,
    List<String>? reverseItems,
    List<SeverityRange>? severityRanges,
    int? clinicalCutoff,
    String? clinicalCutoffDescription,
  }) {
    return ScoringConfig(
      method: method ?? this.method,
      minScore: minScore ?? this.minScore,
      maxScore: maxScore ?? this.maxScore,
      reverseItems: reverseItems ?? this.reverseItems,
      severityRanges: severityRanges ?? this.severityRanges,
      clinicalCutoff: clinicalCutoff ?? this.clinicalCutoff,
      clinicalCutoffDescription:
          clinicalCutoffDescription ?? this.clinicalCutoffDescription,
    );
  }
}

// ═══════════════════════════════════════════════════════
// SUBSCALE
// ═══════════════════════════════════════════════════════

class Subscale {
  final String id;
  final String name;
  final List<String> items;

  const Subscale({
    required this.id,
    required this.name,
    required this.items,
  });

  factory Subscale.fromJson(Map<String, dynamic> json) {
    return Subscale(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items,
      };
}

// ═══════════════════════════════════════════════════════
// ALERT RULE
// ═══════════════════════════════════════════════════════

class AlertRule {
  final String condition;
  final String severity; // 'critical', 'high', 'medium', 'low'
  final String message;
  final String action;

  const AlertRule({
    required this.condition,
    required this.severity,
    required this.message,
    required this.action,
  });

  factory AlertRule.fromJson(Map<String, dynamic> json) {
    return AlertRule(
      condition: json['condition'] as String,
      severity: json['severity'] as String,
      message: json['message'] as String,
      action: json['action'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'condition': condition,
        'severity': severity,
        'message': message,
        'action': action,
      };

  bool get isCritical => severity == 'critical';
}

// ═══════════════════════════════════════════════════════
// SCALE TEMPLATE MODEL
// ═══════════════════════════════════════════════════════

class ScaleTemplateModel {
  final String id;
  final String name;
  final String fullName;
  final String? description;
  final ScaleCategory category;
  final bool isValidated;
  final String? reference;
  final int estimatedTimeMinutes;

  final String instructions;
  final List<ResponseOption> responseOptions;
  final List<ScaleQuestion> questions;
  final ScoringConfig scoring;
  final List<Subscale> subscales;
  final List<AlertRule> alerts;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ScaleTemplateModel({
    required this.id,
    required this.name,
    required this.fullName,
    this.description,
    required this.category,
    this.isValidated = true,
    this.reference,
    this.estimatedTimeMinutes = 5,
    required this.instructions,
    required this.responseOptions,
    required this.questions,
    required this.scoring,
    this.subscales = const [],
    this.alerts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ══════════════════════════════════════
  // FROM JSON (Supabase → Dart)
  // ══════════════════════════════════════
  factory ScaleTemplateModel.fromJson(Map<String, dynamic> json) {
    final responseOpts = (json['response_options'] as List<dynamic>?)
            ?.map((r) => ResponseOption.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    final questionsList = (json['questions'] as List<dynamic>?)
            ?.map((q) => ScaleQuestion.fromJson(q as Map<String, dynamic>))
            .toList() ??
        [];

    final subscalesList = (json['subscales'] as List<dynamic>?)
            ?.map((s) => Subscale.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    final alertsList = (json['alerts'] as List<dynamic>?)
            ?.map((a) => AlertRule.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    return ScaleTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      fullName: json['full_name'] as String,
      description: json['description'] as String?,
      category: _parseCategory(json['category'] as String),
      isValidated: json['is_validated'] as bool? ?? true,
      reference: json['reference'] as String?,
      estimatedTimeMinutes: json['estimated_time_minutes'] as int? ?? 5,
      instructions: json['instructions'] as String,
      responseOptions: responseOpts,
      questions: questionsList,
      scoring: ScoringConfig.fromJson(json['scoring'] as Map<String, dynamic>),
      subscales: subscalesList,
      alerts: alertsList,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ══════════════════════════════════════
  // TO JSON (Dart → Supabase)
  // ══════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_name': fullName,
      'description': description,
      'category': category.name,
      'is_validated': isValidated,
      'reference': reference,
      'estimated_time_minutes': estimatedTimeMinutes,
      'instructions': instructions,
      'response_options': responseOptions.map((r) => r.toJson()).toList(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'scoring': scoring.toJson(),
      'subscales': subscales.map((s) => s.toJson()).toList(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
    };
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════

  /// Calcula o score total a partir das respostas
  int calculateTotalScore(Map<String, int> answers) {
    int total = 0;
    for (final entry in answers.entries) {
      int value = entry.value;

      // Inverter itens reversos (ex: se resposta é 3, vira 0; 2 vira 1, etc.)
      if (scoring.reverseItems.contains(entry.key)) {
        value = scoring.maxScore ~/ questions.length - value;
      }

      total += value;
    }
    return total;
  }

  /// Determina o nível de severidade baseado no score
  SeverityRange getSeverityLevel(int score) {
    return scoring.getSeverityLevel(score);
  }

  /// Verifica se há itens críticos nas respostas
  List<CriticalFlag> checkCriticalItems(Map<String, int> answers) {
    final flags = <CriticalFlag>[];

    for (final question in questions) {
      if (question.isCritical && question.alertThreshold != null) {
        final answer = answers[question.id];
        if (answer != null && answer >= question.alertThreshold!) {
          flags.add(CriticalFlag(
            questionId: question.id,
            questionText: question.text,
            value: answer,
            threshold: question.alertThreshold!,
          ));
        }
      }
    }

    return flags;
  }

  /// Retorna o tempo estimado
  String get estimatedTime {
    if (estimatedTimeMinutes < 60) {
      return '~${estimatedTimeMinutes} min';
    }
    final hours = estimatedTimeMinutes ~/ 60;
    final mins = estimatedTimeMinutes % 60;
    return '~${hours}h${mins > 0 ? ' ${mins}min' : ''}';
  }

  static ScaleCategory _parseCategory(String value) {
    switch (value) {
      case 'depression':
        return ScaleCategory.depression;
      case 'anxiety':
        return ScaleCategory.anxiety;
      case 'progress':
        return ScaleCategory.progress;
      case 'general':
        return ScaleCategory.general;
      default:
        return ScaleCategory.general;
    }
  }

  ScaleTemplateModel copyWith({
    String? id,
    String? name,
    String? fullName,
    String? description,
    ScaleCategory? category,
    bool? isValidated,
    String? reference,
    int? estimatedTimeMinutes,
    String? instructions,
    List<ResponseOption>? responseOptions,
    List<ScaleQuestion>? questions,
    ScoringConfig? scoring,
    List<Subscale>? subscales,
    List<AlertRule>? alerts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScaleTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      description: description ?? this.description,
      category: category ?? this.category,
      isValidated: isValidated ?? this.isValidated,
      reference: reference ?? this.reference,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      instructions: instructions ?? this.instructions,
      responseOptions: responseOptions ?? this.responseOptions,
      questions: questions ?? this.questions,
      scoring: scoring ?? this.scoring,
      subscales: subscales ?? this.subscales,
      alerts: alerts ?? this.alerts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════
// CRITICAL FLAG (usado em resposta)
// ═══════════════════════════════════════════════════════

class CriticalFlag {
  final String questionId;
  final String questionText;
  final int value;
  final int threshold;

  const CriticalFlag({
    required this.questionId,
    required this.questionText,
    required this.value,
    required this.threshold,
  });

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'question_text': questionText,
        'value': value,
        'threshold': threshold,
        'message':
            'Item crítico: resposta $value (threshold: $threshold)',
      };

  factory CriticalFlag.fromJson(Map<String, dynamic> json) {
    return CriticalFlag(
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String? ?? '',
      value: json['value'] as int,
      threshold: json['threshold'] as int,
    );
  }
}
