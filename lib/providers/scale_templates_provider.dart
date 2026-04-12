// lib/providers/scale_templates_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/scale_template_model.dart';

// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
@immutable
class ScaleTemplatesState {
  final bool isLoading;
  final List<ScaleTemplateModel> templates;
  final String? error;

  const ScaleTemplatesState({
    this.isLoading = false,
    this.templates = const [],
    this.error,
  });

  ScaleTemplatesState copyWith({
    bool? isLoading,
    List<ScaleTemplateModel>? templates,
    String? error,
    bool clearError = false,
  }) {
    return ScaleTemplatesState(
      isLoading: isLoading ?? this.isLoading,
      templates: templates ?? this.templates,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════

  /// Templates por categoria
  Map<ScaleCategory, List<ScaleTemplateModel>> get byCategory {
    final map = <ScaleCategory, List<ScaleTemplateModel>>{};
    for (final template in templates) {
      map.putIfAbsent(template.category, () => []).add(template);
    }
    return map;
  }

  /// Templates de depressão
  List<ScaleTemplateModel> get depression =>
      templates.where((t) => t.category == ScaleCategory.depression).toList();

  /// Templates de ansiedade
  List<ScaleTemplateModel> get anxiety =>
      templates.where((t) => t.category == ScaleCategory.anxiety).toList();

  /// Templates de progresso
  List<ScaleTemplateModel> get progress =>
      templates.where((t) => t.category == ScaleCategory.progress).toList();

  /// Escala validada pelo ID (template padrão)
  ScaleTemplateModel? getTemplateById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ══════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════
class ScaleTemplatesNotifier extends Notifier<ScaleTemplatesState> {
  @override
  ScaleTemplatesState build() {
    return const ScaleTemplatesState();
  }

  final _client = SupabaseService.client;

  // ══════════════════════════════════════
  // CARREGAR TODOS OS TEMPLATES
  // ══════════════════════════════════════
  Future<void> loadTemplates() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('scale_templates')
          .select()
          .order('name', ascending: true);

      final templates = (response as List)
          .map((json) => ScaleTemplateModel.fromJson(json))
          .toList();

      state = state.copyWith(templates: templates, isLoading: false);
      debugPrint('=== ${templates.length} TEMPLATES DE ESCALA CARREGADOS ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar templates: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // CARREGAR POR CATEGORIA
  // ══════════════════════════════════════
  Future<void> loadByCategory(ScaleCategory category) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('scale_templates')
          .select()
          .eq('category', category.name)
          .order('name', ascending: true);

      final templates = (response as List)
          .map((json) => ScaleTemplateModel.fromJson(json))
          .toList();

      // Mantém os existentes e adiciona os da categoria
      final existing = List<ScaleTemplateModel>.from(state.templates);
      existing.removeWhere((t) => t.category == category);
      existing.addAll(templates);

      state = state.copyWith(templates: existing, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar templates: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // OBTER TEMPLATE POR ID (com fallback)
  // ══════════════════════════════════════
  Future<ScaleTemplateModel?> getTemplateById(String id) async {
    // Tenta do state primeiro
    final cached = state.getTemplateById(id);
    if (cached != null) return cached;

    // Se não tem, busca do banco
    try {
      final response = await _client
          .from('scale_templates')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return ScaleTemplateModel.fromJson(response);
    } catch (e) {
      debugPrint('Erro ao buscar template $id: $e');
      return null;
    }
  }

  // ══════════════════════════════════════
  // FORÇAR RELOAD
  // ══════════════════════════════════════
  Future<void> refresh() async {
    state = const ScaleTemplatesState();
    await loadTemplates();
  }

  void clear() {
    state = const ScaleTemplatesState();
  }
}

// ══════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════
final scaleTemplatesProvider =
    NotifierProvider<ScaleTemplatesNotifier, ScaleTemplatesState>(
  ScaleTemplatesNotifier.new,
);
