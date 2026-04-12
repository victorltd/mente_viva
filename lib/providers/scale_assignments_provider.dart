// lib/providers/scale_assignments_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/scale_assignment_model.dart';
import '../models/scale_template_model.dart';

// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
@immutable
class ScaleAssignmentsState {
  final bool isLoading;
  final List<ScaleAssignmentModel> assignments;
  final String? error;

  const ScaleAssignmentsState({
    this.isLoading = false,
    this.assignments = const [],
    this.error,
  });

  ScaleAssignmentsState copyWith({
    bool? isLoading,
    List<ScaleAssignmentModel>? assignments,
    String? error,
    bool clearError = false,
  }) {
    return ScaleAssignmentsState(
      isLoading: isLoading ?? this.isLoading,
      assignments: assignments ?? this.assignments,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════

  /// Escalas ativas
  List<ScaleAssignmentModel> get active =>
      assignments.where((a) => a.status == AssignmentStatus.active).toList();

  /// Escalas pendentes (ativas e com due_date vencida ou nula)
  List<ScaleAssignmentModel> get pending =>
      active.where((a) => a.isPending).toList();

  /// Escalas atrasadas
  List<ScaleAssignmentModel> get overdue =>
      active.where((a) => a.isOverdue).toList();

  /// Escalas pausadas
  List<ScaleAssignmentModel> get paused =>
      assignments.where((a) => a.status == AssignmentStatus.paused).toList();

  /// Escalas concluídas
  List<ScaleAssignmentModel> get completed =>
      assignments.where((a) => a.status == AssignmentStatus.completed).toList();

  /// Escala por ID
  ScaleAssignmentModel? getAssignmentById(String id) {
    try {
      return assignments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ══════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════
class ScaleAssignmentsNotifier extends Notifier<ScaleAssignmentsState> {
  @override
  ScaleAssignmentsState build() {
    return const ScaleAssignmentsState();
  }

  final _client = SupabaseService.client;

  // ══════════════════════════════════════
  // CARREGAR ESCALAS ATRIBUÍDAS AO PACIENTE
  // ══════════════════════════════════════
  Future<void> loadForPatient(String patientId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('scale_assignments')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      final assignments = (response as List)
          .map((json) => ScaleAssignmentModel.fromJson(json))
          .toList();

      state = state.copyWith(assignments: assignments, isLoading: false);
      debugPrint('=== ${assignments.length} ESCALAS ATRIBUÍDAS CARREGADAS ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar escalas: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // CARREGAR APENAS PENDENTES (pra responder)
  // ══════════════════════════════════════
  Future<void> loadPendingForPatient(String patientId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // Buscar TODAS as escalas do paciente (sem filtrar por status)
      // para debug
      final responseAll = await _client
          .from('scale_assignments')
          .select()
          .eq('patient_id', patientId)
          .order('next_due_date', ascending: true)
          .order('created_at', ascending: false);

      debugPrint('=== DEBUG: ${((responseAll) as List).length} ESCALAS TOTAIS DO PACIENTE ===');
      for (var a in responseAll) {
        debugPrint('  - ID: ${a['id']}');
        debugPrint('    Status: ${a['status']}');
        debugPrint('    lastCompletedAt: ${a['last_completed_at']}');
        debugPrint('    nextDueDate: ${a['next_due_date']}');
        debugPrint('    frequency: ${a['frequency']}');
      }

      // Agora buscar apenas as ativas
      final response = await _client
          .from('scale_assignments')
          .select()
          .eq('patient_id', patientId)
          .eq('status', AssignmentStatus.active.name)
          .order('next_due_date', ascending: true)
          .order('created_at', ascending: false);

      final allAssignments = (response as List)
          .map((json) => ScaleAssignmentModel.fromJson(json))
          .toList();

      debugPrint('=== ${allAssignments.length} ESCALAS ATIVAS CARREGADAS ===');

      // Filtra só as pendentes no Dart
      // Lógica: se nunca respondida (lastCompletedAt == null) → SEMPRE pendente
      // Se já respondida → próxima data vencida
      final now = DateTime.now();
      final pending = allAssignments.where((a) {
        if (a.status != AssignmentStatus.active) return false;
        
        // Primeira vez (nunca respondida): sempre pendente
        if (a.lastCompletedAt == null) return true;
        
        // Já respondida:
        // - Se frequência é 'once' (nextDueDate == null): NÃO está pendente (já foi completada)
        // - Se tem próxima data: só está pendente se a data já venceu
        if (a.nextDueDate == null) return false; // Escala única já completada
        return !a.nextDueDate!.isAfter(now);
      }).toList();

      state = state.copyWith(assignments: pending, isLoading: false);
      debugPrint('=== ${pending.length} ESCALAS PENDENTES (FINAL) ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar escalas pendentes: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // ATRIBUIR ESCALA AO PACIENTE
  // ══════════════════════════════════════
  Future<bool> assignScale({
    required String patientId,
    required String psychologistId,
    String? scaleTemplateId,
    String? customScaleId,
    ScaleFrequency frequency = ScaleFrequency.once,
    DateTime? startDate,
    String? customInstructions,
  }) async {
    try {
      // Garante que só uma escala é referenciada
      assert(
        (scaleTemplateId != null && customScaleId == null) ||
            (scaleTemplateId == null && customScaleId != null),
        'Informe apenas scaleTemplateId OU customScaleId',
      );

      state = state.copyWith(isLoading: true, clearError: true);

      final now = DateTime.now();
      final start = startDate ?? now;

      // Calcula next_due_date baseado na frequência
      DateTime? nextDueDate;
      if (frequency != ScaleFrequency.once) {
        nextDueDate = _calculateNextDueDate(start, frequency);
      }

      final data = {
        'patient_id': patientId,
        'psychologist_id': psychologistId,
        'scale_template_id': scaleTemplateId,
        'custom_scale_id': customScaleId,
        'frequency': frequency.name,
        'status': AssignmentStatus.active.name,
        'start_date': start.toIso8601String().split('T').first,
        'next_due_date': nextDueDate?.toIso8601String().split('T').first,
        'notify_patient': true,
        'custom_instructions': customInstructions,
      };

      final response = await _client
          .from('scale_assignments')
          .insert(data)
          .select()
          .single();

      final newAssignment = ScaleAssignmentModel.fromJson(response);
      final updatedAssignments = [newAssignment, ...state.assignments];

      state = state.copyWith(
        assignments: updatedAssignments,
        isLoading: false,
      );

      debugPrint('=== ESCALA ATRIBUÍDA: ${newAssignment.scaleLabel} ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atribuir escala: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // ATUALIZAR ASSIGNMENT
  // ══════════════════════════════════════
  Future<bool> updateAssignment(ScaleAssignmentModel assignment) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _client
          .from('scale_assignments')
          .update({
            'frequency': assignment.frequency.name,
            'status': assignment.status.name,
            'start_date': assignment.startDate.toIso8601String().split('T').first,
            'next_due_date':
                assignment.nextDueDate?.toIso8601String().split('T').first,
            'notify_patient': assignment.notifyPatient,
            'custom_instructions': assignment.customInstructions,
          })
          .eq('id', assignment.id);

      final updatedAssignments = state.assignments.map((a) {
        if (a.id == assignment.id) return assignment;
        return a;
      }).toList();

      state = state.copyWith(
        assignments: updatedAssignments,
        isLoading: false,
      );

      debugPrint('=== ASSIGNMENT ATUALIZADO: ${assignment.id} ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar assignment: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // PAUSAR ESCALA
  // ══════════════════════════════════════
  Future<bool> pauseAssignment(String id) async {
    final assignment = state.getAssignmentById(id);
    if (assignment == null) return false;

    return updateAssignment(
      assignment.copyWith(status: AssignmentStatus.paused),
    );
  }

  // ══════════════════════════════════════
  // REATIVAR ESCALA
  // ══════════════════════════════════════
  Future<bool> resumeAssignment(String id) async {
    final assignment = state.getAssignmentById(id);
    if (assignment == null) return false;

    // Recalcula next_due_date
    final nextDueDate = _calculateNextDueDate(
      DateTime.now(),
      assignment.frequency,
    );

    return updateAssignment(
      assignment.copyWith(
        status: AssignmentStatus.active,
        nextDueDate: nextDueDate,
      ),
    );
  }

  // ══════════════════════════════════════
  // DESATIVAR ESCALA
  // ══════════════════════════════════════
  Future<bool> deactivateAssignment(String id) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _client
          .from('scale_assignments')
          .update({'status': AssignmentStatus.completed.name})
          .eq('id', id);

      final updatedAssignments = state.assignments.map((a) {
        if (a.id == id) {
          return a.copyWith(status: AssignmentStatus.completed);
        }
        return a;
      }).toList();

      state = state.copyWith(
        assignments: updatedAssignments,
        isLoading: false,
      );

      debugPrint('=== ESCALA DESATIVADA: $id ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao desativar escala: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // DELETAR ASSIGNMENT
  // ══════════════════════════════════════
  Future<bool> deleteAssignment(String id) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _client.from('scale_assignments').delete().eq('id', id);

      final updatedAssignments =
          state.assignments.where((a) => a.id != id).toList();

      state = state.copyWith(
        assignments: updatedAssignments,
        isLoading: false,
      );

      debugPrint('=== ASSIGNMENT DELETADO: $id ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao deletar assignment: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // REFRESH
  // ══════════════════════════════════════
  Future<void> refresh(String patientId) async {
    state = const ScaleAssignmentsState();
    await loadForPatient(patientId);
  }

  // ══════════════════════════════════════
  // HELPER: Calcular próxima data
  // ══════════════════════════════════════
  DateTime? _calculateNextDueDate(DateTime from, ScaleFrequency frequency) {
    switch (frequency) {
      case ScaleFrequency.once:
        return null;
      case ScaleFrequency.weekly:
        return from.add(const Duration(days: 7));
      case ScaleFrequency.biweekly:
        return from.add(const Duration(days: 14));
      case ScaleFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case ScaleFrequency.custom:
        return null;
    }
  }

  void clear() {
    state = const ScaleAssignmentsState();
  }
}

// ══════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════
final scaleAssignmentsProvider =
    NotifierProvider<ScaleAssignmentsNotifier, ScaleAssignmentsState>(
  ScaleAssignmentsNotifier.new,
);
