// lib/features/patient/screens/task_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/task_model.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/checkin_provider.dart';
import '../../../providers/achievement_provider.dart';
import '../widgets/breathing_exercise.dart';
import '../widgets/thought_record_form.dart';
import '../widgets/journaling_form.dart';
import '../widgets/mindfulness_timer.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isCompleting = false;
  bool _showInteractiveWidget = false;

  // ══════════════════════════════════════
  // FORM CONTROLLERS (para tipos sem widget específico)
  // ══════════════════════════════════════
  final _notesController = TextEditingController();
  int _rating = 3;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    // Se está mostrando widget interativo, exibir tela cheia
    if (_showInteractiveWidget && task.isPending) {
      return Scaffold(
        appBar: AppBar(
          title: Text(task.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmExit(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: _buildInteractiveWidget(task),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefa'),
        actions: [
          if (task.isPending)
            TextButton(
              onPressed: _skipTask,
              child: const Text(
                'Pular',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════
            // HEADER CARD
            // ══════════════════════════════════════
            _buildHeaderCard(task),

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // DESCRIÇÃO
            // ══════════════════════════════════════
            if (task.description != null && task.description!.isNotEmpty) ...[
              Text(
                'Descrição',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
            ],

            // ══════════════════════════════════════
            // INSTRUÇÕES / PREVIEW
            // ══════════════════════════════════════
            if (task.isPending) ...[
              _buildTaskPreview(task),
              const SizedBox(height: AppSizes.lg),
            ],

            // ══════════════════════════════════════
            // STATUS CONCLUÍDO
            // ══════════════════════════════════════
            if (task.isCompleted) _buildCompletedInfo(),

            // ══════════════════════════════════════
            // STATUS PULADA
            // ══════════════════════════════════════
            if (task.isSkipped) _buildSkippedInfo(),
          ],
        ),
      ),

      // ══════════════════════════════════════
      // BOTÃO DE AÇÃO
      // ══════════════════════════════════════
      bottomNavigationBar: task.isPending
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: ElevatedButton.icon(
                  onPressed: _startTask,
                  icon: Icon(_getStartIcon(task.taskType)),
                  label: Text(_getStartLabel(task.taskType)),
                ),
              ),
            )
          : null,
    );
  }

  // ══════════════════════════════════════
  // HEADER CARD
  // ══════════════════════════════════════
  Widget _buildHeaderCard(TaskModel task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: task.isCompleted
              ? [AppColors.success, AppColors.success.withOpacity(0.8)]
              : task.isOverdue
                  ? [AppColors.error, AppColors.error.withOpacity(0.8)]
                  : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji + Status
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Center(
                  child: Text(
                    task.typeEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  task.status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Tipo
          Text(
            task.typeLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSizes.xs),

          // Título
          Text(
            task.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Data
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                _formatDate(task.dueDate),
                style: const TextStyle(color: Colors.white70),
              ),
              if (task.isRecurring) ...[
                const SizedBox(width: AppSizes.md),
                const Icon(
                  Icons.repeat,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  _getRecurrenceLabel(task.recurrencePattern),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // TASK PREVIEW (mostra o que esperar)
  // ══════════════════════════════════════
  Widget _buildTaskPreview(TaskModel task) {
    String title;
    String description;
    IconData icon;
    Color color;

    switch (task.taskType) {
      case TaskType.breathing:
        final config = task.taskConfig;
        final inhale = config['inhale_seconds'] ?? 4;
        final hold = config['hold_seconds'] ?? 4;
        final exhale = config['exhale_seconds'] ?? 4;
        final cycles = config['cycles'] ?? 5;
        title = 'Exercício de Respiração';
        description = 'Padrão $inhale-$hold-$exhale · $cycles ciclos\n'
            'Duração estimada: ~${(cycles * (inhale + hold + exhale) / 60).ceil()} minutos';
        icon = Icons.air;
        color = AppColors.info;
        break;

      case TaskType.thoughtRecord:
        title = 'Registro de Pensamento';
        description = 'Você será guiado por 6 passos:\n'
            '1. Situação → 2. Pensamento → 3. Emoção\n'
            '4. Evidências a favor → 5. Contra → 6. Alternativa';
        icon = Icons.psychology;
        color = AppColors.warning;
        break;

      case TaskType.journaling:
        final prompt = task.taskConfig['prompt'] as String?;
        final minWords = task.taskConfig['min_words'] as int?;
        title = 'Diário / Journaling';
        description = prompt != null
            ? 'Prompt: "$prompt"'
            : 'Escrita livre sobre seus pensamentos';
        if (minWords != null) {
          description += '\nMínimo sugerido: $minWords palavras';
        }
        icon = Icons.edit_note;
        color = AppColors.secondary;
        break;

      case TaskType.mindfulness:
        final duration = task.taskConfig['duration_minutes'] ?? 10;
        title = 'Prática de Mindfulness';
        description = 'Meditação guiada de $duration minutos\n'
            'Encontre um lugar tranquilo e confortável';
        icon = Icons.self_improvement;
        color = AppColors.secondary;
        break;

      case TaskType.behavioral:
        title = 'Atividade Comportamental';
        description = 'Complete a atividade proposta e registre sua experiência';
        icon = Icons.directions_run;
        color = AppColors.primary;
        break;

      case TaskType.custom:
      default:
        title = 'Tarefa Personalizada';
        description = 'Siga as instruções na descrição e registre a conclusão';
        icon = Icons.lightbulb_outline;
        color = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSizes.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // INTERACTIVE WIDGETS
  // ══════════════════════════════════════
  Widget _buildInteractiveWidget(TaskModel task) {
    switch (task.taskType) {
      case TaskType.breathing:
        return BreathingExercise(
          inhaleSeconds: task.taskConfig['inhale_seconds'] ?? 4,
          holdSeconds: task.taskConfig['hold_seconds'] ?? 4,
          exhaleSeconds: task.taskConfig['exhale_seconds'] ?? 4,
          totalCycles: task.taskConfig['cycles'] ?? 5,
          onComplete: (result) => _completeWithResponse(result),
        );

      case TaskType.thoughtRecord:
        return ThoughtRecordForm(
          onComplete: (result) => _completeWithResponse(result),
        );

      case TaskType.journaling:
        return JournalingForm(
          prompt: task.taskConfig['prompt'] as String?,
          minWords: task.taskConfig['min_words'] as int?,
          onComplete: (result) => _completeWithResponse(result),
        );

      case TaskType.mindfulness:
        return MindfulnessTimer(
          durationMinutes: task.taskConfig['duration_minutes'] ?? 10,
          guidance: task.taskConfig['guidance'] as String?,
          onComplete: (result) => _completeWithResponse(result),
        );

      case TaskType.behavioral:
      case TaskType.custom:
      default:
        return _buildGenericCompletionForm();
    }
  }

  // ══════════════════════════════════════
  // GENERIC FORM (behavioral, custom)
  // ══════════════════════════════════════
  Widget _buildGenericCompletionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registrar Conclusão',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSizes.md),

        // Rating
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Como foi a experiência?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  final isSelected = _rating == value;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = value),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getRatingEmoji(value),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRatingLabel(value),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textLight,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.md),

        // Notes
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Observações (opcional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.sm),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Como você se sentiu? O que percebeu?',
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCompleting ? null : _submitGenericForm,
            child: _isCompleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Concluir Tarefa'),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // STATUS WIDGETS
  // ══════════════════════════════════════
  Widget _buildCompletedInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 48,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Tarefa Concluída! 🎉',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.success,
                ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Parabéns por completar esta atividade!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkippedInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.skip_next,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Tarefa Pulada',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Tudo bem! Você pode tentar na próxima vez.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════
  void _startTask() {
    setState(() {
      _showInteractiveWidget = true;
      _startTime = DateTime.now();
    });
  }

  Future<void> _completeWithResponse(Map<String, dynamic> responseData) async {
    setState(() => _isCompleting = true);

    final patient = ref.read(patientProvider).patient;
    if (patient == null) {
      setState(() => _isCompleting = false);
      return;
    }

    // Adiciona task_type ao response
    responseData['task_type'] = widget.task.taskType.value;

    final success = await ref.read(taskProvider.notifier).completeTask(
          taskId: widget.task.id,
          patientId: patient.id,
          responseData: responseData,
        );

    setState(() => _isCompleting = false);

    if (success && mounted) {
      // Verificar conquistas
      final checkins = ref.read(checkinProvider).checkins;
      final tasks = ref.read(taskProvider).tasks;

      final patient = ref.read(patientProvider).patient;
      if (patient != null) {
        await ref.read(achievementProvider.notifier).checkAndUnlockAchievements(
          patientId: patient.id,
          checkins: checkins,
          tasks: tasks,
        );
      }

      _showSuccessDialog();
    }
  }

  Future<void> _submitGenericForm() async {
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : null;

    final responseData = {
      'rating': _rating,
      'notes': _notesController.text.trim(),
      'duration_seconds': duration,
    };

    await _completeWithResponse(responseData);
  }

  Future<void> _skipTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pular tarefa?'),
        content: const Text(
          'Tem certeza que deseja pular esta tarefa? '
          'Você poderá fazê-la em outro momento se for recorrente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pular'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(taskProvider.notifier).skipTask(widget.task.id);
      if (mounted) {
        context.pop();
      }
    }
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da tarefa?'),
        content: const Text(
          'Seu progresso não será salvo. Deseja realmente sair?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _showInteractiveWidget = false);
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSizes.md),
            Text(
              'Tarefa Concluída!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Parabéns por completar "${widget.task.title}"!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) return 'Hoje';
    if (taskDate == today.subtract(const Duration(days: 1))) return 'Ontem';
    if (taskDate == today.add(const Duration(days: 1))) return 'Amanhã';

    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${date.day} de ${months[date.month - 1]}';
  }

  String _getRecurrenceLabel(String? pattern) {
    switch (pattern) {
      case 'daily':
        return 'Diário';
      case 'weekdays':
        return 'Dias úteis';
      case 'weekly':
        return 'Semanal';
      default:
        return 'Recorrente';
    }
  }

  IconData _getStartIcon(TaskType type) {
    switch (type) {
      case TaskType.breathing:
        return Icons.air;
      case TaskType.thoughtRecord:
        return Icons.psychology;
      case TaskType.journaling:
        return Icons.edit_note;
      case TaskType.mindfulness:
        return Icons.self_improvement;
      case TaskType.behavioral:
        return Icons.directions_run;
      case TaskType.custom:
      default:
        return Icons.play_arrow;
    }
  }

  String _getStartLabel(TaskType type) {
    switch (type) {
      case TaskType.breathing:
        return 'Iniciar Respiração';
      case TaskType.thoughtRecord:
        return 'Iniciar Registro';
      case TaskType.journaling:
        return 'Abrir Diário';
      case TaskType.mindfulness:
        return 'Iniciar Meditação';
      case TaskType.behavioral:
        return 'Registrar Atividade';
      case TaskType.custom:
      default:
        return 'Iniciar Tarefa';
    }
  }

  String _getRatingEmoji(int value) {
    switch (value) {
      case 1:
        return '😣';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😊';
      default:
        return '😐';
    }
  }

  String _getRatingLabel(int value) {
    switch (value) {
      case 1:
        return 'Difícil';
      case 2:
        return 'Regular';
      case 3:
        return 'Ok';
      case 4:
        return 'Bom';
      case 5:
        return 'Ótimo';
      default:
        return '';
    }
  }
}