// lib/providers/task_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/task_model.dart';
import '../models/task_response_model.dart';

// ══════════════════════════════════════
// STATE
// ══════════════════════════════════════
@immutable
class TaskState {
  final bool isLoading;
  final List<TaskModel> tasks;
  final List<TaskResponseModel> responses;
  final String? error;

  const TaskState({
    this.isLoading = false,
    this.tasks = const [],
    this.responses = const [],
    this.error,
  });

  TaskState copyWith({
    bool? isLoading,
    List<TaskModel>? tasks,
    List<TaskResponseModel>? responses,
    String? error,
    bool clearError = false,
  }) {
    return TaskState(
      isLoading: isLoading ?? this.isLoading,
      tasks: tasks ?? this.tasks,
      responses: responses ?? this.responses,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // ══════════════════════════════════════
  // FILTROS
  // ══════════════════════════════════════
  List<TaskModel> get pendingTasks =>
      tasks.where((t) => t.isPending).toList();

  List<TaskModel> get completedTasks =>
      tasks.where((t) => t.isCompleted).toList();

  List<TaskModel> get todayTasks {
    final now = DateTime.now();
    return tasks.where((t) {
      return t.dueDate.year == now.year &&
          t.dueDate.month == now.month &&
          t.dueDate.day == now.day;
    }).toList();
  }

  List<TaskModel> get todayPendingTasks =>
      todayTasks.where((t) => t.isPending).toList();

  List<TaskModel> get todayCompletedTasks =>
      todayTasks.where((t) => t.isCompleted).toList();

  double get todayProgress {
    if (todayTasks.isEmpty) return 0;
    return todayCompletedTasks.length / todayTasks.length;
  }

  // ══════════════════════════════════════
  // STREAK
  // ══════════════════════════════════════
  int get streak {
    if (tasks.isEmpty) return 0;

    int count = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    if (todayPendingTasks.isNotEmpty) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    for (int i = 0; i < 365; i++) {
      final dayTasks = tasks.where((t) {
        final d = t.dueDate;
        return d.year == checkDate.year &&
            d.month == checkDate.month &&
            d.day == checkDate.day;
      }).toList();

      if (dayTasks.isEmpty) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      final allCompleted = dayTasks.every((t) => t.isCompleted);
      if (allCompleted) {
        count++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return count;
  }
}

// ══════════════════════════════════════
// NOTIFIER
// ══════════════════════════════════════
class TaskNotifier extends Notifier<TaskState> {
  @override
  TaskState build() {
    return const TaskState();
  }

  final _client = SupabaseService.client;

  // ══════════════════════════════════════
  // PACIENTE: Carregar suas tarefas
  // ══════════════════════════════════════
  Future<void> loadPatientTasks(String patientId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('tasks')
          .select()
          .eq('patient_id', patientId)
          .gte(
            'due_date',
            DateTime.now()
                .subtract(const Duration(days: 7))
                .toIso8601String()
                .split('T')[0],
          )
          .order('due_date', ascending: true)
          .order('created_at', ascending: false);

      final tasks = (response as List)
          .map((json) => TaskModel.fromJson(json))
          .toList();

      state = state.copyWith(tasks: tasks, isLoading: false);
      debugPrint('=== ${tasks.length} TAREFAS CARREGADAS ===');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar tarefas: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // PSICÓLOGO: Carregar tarefas de um paciente
  // ══════════════════════════════════════
  Future<void> loadTasksForPatient(String patientId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('tasks')
          .select()
          .eq('patient_id', patientId)
          .order('due_date', ascending: false)
          .order('created_at', ascending: false);

      final tasks = (response as List)
          .map((json) => TaskModel.fromJson(json))
          .toList();

      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar tarefas: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // PSICÓLOGO: Criar tarefa
  // ══════════════════════════════════════
  Future<bool> createTask({
    required String psychologistId,
    required String patientId,
    required String title,
    String? description,
    required TaskType taskType,
    Map<String, dynamic> taskConfig = const {},
    required DateTime dueDate,
    bool isRecurring = false,
    String? recurrencePattern,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final taskData = {
        'psychologist_id': psychologistId,
        'patient_id': patientId,
        'title': title,
        'description': description,
        'task_type': taskType.value,
        'task_config': taskConfig,
        'due_date': dueDate.toIso8601String().split('T')[0],
        'is_recurring': isRecurring,
        'recurrence_pattern': recurrencePattern,
        'status': 'pending',
      };

      final response = await _client
          .from('tasks')
          .insert(taskData)
          .select()
          .single();

      final newTask = TaskModel.fromJson(response);
      final updatedTasks = [newTask, ...state.tasks];

      if (isRecurring && recurrencePattern != null) {
        final recurring = await _createRecurringTasks(
          taskData: taskData,
          pattern: recurrencePattern!,
          startDate: dueDate,
        );
        updatedTasks.addAll(recurring);
      }

      state = state.copyWith(tasks: updatedTasks, isLoading: false);
      debugPrint('=== TAREFA CRIADA: ${newTask.title} ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar tarefa: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // PACIENTE: Completar tarefa
  // ══════════════════════════════════════
  Future<bool> completeTask({
    required String taskId,
    required String patientId,
    required Map<String, dynamic> responseData,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await _client.from('task_responses').insert({
        'task_id': taskId,
        'patient_id': patientId,
        'response_data': responseData,
        'duration_seconds': responseData['duration_seconds'],
        'completed_at': DateTime.now().toIso8601String(),
      });

      await _client
          .from('tasks')
          .update({'status': 'completed'})
          .eq('id', taskId);

      final updatedTasks = state.tasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(status: TaskStatus.completed);
        }
        return t;
      }).toList();

      state = state.copyWith(tasks: updatedTasks, isLoading: false);
      debugPrint('=== TAREFA COMPLETADA: $taskId ===');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao completar tarefa: $e',
      );
      return false;
    }
  }

  // ══════════════════════════════════════
  // PACIENTE: Pular tarefa
  // ══════════════════════════════════════
  Future<bool> skipTask(String taskId) async {
    try {
      await _client
          .from('tasks')
          .update({'status': 'skipped'})
          .eq('id', taskId);

      final updatedTasks = state.tasks.map((t) {
        if (t.id == taskId) {
          return t.copyWith(status: TaskStatus.skipped);
        }
        return t;
      }).toList();

      state = state.copyWith(tasks: updatedTasks);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao pular tarefa: $e');
      return false;
    }
  }

  // ══════════════════════════════════════
  // PSICÓLOGO: Ver respostas
  // ══════════════════════════════════════
  Future<void> loadTaskResponses(String taskId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _client
          .from('task_responses')
          .select()
          .eq('task_id', taskId)
          .order('completed_at', ascending: false);

      final responses = (response as List)
          .map((json) => TaskResponseModel.fromJson(json))
          .toList();

      state = state.copyWith(responses: responses, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar respostas: $e',
      );
    }
  }

  // ══════════════════════════════════════
  // PSICÓLOGO: Deletar tarefa
  // ══════════════════════════════════════
  Future<bool> deleteTask(String taskId) async {
    try {
      await _client.from('tasks').delete().eq('id', taskId);

      final updatedTasks =
          state.tasks.where((t) => t.id != taskId).toList();

      state = state.copyWith(tasks: updatedTasks);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao deletar tarefa: $e');
      return false;
    }
  }

  // ══════════════════════════════════════
  // HELPER: Recorrentes
  // ══════════════════════════════════════
  Future<List<TaskModel>> _createRecurringTasks({
    required Map<String, dynamic> taskData,
    required String pattern,
    required DateTime startDate,
    int daysAhead = 7,
  }) async {
    final tasks = <Map<String, dynamic>>[];

    for (int i = 1; i <= daysAhead; i++) {
      final date = startDate.add(Duration(days: i));
      bool shouldCreate = false;

      switch (pattern) {
        case 'daily':
          shouldCreate = true;
          break;
        case 'weekdays':
          shouldCreate = date.weekday <= 5;
          break;
        case 'weekly':
          shouldCreate = i % 7 == 0;
          break;
      }

      if (shouldCreate) {
        tasks.add({
          ...taskData,
          'due_date': date.toIso8601String().split('T')[0],
        });
      }
    }

    if (tasks.isEmpty) return [];

    final response = await _client
        .from('tasks')
        .insert(tasks)
        .select();

    return (response as List)
        .map((json) => TaskModel.fromJson(json))
        .toList();
  }

  void clear() {
    state = const TaskState();
  }
}

// ══════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════
final taskProvider =
    NotifierProvider<TaskNotifier, TaskState>(TaskNotifier.new);