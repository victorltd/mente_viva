// lib/providers/custom_scales_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/scale_template_model.dart';
import '../models/custom_scale_model.dart';

// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
@immutable
class CustomScalesState {
  final bool isLoading;
  final List<CustomScaleModel> scales;
  final String? error;

  const CustomScalesState({
    this.isLoading = false,
    this.scales = const [],
    this.error,
  });

  CustomScalesState copyWith({
    bool? isLoading,
    List<CustomScaleModel>? scales,
    String? error,
    bool clearError = false,
  }) {
    return CustomScalesState(
      isLoading: isLoading ?? this.isLoading,
      scales: scales ?? this.scales,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════

  /// Escalas que são rascunhos
  List<CustomScaleModel> get drafts =>
      scales.where((s) => s.isDraft).toList();

  /// Escalas finalizadas (não rascunhos)
  List<CustomScaleModel> get published =>
      scales.where((s) => !s.isDraft).toList();

  /// Escalas baseadas em templates
  List<CustomScaleModel> get basedOnTemplates =>
      scales.where((s) => s.isBasedOnTemplate).toList();

  /// Escalas totalmente customizadas (sem base)
  List<CustomScaleModel> get fullyCustom =>
      scales.where((s) => !s.isBasedOnTemplate).toList();

  /// Escala por ID
  CustomScaleModel? getScaleById(String id) {
    try {
      return scales.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ══════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════
class CustomScalesNotifier extends Notifier<CustomScalesState> {
  @override
  CustomScalesState build() {
    return const CustomScalesState();
  }

  final _client = SupabaseService.client;

  // ══════════════════════════════════════
  // CARREGAR ESCALAS DO PSICÓLOGO
  // ══════════════════════════════════════
  Future<void> loadScales(String psychologistId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('custom_scales')
          .select()
          .eq('psychologist_id', psychologistId)
          .order('created_at', ascending: false);

      final scales = (response as List)
          .map((json) => CustomScaleModel.fromJson(json))
          .toList();

      state = state.copyWith(scales: scales, isLoading: false);
      debugPrint('=== ${scales.length} ESCALAS CUSTOMIZADAS CARREGADAS ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar escalas: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // CRIAR ESCALA CUSTOMIZADA
  // ══════════════════════════════════════
  Future<bool> createScale(CustomScaleModel scale) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final data = scale.toJson();
      // Converter listas para JSONB
      data['response_options'] = scale.responseOptions.map((r) => r.toJson()).toList();
      data['questions'] = scale.questions.map((q) => q.toJson()).toList();
      data['scoring'] = scale.scoring.toJson();
      data['subscales'] = scale.subscales.map((s) => s.toJson()).toList();
      data['alerts'] = scale.alerts.map((a) => a.toJson()).toList();

      final response = await _client
          .from('custom_scales')
          .insert(data)
          .select()
          .single();

      final newScale = CustomScaleModel.fromJson(response);
      final updatedScales = [newScale, ...state.scales];

      state = state.copyWith(scales: updatedScales, isLoading: false);
      debugPrint('=== ESCALA CUSTOMIZADA CRIADA: ${newScale.name} ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar escala: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // ATUALIZAR ESCALA CUSTOMIZADA
  // ══════════════════════════════════════
  Future<bool> updateScale(CustomScaleModel scale) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final data = scale.toJson();
      // Converter listas para JSONB
      data['response_options'] = scale.responseOptions.map((r) => r.toJson()).toList();
      data['questions'] = scale.questions.map((q) => q.toJson()).toList();
      data['scoring'] = scale.scoring.toJson();
      data['subscales'] = scale.subscales.map((s) => s.toJson()).toList();
      data['alerts'] = scale.alerts.map((a) => a.toJson()).toList();

      await _client
          .from('custom_scales')
          .update(data)
          .eq('id', scale.id);

      final updatedScales = state.scales.map((s) {
        if (s.id == scale.id) return scale;
        return s;
      }).toList();

      state = state.copyWith(scales: updatedScales, isLoading: false);
      debugPrint('=== ESCALA ATUALIZADA: ${scale.name} ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar escala: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // DELETAR ESCALA
  // ══════════════════════════════════════
  Future<bool> deleteScale(String id) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _client.from('custom_scales').delete().eq('id', id);

      final updatedScales =
          state.scales.where((s) => s.id != id).toList();

      state = state.copyWith(scales: updatedScales, isLoading: false);
      debugPrint('=== ESCALA DELETADA: $id ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao deletar escala: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // PUBLICAR RASCUNHO
  // ══════════════════════════════════════
  Future<bool> publishScale(String id) async {
    final scale = state.getScaleById(id);
    if (scale == null) return false;

    return updateScale(scale.copyWith(isDraft: false, isValidated: false));
  }

  // ══════════════════════════════════════
  // DUPLICAR ESCALA (baseada em template ou custom)
  // ══════════════════════════════════════
  Future<bool> duplicateScale(CustomScaleModel original, String psychologistId) async {
    final duplicate = CustomScaleModel(
      id: '', // Gerado pelo Supabase
      psychologistId: psychologistId,
      baseTemplateId: original.baseTemplateId,
      name: '${original.name} (cópia)',
      description: original.description,
      instructions: original.instructions,
      responseOptions: original.responseOptions,
      questions: original.questions,
      scoring: original.scoring,
      subscales: original.subscales,
      alerts: original.alerts,
      isValidated: false,
      isDraft: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return createScale(duplicate);
  }

  // ══════════════════════════════════════
  // OBTER ESCALA POR ID (com fallback do banco)
  // ══════════════════════════════════════
  Future<CustomScaleModel?> getScaleById(String id) async {
    final cached = state.getScaleById(id);
    if (cached != null) return cached;

    try {
      final response = await _client
          .from('custom_scales')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return CustomScaleModel.fromJson(response);
    } catch (e) {
      debugPrint('Erro ao buscar escala customizada $id: $e');
      return null;
    }
  }

  // ══════════════════════════════════════
  // REFRESH
  // ══════════════════════════════════════
  Future<void> refresh(String psychologistId) async {
    state = const CustomScalesState();
    await loadScales(psychologistId);
  }

  void clear() {
    state = const CustomScalesState();
  }
}

// ══════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════
final customScalesProvider =
    NotifierProvider<CustomScalesNotifier, CustomScalesState>(
  CustomScalesNotifier.new,
);
