// lib/models/achievement_model.dart

import 'package:flutter/material.dart';

// ══════════════════════════════════════
// ENUM DE TIPOS DE CONQUISTA
// ══════════════════════════════════════
enum AchievementType {
  // Check-in
  firstCheckin,
  streak7,
  streak30,
  streak100,
  
  // Tarefas
  firstTask,
  tasks10,
  tasks50,
  
  // Específicas por tipo
  breathing5,
  breathing20,
  thoughtRecord5,
  thoughtRecord20,
  journaling5,
  journaling20,
  mindfulness5,
  mindfulness20,
  
  // Humor
  moodImprovement3,
  moodImprovement7,
  consistentMood5,
  
  // Especiais
  nightOwl,
  earlyBird,
  weekendWarrior,
  perfectWeek;

  // ══════════════════════════════════════
  // PROPRIEDADES
  // ══════════════════════════════════════
  String get id => name;

  String get title {
    switch (this) {
      case AchievementType.firstCheckin:
        return 'Primeiro Passo';
      case AchievementType.streak7:
        return 'Consistente';
      case AchievementType.streak30:
        return 'Dedicado';
      case AchievementType.streak100:
        return 'Lendário';
      case AchievementType.firstTask:
        return 'Tarefa Cumprida';
      case AchievementType.tasks10:
        return 'Produtivo';
      case AchievementType.tasks50:
        return 'Máquina';
      case AchievementType.breathing5:
        return 'Respira Fundo';
      case AchievementType.breathing20:
        return 'Zen Master';
      case AchievementType.thoughtRecord5:
        return 'Pensador';
      case AchievementType.thoughtRecord20:
        return 'Filósofo';
      case AchievementType.journaling5:
        return 'Escritor';
      case AchievementType.journaling20:
        return 'Autor';
      case AchievementType.mindfulness5:
        return 'Presente';
      case AchievementType.mindfulness20:
        return 'Iluminado';
      case AchievementType.moodImprovement3:
        return 'Subindo';
      case AchievementType.moodImprovement7:
        return 'Superação';
      case AchievementType.consistentMood5:
        return 'Equilíbrio';
      case AchievementType.nightOwl:
        return 'Coruja';
      case AchievementType.earlyBird:
        return 'Madrugador';
      case AchievementType.weekendWarrior:
        return 'Guerreiro de Fim de Semana';
      case AchievementType.perfectWeek:
        return 'Semana Perfeita';
    }
  }

  String get description {
    switch (this) {
      case AchievementType.firstCheckin:
        return 'Fez seu primeiro check-in emocional';
      case AchievementType.streak7:
        return '7 dias seguidos de check-in';
      case AchievementType.streak30:
        return '30 dias seguidos de check-in';
      case AchievementType.streak100:
        return '100 dias seguidos de check-in';
      case AchievementType.firstTask:
        return 'Completou sua primeira tarefa';
      case AchievementType.tasks10:
        return 'Completou 10 tarefas';
      case AchievementType.tasks50:
        return 'Completou 50 tarefas';
      case AchievementType.breathing5:
        return '5 exercícios de respiração';
      case AchievementType.breathing20:
        return '20 exercícios de respiração';
      case AchievementType.thoughtRecord5:
        return '5 registros de pensamento';
      case AchievementType.thoughtRecord20:
        return '20 registros de pensamento';
      case AchievementType.journaling5:
        return '5 entradas no diário';
      case AchievementType.journaling20:
        return '20 entradas no diário';
      case AchievementType.mindfulness5:
        return '5 sessões de mindfulness';
      case AchievementType.mindfulness20:
        return '20 sessões de mindfulness';
      case AchievementType.moodImprovement3:
        return 'Humor melhorou por 3 dias seguidos';
      case AchievementType.moodImprovement7:
        return 'Humor melhorou por 7 dias seguidos';
      case AchievementType.consistentMood5:
        return 'Manteve humor estável por 5 dias';
      case AchievementType.nightOwl:
        return 'Fez check-in após meia-noite';
      case AchievementType.earlyBird:
        return 'Fez check-in antes das 7h';
      case AchievementType.weekendWarrior:
        return 'Check-in em 4 fins de semana seguidos';
      case AchievementType.perfectWeek:
        return 'Check-in + tarefa todos os dias da semana';
    }
  }

  String get emoji {
    switch (this) {
      case AchievementType.firstCheckin:
        return '🌱';
      case AchievementType.streak7:
        return '🔥';
      case AchievementType.streak30:
        return '🏆';
      case AchievementType.streak100:
        return '👑';
      case AchievementType.firstTask:
        return '✅';
      case AchievementType.tasks10:
        return '📋';
      case AchievementType.tasks50:
        return '⚡';
      case AchievementType.breathing5:
        return '🫁';
      case AchievementType.breathing20:
        return '🧘';
      case AchievementType.thoughtRecord5:
        return '🧠';
      case AchievementType.thoughtRecord20:
        return '💡';
      case AchievementType.journaling5:
        return '📝';
      case AchievementType.journaling20:
        return '📚';
      case AchievementType.mindfulness5:
        return '🧘‍♀️';
      case AchievementType.mindfulness20:
        return '✨';
      case AchievementType.moodImprovement3:
        return '📈';
      case AchievementType.moodImprovement7:
        return '💪';
      case AchievementType.consistentMood5:
        return '⚖️';
      case AchievementType.nightOwl:
        return '🦉';
      case AchievementType.earlyBird:
        return '🐦';
      case AchievementType.weekendWarrior:
        return '🗡️';
      case AchievementType.perfectWeek:
        return '🌟';
    }
  }

  Color get color {
    switch (this) {
      case AchievementType.firstCheckin:
      case AchievementType.firstTask:
        return const Color(0xFF10B981); // Green
      case AchievementType.streak7:
      case AchievementType.streak30:
      case AchievementType.streak100:
        return const Color(0xFFF59E0B); // Amber
      case AchievementType.tasks10:
      case AchievementType.tasks50:
        return const Color(0xFF6C63FF); // Primary
      case AchievementType.breathing5:
      case AchievementType.breathing20:
        return const Color(0xFF3B82F6); // Blue
      case AchievementType.thoughtRecord5:
      case AchievementType.thoughtRecord20:
        return const Color(0xFF8B5CF6); // Purple
      case AchievementType.journaling5:
      case AchievementType.journaling20:
        return const Color(0xFF06B6D4); // Cyan
      case AchievementType.mindfulness5:
      case AchievementType.mindfulness20:
        return const Color(0xFF00BFA6); // Teal
      case AchievementType.moodImprovement3:
      case AchievementType.moodImprovement7:
      case AchievementType.consistentMood5:
        return const Color(0xFFEC4899); // Pink
      case AchievementType.nightOwl:
        return const Color(0xFF1E293B); // Dark
      case AchievementType.earlyBird:
        return const Color(0xFFFBBF24); // Yellow
      case AchievementType.weekendWarrior:
        return const Color(0xFFEF4444); // Red
      case AchievementType.perfectWeek:
        return const Color(0xFFFFD700); // Gold
    }
  }

  int get xpValue {
    switch (this) {
      case AchievementType.firstCheckin:
      case AchievementType.firstTask:
        return 10;
      case AchievementType.streak7:
      case AchievementType.breathing5:
      case AchievementType.thoughtRecord5:
      case AchievementType.journaling5:
      case AchievementType.mindfulness5:
        return 25;
      case AchievementType.streak30:
      case AchievementType.tasks10:
      case AchievementType.moodImprovement3:
        return 50;
      case AchievementType.breathing20:
      case AchievementType.thoughtRecord20:
      case AchievementType.journaling20:
      case AchievementType.mindfulness20:
      case AchievementType.consistentMood5:
      case AchievementType.nightOwl:
      case AchievementType.earlyBird:
        return 75;
      case AchievementType.streak100:
      case AchievementType.tasks50:
      case AchievementType.moodImprovement7:
      case AchievementType.weekendWarrior:
      case AchievementType.perfectWeek:
        return 100;
    }
  }

  AchievementCategory get category {
    switch (this) {
      case AchievementType.firstCheckin:
      case AchievementType.streak7:
      case AchievementType.streak30:
      case AchievementType.streak100:
        return AchievementCategory.checkin;
      case AchievementType.firstTask:
      case AchievementType.tasks10:
      case AchievementType.tasks50:
        return AchievementCategory.tasks;
      case AchievementType.breathing5:
      case AchievementType.breathing20:
      case AchievementType.thoughtRecord5:
      case AchievementType.thoughtRecord20:
      case AchievementType.journaling5:
      case AchievementType.journaling20:
      case AchievementType.mindfulness5:
      case AchievementType.mindfulness20:
        return AchievementCategory.exercises;
      case AchievementType.moodImprovement3:
      case AchievementType.moodImprovement7:
      case AchievementType.consistentMood5:
        return AchievementCategory.mood;
      case AchievementType.nightOwl:
      case AchievementType.earlyBird:
      case AchievementType.weekendWarrior:
      case AchievementType.perfectWeek:
        return AchievementCategory.special;
    }
  }

  static AchievementType? fromString(String value) {
    try {
      return AchievementType.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }
}

// ══════════════════════════════════════
// CATEGORIAS
// ══════════════════════════════════════
enum AchievementCategory {
  checkin,
  tasks,
  exercises,
  mood,
  special;

  String get title {
    switch (this) {
      case AchievementCategory.checkin:
        return 'Check-ins';
      case AchievementCategory.tasks:
        return 'Tarefas';
      case AchievementCategory.exercises:
        return 'Exercícios';
      case AchievementCategory.mood:
        return 'Humor';
      case AchievementCategory.special:
        return 'Especiais';
    }
  }

  String get emoji {
    switch (this) {
      case AchievementCategory.checkin:
        return '📊';
      case AchievementCategory.tasks:
        return '✅';
      case AchievementCategory.exercises:
        return '🧘';
      case AchievementCategory.mood:
        return '💜';
      case AchievementCategory.special:
        return '⭐';
    }
  }
}

// ══════════════════════════════════════
// MODEL
// ══════════════════════════════════════
class AchievementModel {
  final String id;
  final String patientId;
  final AchievementType type;
  final DateTime unlockedAt;
  final bool seen;

  AchievementModel({
    required this.id,
    required this.patientId,
    required this.type,
    required this.unlockedAt,
    this.seen = false,
  });

  // Getters de conveniência
  String get title => type.title;
  String get description => type.description;
  String get emoji => type.emoji;
  Color get color => type.color;
  int get xpValue => type.xpValue;
  AchievementCategory get category => type.category;

  // ══════════════════════════════════════
  // FROM JSON
  // ══════════════════════════════════════
  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      type: AchievementType.fromString(json['achievement_type'] as String) ??
          AchievementType.firstCheckin,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      seen: json['seen'] as bool? ?? false,
    );
  }

  // ══════════════════════════════════════
  // TO JSON
  // ══════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'achievement_type': type.name,
      'seen': seen,
    };
  }

  // ══════════════════════════════════════
  // COPY WITH
  // ══════════════════════════════════════
  AchievementModel copyWith({
    String? id,
    String? patientId,
    AchievementType? type,
    DateTime? unlockedAt,
    bool? seen,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      seen: seen ?? this.seen,
    );
  }
}