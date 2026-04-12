// lib/models/custom_scale_model.dart

import 'scale_template_model.dart';

// ═══════════════════════════════════════════════════════
// CUSTOM SCALE MODEL
// Escala criada/editada pelo psicólogo
// ═══════════════════════════════════════════════════════

class CustomScaleModel {
  final String id;
  final String psychologistId;
  final String? baseTemplateId; // Se foi customizada a partir de um template

  final String name;
  final String? description;
  final String instructions;
  final List<ResponseOption> responseOptions;
  final List<ScaleQuestion> questions;
  final ScoringConfig scoring;
  final List<Subscale> subscales;
  final List<AlertRule> alerts;

  final bool isValidated;
  final bool isDraft;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomScaleModel({
    required this.id,
    required this.psychologistId,
    this.baseTemplateId,
    required this.name,
    this.description,
    required this.instructions,
    required this.responseOptions,
    required this.questions,
    required this.scoring,
    this.subscales = const [],
    this.alerts = const [],
    this.isValidated = false,
    this.isDraft = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // ══════════════════════════════════════
  // FROM JSON (Supabase → Dart)
  // ══════════════════════════════════════
  factory CustomScaleModel.fromJson(Map<String, dynamic> json) {
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

    return CustomScaleModel(
      id: json['id'] as String,
      psychologistId: json['psychologist_id'] as String,
      baseTemplateId: json['base_template_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String,
      responseOptions: responseOpts,
      questions: questionsList,
      scoring: ScoringConfig.fromJson(json['scoring'] as Map<String, dynamic>),
      subscales: subscalesList,
      alerts: alertsList,
      isValidated: json['is_validated'] as bool? ?? false,
      isDraft: json['is_draft'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ══════════════════════════════════════
  // TO JSON (Dart → Supabase)
  // ══════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'psychologist_id': psychologistId,
      'base_template_id': baseTemplateId,
      'name': name,
      'description': description,
      'instructions': instructions,
      'response_options': responseOptions.map((r) => r.toJson()).toList(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'scoring': scoring.toJson(),
      'subscales': subscales.map((s) => s.toJson()).toList(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'is_validated': isValidated,
      'is_draft': isDraft,
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

      if (scoring.reverseItems.contains(entry.key)) {
        value = scoring.maxScore ~/ questions.length - value;
      }

      total += value;
    }
    return total;
  }

  /// Determina o nível de severidade
  SeverityRange getSeverityLevel(int score) {
    return scoring.getSeverityLevel(score);
  }

  /// Verifica itens críticos
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

  /// Tempo estimado de resposta
  String get estimatedTime {
    // Estimativa: ~30 segundos por pergunta
    final seconds = questions.length * 30;
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '~${minutes} min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '~${hours}h${mins > 0 ? ' ${mins}min' : ''}';
  }

  /// Se foi baseada em um template
  bool get isBasedOnTemplate => baseTemplateId != null;

  CustomScaleModel copyWith({
    String? id,
    String? psychologistId,
    String? baseTemplateId,
    String? name,
    String? description,
    String? instructions,
    List<ResponseOption>? responseOptions,
    List<ScaleQuestion>? questions,
    ScoringConfig? scoring,
    List<Subscale>? subscales,
    List<AlertRule>? alerts,
    bool? isValidated,
    bool? isDraft,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomScaleModel(
      id: id ?? this.id,
      psychologistId: psychologistId ?? this.psychologistId,
      baseTemplateId: baseTemplateId ?? this.baseTemplateId,
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      responseOptions: responseOptions ?? this.responseOptions,
      questions: questions ?? this.questions,
      scoring: scoring ?? this.scoring,
      subscales: subscales ?? this.subscales,
      alerts: alerts ?? this.alerts,
      isValidated: isValidated ?? this.isValidated,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ══════════════════════════════════════
  // FACTORY: Criar a partir de um template
  // ══════════════════════════════════════
  factory CustomScaleModel.fromTemplate({
    required ScaleTemplateModel template,
    required String psychologistId,
  }) {
    return CustomScaleModel(
      id: '', // Será gerado pelo Supabase
      psychologistId: psychologistId,
      baseTemplateId: template.id,
      name: '${template.name} (Personalizada)',
      description: template.description,
      instructions: template.instructions,
      responseOptions: template.responseOptions,
      questions: template.questions,
      scoring: template.scoring,
      subscales: template.subscales,
      alerts: template.alerts,
      isValidated: false,
      isDraft: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
