// lib/providers/scale_responses_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/scale_template_model.dart';
import '../models/scale_response_model.dart';

// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
@immutable
class ScaleResponsesState {
  final bool isLoading;
  final List<ScaleResponseModel> responses;
  final String? error;

  const ScaleResponsesState({
    this.isLoading = false,
    this.responses = const [],
    this.error,
  });

  ScaleResponsesState copyWith({
    bool? isLoading,
    List<ScaleResponseModel>? responses,
    String? error,
    bool clearError = false,
  }) {
    return ScaleResponsesState(
      isLoading: isLoading ?? this.isLoading,
      responses: responses ?? this.responses,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════

  /// Última resposta
  ScaleResponseModel? get latestResponse {
    try {
      if (responses.isEmpty) return null;
      return responses.first;
    } catch (e) {
      debugPrint('⚠️ Erro ao obter última resposta: $e');
      return null;
    }
  }

  /// Último score
  int? get latestScore {
    final latest = latestResponse;
    if (latest == null) return null;
    return latest.totalScore;
  }

  /// Último nível de severidade
  String? get latestSeverity {
    final latest = latestResponse;
    if (latest == null) return null;
    return latest.severityLevel;
  }

  /// Respostas com itens críticos
  List<ScaleResponseModel> get criticalResponses =>
      responses.where((r) => r.isCritical).toList();

  /// Tendência: retornando true se o score está diminuindo (melhorando)
  bool get isImproving {
    try {
      if (responses.length < 2) return false;
      final sorted = List<ScaleResponseModel>.from(responses)
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      final recent = sorted.first.totalScore;
      final older = sorted.last.totalScore;
      return recent < older; // Score menor = melhor
    } catch (e) {
      debugPrint('⚠️ Erro ao calcular tendência: $e');
      return false;
    }
  }

  /// Dados prontos para gráfico de evolução
  List<ScaleEvolutionPoint> get evolutionData {
    try {
      final sorted = List<ScaleResponseModel>.from(responses)
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
      return sorted
          .map((r) => ScaleEvolutionPoint.fromResponse(r))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Erro ao gerar dados de evolução: $e');
      return [];
    }
  }

  /// Resposta por ID
  ScaleResponseModel? getResponseById(String id) {
    try {
      return responses.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ══════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════
class ScaleResponsesNotifier extends Notifier<ScaleResponsesState> {
  @override
  ScaleResponsesState build() {
    return const ScaleResponsesState();
  }

  final _client = SupabaseService.client;

  // ══════════════════════════════════════
  // CARREGAR RESPOSTAS DE UMA ASSIGNMENT
  // ══════════════════════════════════════
  Future<void> loadForAssignment(String assignmentId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('scale_responses')
          .select()
          .eq('assignment_id', assignmentId)
          .order('completed_at', ascending: false)
          .limit(100);

      final responses = (response as List)
          .map((json) => ScaleResponseModel.fromJson(json))
          .toList();

      state = state.copyWith(responses: responses, isLoading: false);
      debugPrint('=== ${responses.length} RESPOSTAS CARREGADAS ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar respostas: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // CARREGAR TODAS AS RESPOSTAS DE UM PACIENTE
  // ══════════════════════════════════════
  Future<void> loadForPatient(String patientId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('scale_responses')
          .select()
          .eq('patient_id', patientId)
          .order('completed_at', ascending: false)
          .limit(200);

      final responses = (response as List)
          .map((json) => ScaleResponseModel.fromJson(json))
          .toList();

      state = state.copyWith(responses: responses, isLoading: false);
      debugPrint('=== ${responses.length} RESPOSTAS DO PACIENTE ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar respostas do paciente: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // ENVIAR RESPOSTA (calcula score automaticamente)
  // ══════════════════════════════════════
  Future<bool> submitResponse({
    required String assignmentId,
    required String patientId,
    required Map<String, int> answers,
    required int totalScore,
    required String severityLevel,
    required Map<String, double> subscaleScores,
    required List<CriticalFlag> criticalFlags,
    int? durationSeconds,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // Monta o objeto de resposta
      final response = ScaleResponseModel.calculate(
        assignmentId: assignmentId,
        patientId: patientId,
        answers: answers,
        totalScore: totalScore,
        severityLevel: severityLevel,
        subscaleScores: subscaleScores,
        criticalFlags: criticalFlags,
        durationSeconds: durationSeconds,
      );

      // Converte para JSON
      final data = response.toJson();

      debugPrint('=== ENVIANDO RESPOSTA PARA O BANCO ===');
      debugPrint('Assignment ID: ${response.assignmentId}');
      debugPrint('Patient ID: ${response.patientId}');
      debugPrint('Total Score: ${response.totalScore}');
      debugPrint('Severity: ${response.severityLevel}');
      debugPrint('Completed At: ${response.completedAt}');

      // Insere no Supabase
      final insertedResponse = await _client
          .from('scale_responses')
          .insert(data)
          .select()
          .single();

      debugPrint('=== RESPOSTA INSERIDA COM SUCESSO ===');
      debugPrint('Response ID: ${insertedResponse['id']}');
      debugPrint('Completed At: ${insertedResponse['completed_at']}');

      // ═══════════════════════════════════════════════════
      // ATUALIZAR ASSIGNMENT VIA FUNÇÃO SQL (ignora RLS)
      // ═══════════════════════════════════════════════════
      debugPrint('=== ATUALIZANDO ASSIGNMENT VIA FUNÇÃO SQL ===');
      
      try {
        // Buscar info do assignment para saber a frequência
        final assignmentData = await _client
            .from('scale_assignments')
            .select('frequency')
            .eq('id', response.assignmentId)
            .maybeSingle();

        if (assignmentData != null) {
          final frequency = assignmentData['frequency'] as String? ?? 'once';
          
          // Calcular próxima data baseado na frequência
          String? nextDueDate;
          String newStatus = 'active';
          final completedAt = insertedResponse['completed_at'] as String;
          
          if (frequency == 'weekly') {
            final date = DateTime.parse(completedAt).add(const Duration(days: 7));
            nextDueDate = date.toIso8601String().split('T').first;
          } else if (frequency == 'biweekly') {
            final date = DateTime.parse(completedAt).add(const Duration(days: 14));
            nextDueDate = date.toIso8601String().split('T').first;
          } else if (frequency == 'monthly') {
            final date = DateTime.parse(completedAt);
            final nextMonth = DateTime(date.year, date.month + 1, date.day);
            nextDueDate = nextMonth.toIso8601String().split('T').first;
          } else if (frequency == 'once') {
            nextDueDate = null;
            newStatus = 'completed'; // Marcar como completada
          }
          
          debugPrint('  Frequency: $frequency');
          debugPrint('  Next Due Date: $nextDueDate');
          debugPrint('  New Status: $newStatus');

          // Chamar função SQL que ignora RLS
          // Nota: O PostgREST suporta chamar funções RPC via .rpc()
          final rpcData = <String, dynamic>{
            'p_assignment_id': response.assignmentId,
            'p_completed_at': completedAt,
            'p_next_due_date': nextDueDate,
            'p_status': newStatus,
          };

          debugPrint('  Chamando RPC: patient_complete_assignment');
          debugPrint('  Params: $rpcData');

          await _client.rpc(
            'patient_complete_assignment',
            params: rpcData,
          );

          debugPrint('✅ Assignment atualizado com sucesso via função SQL!');
        } else {
          debugPrint('⚠️ Assignment não encontrado para atualizar');
        }
      } catch (e) {
        debugPrint('❌ ERRO ao atualizar assignment: $e');
        // Não falha a resposta se o assignment update falhar
        // A resposta já foi salva com sucesso
      }

      // Recarrega as respostas
      await loadForAssignment(assignmentId);

      debugPrint('=== RESPOSTA ENVIADA: score=$totalScore, severidade=$severityLevel ===');
      if (criticalFlags.isNotEmpty) {
        debugPrint('⚠️ ITENS CRÍTICOS DETECTADOS: ${criticalFlags.length}');
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao enviar resposta: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // ENVIAR RESPOSTA COM CÁLCULO AUTOMÁTICO
  // Usa a escala para calcular tudo sozinho
  // ══════════════════════════════════════
  Future<bool> submitResponseAuto({
    required String assignmentId,
    required String patientId,
    required Map<String, int> answers,
    required Map<String, dynamic> scaleScoring, // scoring JSON da escala
    required List<ScaleQuestion> questions,
    required List<Subscale> subscales,
    int? durationSeconds,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // 1. Calcular score total
      int totalScore = 0;
      for (final entry in answers.entries) {
        int value = entry.value;
        // Inverter itens reversos
        final reverseItems = (scaleScoring['reverse_items'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [];
        if (reverseItems.contains(entry.key)) {
          final maxScore = scaleScoring['max_score'] as int;
          final questionCount = questions.length;
          value = (maxScore ~/ questionCount) - value;
        }
        totalScore += value;
      }

      // 2. Determinar severidade
      final severityRanges = (scaleScoring['severity_ranges'] as List<dynamic>?)
              ?.map((r) => SeverityRange.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [];
      final severity = SeverityRange.fromScore(totalScore, severityRanges);

      // 3. Calcular subescalas
      final subscaleScores = <String, double>{};
      for (final subscale in subscales) {
        double sum = 0;
        int count = 0;
        for (final itemId in subscale.items) {
          if (answers.containsKey(itemId)) {
            sum += answers[itemId]!;
            count++;
          }
        }
        subscaleScores[subscale.id] = count > 0 ? sum / count : 0;
      }

      // 4. Verificar itens críticos
      final criticalFlags = <CriticalFlag>[];
      for (final question in questions) {
        if (question.isCritical && question.alertThreshold != null) {
          final answer = answers[question.id];
          if (answer != null && answer >= question.alertThreshold!) {
            criticalFlags.add(CriticalFlag(
              questionId: question.id,
              questionText: question.text,
              value: answer,
              threshold: question.alertThreshold!,
            ));
          }
        }
      }

      // 5. Enviar
      return submitResponse(
        assignmentId: assignmentId,
        patientId: patientId,
        answers: answers,
        totalScore: totalScore,
        severityLevel: severity.level,
        subscaleScores: subscaleScores,
        criticalFlags: criticalFlags,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao calcular e enviar resposta: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // DADOS DE EVOLUÇÃO (pra gráfico)
  // ══════════════════════════════════════
  Future<List<ScaleEvolutionPoint>> getEvolutionData(String assignmentId) async {
    try {
      final response = await _client
          .from('scale_responses')
          .select()
          .eq('assignment_id', assignmentId)
          .order('completed_at', ascending: true)
          .limit(100);

      final responses = (response as List)
          .map((json) => ScaleResponseModel.fromJson(json))
          .toList();

      return responses
          .map((r) => ScaleEvolutionPoint.fromResponse(r))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar dados de evolução: $e');
      return [];
    }
  }

  // ══════════════════════════════════════
  // DELETAR RESPOSTA (apenas psicólogo, via RLS)
  // ══════════════════════════════════════
  Future<bool> deleteResponse(String id) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _client.from('scale_responses').delete().eq('id', id);

      final updatedResponses =
          state.responses.where((r) => r.id != id).toList();

      state = state.copyWith(responses: updatedResponses, isLoading: false);
      debugPrint('=== RESPOSTA DELETADA: $id ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao deletar resposta: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // REFRESH
  // ══════════════════════════════════════
  Future<void> refreshForAssignment(String assignmentId) async {
    state = const ScaleResponsesState();
    await loadForAssignment(assignmentId);
  }

  void clear() {
    state = const ScaleResponsesState();
  }
}

// ══════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════
final scaleResponsesProvider =
    NotifierProvider<ScaleResponsesNotifier, ScaleResponsesState>(
  ScaleResponsesNotifier.new,
);
