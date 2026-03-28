// lib/providers/achievement_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/achievement_model.dart';
import '../models/checkin_model.dart';
import '../models/task_model.dart';

// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
@immutable
class AchievementState {
  final bool isLoading;
  final List<AchievementModel> achievements;
  final List<AchievementType> newlyUnlocked;
  final String? error;

  const AchievementState({
    this.isLoading = false,
    this.achievements = const [],
    this.newlyUnlocked = const [],
    this.error,
  });

  AchievementState copyWith({
    bool? isLoading,
    List<AchievementModel>? achievements,
    List<AchievementType>? newlyUnlocked,
    String? error,
    bool clearError = false,
    bool clearNewlyUnlocked = false,
  }) {
    return AchievementState(
      isLoading: isLoading ?? this.isLoading,
      achievements: achievements ?? this.achievements,
      newlyUnlocked:
          clearNewlyUnlocked ? [] : (newlyUnlocked ?? this.newlyUnlocked),
      error: clearError ? null : (error ?? this.error),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  bool hasAchievement(AchievementType type) {
    return achievements.any((a) => a.type == type);
  }

  List<AchievementModel> get unlockedAchievements => achievements;

  List<AchievementType> get lockedAchievements {
    final unlocked = achievements.map((a) => a.type).toSet();
    return AchievementType.values.where((t) => !unlocked.contains(t)).toList();
  }

  List<AchievementModel> get unseenAchievements {
    return achievements.where((a) => !a.seen).toList();
  }

  int get totalXP {
    return achievements.fold(0, (sum, a) => sum + a.xpValue);
  }

  int get level {
    // Cada nível requer progressivamente mais XP
    // Nível 1: 0-50, Nível 2: 51-150, Nível 3: 151-300, etc.
    int xp = totalXP;
    int level = 1;
    int threshold = 50;

    while (xp >= threshold) {
      xp -= threshold;
      level++;
      threshold += 50;
    }

    return level;
  }

  double get levelProgress {
    int xp = totalXP;
    int level = 1;
    int threshold = 50;
    int accumulated = 0;

    while (xp >= threshold) {
      accumulated += threshold;
      xp -= threshold;
      level++;
      threshold += 50;
    }

    return xp / threshold;
  }

  int get xpForNextLevel {
    int xp = totalXP;
    int threshold = 50;

    while (xp >= threshold) {
      xp -= threshold;
      threshold += 50;
    }

    return threshold - xp;
  }

  Map<AchievementCategory, List<AchievementModel>> get byCategory {
    final map = <AchievementCategory, List<AchievementModel>>{};
    for (final category in AchievementCategory.values) {
      map[category] = achievements.where((a) => a.category == category).toList();
    }
    return map;
  }
}

// ══════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════
class AchievementNotifier extends Notifier<AchievementState> {
  @override
  AchievementState build() {
    return const AchievementState();
  }

  final _client = SupabaseService.client;

  // ══════════════════════════════════════
  // CARREGAR CONQUISTAS
  // ══════════════════════════════════════
  Future<void> loadAchievements(String patientId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('user_achievements')
          .select()
          .eq('patient_id', patientId)
          .order('unlocked_at', ascending: false);

      final achievements = (response as List)
          .map((json) => AchievementModel.fromJson(json))
          .toList();

      state = state.copyWith(
        achievements: achievements,
        isLoading: false,
      );

      debugPrint('=== ${achievements.length} CONQUISTAS CARREGADAS ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar conquistas: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // VERIFICAR E DESBLOQUEAR CONQUISTAS
  // ══════════════════════════════════════
  Future<void> checkAndUnlockAchievements({
    required String patientId,
    required List<CheckinModel> checkins,
    required List<TaskModel> tasks,
  }) async {
    final newAchievements = <AchievementType>[];

    // Check-in achievements
    newAchievements.addAll(_checkCheckinAchievements(checkins));

    // Task achievements
    newAchievements.addAll(_checkTaskAchievements(tasks));

    // Mood achievements
    newAchievements.addAll(_checkMoodAchievements(checkins));

    // Special achievements
    newAchievements.addAll(_checkSpecialAchievements(checkins, tasks));

    // Filtrar apenas os que ainda não foram desbloqueados
    final toUnlock = newAchievements
        .where((type) => !state.hasAchievement(type))
        .toList();

    if (toUnlock.isEmpty) return;

    // Salvar no banco
    for (final type in toUnlock) {
      await _unlockAchievement(patientId, type);
    }

    // Atualizar state com novos desbloqueios
    state = state.copyWith(newlyUnlocked: toUnlock);

    // Recarregar para ter os dados completos
    await loadAchievements(patientId);

    debugPrint('=== ${toUnlock.length} NOVAS CONQUISTAS DESBLOQUEADAS ===');
  }

  // ══════════════════════════════════════
  // CHECK-IN ACHIEVEMENTS
  // ══════════════════════════════════════
  List<AchievementType> _checkCheckinAchievements(List<CheckinModel> checkins) {
    final achievements = <AchievementType>[];

    if (checkins.isEmpty) return achievements;

    // Primeiro check-in
    if (checkins.isNotEmpty) {
      achievements.add(AchievementType.firstCheckin);
    }

    // Calcular streak
    final streak = _calculateStreak(checkins);

    if (streak >= 7) achievements.add(AchievementType.streak7);
    if (streak >= 30) achievements.add(AchievementType.streak30);
    if (streak >= 100) achievements.add(AchievementType.streak100);

    return achievements;
  }

  // ══════════════════════════════════════
  // TASK ACHIEVEMENTS
  // ══════════════════════════════════════
  List<AchievementType> _checkTaskAchievements(List<TaskModel> tasks) {
    final achievements = <AchievementType>[];

    final completed = tasks.where((t) => t.isCompleted).toList();

    if (completed.isEmpty) return achievements;

    // Primeira tarefa
    achievements.add(AchievementType.firstTask);

    // Quantidade total
    if (completed.length >= 10) achievements.add(AchievementType.tasks10);
    if (completed.length >= 50) achievements.add(AchievementType.tasks50);

    // Por tipo
    final breathingCount =
        completed.where((t) => t.taskType == TaskType.breathing).length;
    final thoughtCount =
        completed.where((t) => t.taskType == TaskType.thoughtRecord).length;
    final journalingCount =
        completed.where((t) => t.taskType == TaskType.journaling).length;
    final mindfulnessCount =
        completed.where((t) => t.taskType == TaskType.mindfulness).length;

    if (breathingCount >= 5) achievements.add(AchievementType.breathing5);
    if (breathingCount >= 20) achievements.add(AchievementType.breathing20);

    if (thoughtCount >= 5) achievements.add(AchievementType.thoughtRecord5);
    if (thoughtCount >= 20) achievements.add(AchievementType.thoughtRecord20);

    if (journalingCount >= 5) achievements.add(AchievementType.journaling5);
    if (journalingCount >= 20) achievements.add(AchievementType.journaling20);

    if (mindfulnessCount >= 5) achievements.add(AchievementType.mindfulness5);
    if (mindfulnessCount >= 20) achievements.add(AchievementType.mindfulness20);

    return achievements;
  }

  // ══════════════════════════════════════
  // MOOD ACHIEVEMENTS
  // ══════════════════════════════════════
  List<AchievementType> _checkMoodAchievements(List<CheckinModel> checkins) {
    final achievements = <AchievementType>[];

    if (checkins.length < 3) return achievements;

    // Ordenar por data
    final sorted = [...checkins]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Melhora de humor (3 dias seguidos melhorando)
    int improvementStreak = 0;
    for (int i = 0; i < sorted.length - 1; i++) {
      if (sorted[i].moodScore > sorted[i + 1].moodScore) {
        improvementStreak++;
      } else {
        break;
      }
    }

    if (improvementStreak >= 3) achievements.add(AchievementType.moodImprovement3);
    if (improvementStreak >= 7) achievements.add(AchievementType.moodImprovement7);

    // Humor consistente (variação <= 1 por 5 dias)
    if (sorted.length >= 5) {
      final last5 = sorted.take(5).toList();
      final moods = last5.map((c) => c.moodScore).toList();
      final maxDiff = moods.reduce((a, b) => a > b ? a : b) -
          moods.reduce((a, b) => a < b ? a : b);

      if (maxDiff <= 1) {
        achievements.add(AchievementType.consistentMood5);
      }
    }

    return achievements;
  }

  // ══════════════════════════════════════
  // SPECIAL ACHIEVEMENTS
  // ══════════════════════════════════════
  List<AchievementType> _checkSpecialAchievements(
    List<CheckinModel> checkins,
    List<TaskModel> tasks,
  ) {
    final achievements = <AchievementType>[];

    // Night Owl (check-in após meia-noite)
    final hasNightCheckin = checkins.any((c) {
      final hour = c.createdAt.hour;
      return hour >= 0 && hour < 5;
    });
    if (hasNightCheckin) achievements.add(AchievementType.nightOwl);

    // Early Bird (check-in antes das 7h)
    final hasEarlyCheckin = checkins.any((c) {
      final hour = c.createdAt.hour;
      return hour >= 5 && hour < 7;
    });
    if (hasEarlyCheckin) achievements.add(AchievementType.earlyBird);

    // Weekend Warrior (4 fins de semana seguidos)
    final weekendCount = _countConsecutiveWeekends(checkins);
    if (weekendCount >= 4) achievements.add(AchievementType.weekendWarrior);

    // Perfect Week (check-in + tarefa todo dia por 7 dias)
    if (_hasPerfectWeek(checkins, tasks)) {
      achievements.add(AchievementType.perfectWeek);
    }

    return achievements;
  }

  // ══════════════════════════════════════
  // UNLOCK ACHIEVEMENT
  // ══════════════════════════════════════
  Future<void> _unlockAchievement(String patientId, AchievementType type) async {
    try {
      await _client.from('user_achievements').insert({
        'patient_id': patientId,
        'achievement_type': type.name,
      });

      debugPrint('=== CONQUISTA DESBLOQUEADA: ${type.title} ===');
    } catch (e) {
      // Pode falhar se já existe (UNIQUE constraint) - ignorar
      debugPrint('Erro ao desbloquear conquista: $e');
    }
  }

  // ══════════════════════════════════════
  // MARCAR COMO VISTO
  // ══════════════════════════════════════
  Future<void> markAsSeen(String achievementId) async {
    try {
      await _client
          .from('user_achievements')
          .update({'seen': true})
          .eq('id', achievementId);

      final updated = state.achievements.map((a) {
        if (a.id == achievementId) {
          return a.copyWith(seen: true);
        }
        return a;
      }).toList();

      state = state.copyWith(achievements: updated);
    } catch (e) {
      debugPrint('Erro ao marcar conquista como vista: $e');
    }
  }

  // ══════════════════════════════════════
  // MARCAR TODOS COMO VISTOS
  // ══════════════════════════════════════
  Future<void> markAllAsSeen(String patientId) async {
    try {
      await _client
          .from('user_achievements')
          .update({'seen': true})
          .eq('patient_id', patientId)
          .eq('seen', false);

      final updated = state.achievements.map((a) {
        return a.copyWith(seen: true);
      }).toList();

      state = state.copyWith(achievements: updated);
    } catch (e) {
      debugPrint('Erro ao marcar conquistas como vistas: $e');
    }
  }

  // ══════════════════════════════════════
  // LIMPAR NOVOS DESBLOQUEIOS
  // ══════════════════════════════════════
  void clearNewlyUnlocked() {
    state = state.copyWith(clearNewlyUnlocked: true);
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  int _calculateStreak(List<CheckinModel> checkins) {
    if (checkins.isEmpty) return 0;

    final sorted = [...checkins]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Criar set de datas únicas
    final dates = <String>{};
    for (final checkin in sorted) {
      final date = DateTime(
        checkin.createdAt.year,
        checkin.createdAt.month,
        checkin.createdAt.day,
      );
      dates.add(date.toIso8601String().split('T')[0]);
    }

    final sortedDates = dates.toList()..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);

    // Se não tem check-in hoje, começar de ontem
    final todayStr = checkDate.toIso8601String().split('T')[0];
    if (!dates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    for (int i = 0; i < 365; i++) {
      final dateStr = checkDate.toIso8601String().split('T')[0];
      if (dates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int _countConsecutiveWeekends(List<CheckinModel> checkins) {
    if (checkins.isEmpty) return 0;

    // Agrupar por semana
    final weekendWeeks = <int>{};
    for (final checkin in checkins) {
      if (checkin.createdAt.weekday == 6 || checkin.createdAt.weekday == 7) {
        // Calcular número da semana
        final weekNumber = checkin.createdAt
            .difference(DateTime(checkin.createdAt.year, 1, 1))
            .inDays ~/
            7;
        weekendWeeks.add(weekNumber);
      }
    }

    if (weekendWeeks.isEmpty) return 0;

    final sorted = weekendWeeks.toList()..sort((a, b) => b.compareTo(a));

    int count = 1;
    for (int i = 0; i < sorted.length - 1; i++) {
      if (sorted[i] - sorted[i + 1] == 1) {
        count++;
      } else {
        break;
      }
    }

    return count;
  }

  bool _hasPerfectWeek(List<CheckinModel> checkins, List<TaskModel> tasks) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    // Verificar check-ins
    final recentCheckins = checkins.where((c) => c.createdAt.isAfter(weekAgo));
    final checkinDates = recentCheckins
        .map((c) => DateTime(c.createdAt.year, c.createdAt.month, c.createdAt.day))
        .toSet();

    // Verificar tarefas completas
    final completedTasks = tasks.where(
        (t) => t.isCompleted && t.dueDate.isAfter(weekAgo));
    final taskDates = completedTasks
        .map((t) => DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day))
        .toSet();

    // Verificar se todos os 7 dias têm check-in E tarefa
    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (!checkinDates.contains(dateOnly) || !taskDates.contains(dateOnly)) {
        return false;
      }
    }

    return true;
  }

  void clear() {
    state = const AchievementState();
  }
}

// ══════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════
final achievementProvider =
    NotifierProvider<AchievementNotifier, AchievementState>(
        AchievementNotifier.new);