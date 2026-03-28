// lib/providers/checkin_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/checkin_model.dart';

// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
@immutable
class CheckinState {
  final bool isLoading;
  final List<CheckinModel> checkins;
  final String? error;
  final bool submitted;

  const CheckinState({
    this.isLoading = false,
    this.checkins = const [],
    this.error,
    this.submitted = false,
  });

  CheckinState copyWith({
    bool? isLoading,
    List<CheckinModel>? checkins,
    String? error,
    bool? submitted,
    bool clearError = false,
  }) {
    return CheckinState(
      isLoading: isLoading ?? this.isLoading,
      checkins: checkins ?? this.checkins,
      error: clearError ? null : (error ?? this.error),
      submitted: submitted ?? this.submitted,
    );
  }

  // ══════════════════════════════════════
  // HELPERS - AGRUPADOS POR DIA
  // ══════════════════════════════════════

  /// Retorna apenas o ÚLTIMO check-in de cada dia
  List<CheckinModel> get uniqueDailyCheckins {
    final Map<String, CheckinModel> dailyMap = {};

    for (final checkin in checkins) {
      final dayKey = _dayKey(checkin.createdAt);
      // Como a lista vem ordenada DESC (mais recente primeiro),
      // o primeiro de cada dia é o mais recente
      if (!dailyMap.containsKey(dayKey)) {
        dailyMap[dayKey] = checkin;
      }
    }

    // Retorna ordenado por data DESC
    final list = dailyMap.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Média de humor (baseado em 1 por dia)
  double get averageMood {
    final daily = uniqueDailyCheckins;
    if (daily.isEmpty) return 0;
    final sum = daily.fold<int>(0, (sum, c) => sum + c.moodScore);
    return sum / daily.length;
  }

  /// Último check-in
  CheckinModel? get lastCheckin {
    if (checkins.isEmpty) return null;
    return checkins.first;
  }

  /// Já fez check-in hoje?
  bool get hasCheckinToday {
    if (checkins.isEmpty) return false;
    final now = DateTime.now();
    final last = checkins.first.createdAt;
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  /// Check-ins da última semana (1 por dia, o mais recente)
  List<CheckinModel> get weekCheckins {
    final now = DateTime.now();
    final weekAgo = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7));

    return uniqueDailyCheckins
        .where((c) => c.createdAt.isAfter(weekAgo))
        .toList();
  }

  /// Contagem de streak (dias CONSECUTIVOS)
  int get streak {
    final daily = uniqueDailyCheckins;
    if (daily.isEmpty) return 0;

    int count = 0;
    final now = DateTime.now();
    DateTime expectedDate = DateTime(now.year, now.month, now.day);

    for (final checkin in daily) {
      final checkinDate = DateTime(
        checkin.createdAt.year,
        checkin.createdAt.month,
        checkin.createdAt.day,
      );

      if (checkinDate == expectedDate) {
        // Check-in no dia esperado
        count++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (count == 0 &&
          checkinDate == expectedDate.subtract(const Duration(days: 1))) {
        // Se ainda não contou nenhum e o último foi ontem
        // (não fez hoje ainda mas fez ontem)
        expectedDate = checkinDate;
        count++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else {
        // Quebrou a sequência
        break;
      }
    }

    return count;
  }

  /// Total de dias com check-in
  int get totalDays => uniqueDailyCheckins.length;

  // Helper para gerar chave do dia
  static String _dayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ══════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════
class CheckinNotifier extends Notifier<CheckinState> {
  @override
  CheckinState build() {
    return const CheckinState();
  }

  final _client = SupabaseService.client;

  // ══════════════════════════════════════
  // CARREGAR CHECK-INS
  // ══════════════════════════════════════
  Future<void> loadCheckins(String patientId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('checkins')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(90);

      final checkins = (response as List)
          .map((json) => CheckinModel.fromJson(json))
          .toList();

      state = state.copyWith(
        checkins: checkins,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar check-ins: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // ENVIAR CHECK-IN (cria ou atualiza)
  // ══════════════════════════════════════
  Future<bool> submitCheckin({
    required String patientId,
    required int moodScore,
    required String primaryEmotion,
    int? energyLevel,
    int? sleepQuality,
    String? notes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // Verificar se já existe check-in HOJE
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      final existing = await _client
          .from('checkins')
          .select('id')
          .eq('patient_id', patientId)
          .gte('created_at', todayStart)
          .lte('created_at', todayEnd)
          .maybeSingle();

      if (existing != null) {
        // ══════════════════════════════════════
        // JÁ EXISTE HOJE → ATUALIZA
        // ══════════════════════════════════════
        await _client.from('checkins').update({
          'mood_score': moodScore,
          'primary_emotion': primaryEmotion,
          'energy_level': energyLevel,
          'sleep_quality': sleepQuality,
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);

        print('=== CHECK-IN ATUALIZADO (já existia hoje) ===');
      } else {
        // ══════════════════════════════════════
        // NÃO EXISTE HOJE → CRIA NOVO
        // ══════════════════════════════════════
        await _client.from('checkins').insert({
          'patient_id': patientId,
          'mood_score': moodScore,
          'primary_emotion': primaryEmotion,
          'energy_level': energyLevel,
          'sleep_quality': sleepQuality,
          'notes': notes,
        });

        print('=== NOVO CHECK-IN CRIADO ===');
      }

      // Recarrega
      await loadCheckins(patientId);

      state = state.copyWith(submitted: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao registrar check-in: $e',
      );
      return false;
    }
  }

  void resetSubmitted() {
    state = state.copyWith(submitted: false);
  }
}

// ══════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════
final checkinProvider =
    NotifierProvider<CheckinNotifier, CheckinState>(CheckinNotifier.new);