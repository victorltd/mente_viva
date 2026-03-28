// lib/providers/feature_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/psychologist_model.dart';

// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
@immutable
class FeatureState {
  final bool isLoading;
  final PsychologistFeatures features;
  final String? error;

  const FeatureState({
    this.isLoading = false,
    this.features = const PsychologistFeatures(),
    this.error,
  });

  FeatureState copyWith({
    bool? isLoading,
    PsychologistFeatures? features,
    String? error,
    bool clearError = false,
  }) {
    return FeatureState(
      isLoading: isLoading ?? this.isLoading,
      features: features ?? this.features,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Atalhos
  bool get tasksEnabled => features.tasks;
  bool get chatEnabled => features.chat;
}

// ══════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════
class FeatureNotifier extends Notifier<FeatureState> {
  @override
  FeatureState build() {
    return const FeatureState();
  }

  final _client = SupabaseService.client;

  // ══════════════════════════════════════
  // CARREGAR FEATURES DO PSICÓLOGO
  // (chamado pelo psicólogo logado)
  // ══════════════════════════════════════
  Future<void> loadFeatures() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final userId = SupabaseService.currentUserId;
      if (userId == null) return;

      final response = await _client
          .from('psychologists')
          .select('features')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final features = PsychologistFeatures.fromJson(
          response['features'] as Map<String, dynamic>?,
        );
        state = state.copyWith(features: features, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      debugPrint('=== FEATURES: tasks=${state.tasksEnabled}, chat=${state.chatEnabled} ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar features: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // CARREGAR FEATURES PARA UM PACIENTE
  // (busca via psychologist_id do paciente)
  // ══════════════════════════════════════
  Future<void> loadFeaturesForPatient(String psychologistId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('psychologists')
          .select('features')
          .eq('id', psychologistId)
          .maybeSingle();

      if (response != null) {
        final features = PsychologistFeatures.fromJson(
          response['features'] as Map<String, dynamic>?,
        );
        state = state.copyWith(features: features, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar features: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // TOGGLE FEATURE
  // ══════════════════════════════════════
  Future<bool> toggleFeature(String featureName, bool enabled) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return false;

      // Atualizar localmente primeiro
      PsychologistFeatures updated;
      switch (featureName) {
        case 'tasks':
          updated = state.features.copyWith(tasks: enabled);
          break;
        case 'chat':
          updated = state.features.copyWith(chat: enabled);
          break;
        default:
          return false;
      }

      state = state.copyWith(features: updated);

      // Salvar no Supabase
      await _client
          .from('psychologists')
          .update({'features': updated.toJson()})
          .eq('id', userId);

      debugPrint('=== FEATURE "$featureName" = $enabled ===');
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao atualizar feature: $e');
      return false;
    }
  }

  void clear() {
    state = const FeatureState();
  }
}

// ══════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════
final featureProvider =
    NotifierProvider<FeatureNotifier, FeatureState>(FeatureNotifier.new);