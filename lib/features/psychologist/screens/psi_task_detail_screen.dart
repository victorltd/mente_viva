// lib/features/psychologist/screens/psi_task_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/task_model.dart';
import '../../../providers/task_provider.dart';
import '../widgets/task_response_card.dart';
import '../widgets/task_response_viewer.dart';

class PsiTaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const PsiTaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<PsiTaskDetailScreen> createState() =>
      _PsiTaskDetailScreenState();
}

class _PsiTaskDetailScreenState extends ConsumerState<PsiTaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadResponses());
  }

  Future<void> _loadResponses() async {
    await ref.read(taskProvider.notifier).loadTaskResponses(widget.task.id);
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final task = widget.task;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Tarefa'),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') _confirmDelete();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadResponses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════
              // TASK INFO CARD
              // ══════════════════════════════════════
              _buildTaskInfoCard(context, task),

              const SizedBox(height: AppSizes.lg),

              // ══════════════════════════════════════
              // DESCRIÇÃO
              // ══════════════════════════════════════
              if (task.description != null &&
                  task.description!.isNotEmpty) ...[
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
              ],

              // ══════════════════════════════════════
              // CONFIG (se houver)
              // ══════════════════════════════════════
              if (task.taskConfig.isNotEmpty) ...[
                Text(
                  'Configuração',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSizes.sm),
                _buildConfigCard(context, task),
                const SizedBox(height: AppSizes.lg),
              ],

              // ══════════════════════════════════════
              // RESPOSTAS
              // ══════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Respostas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (taskState.responses.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: AppSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        '${taskState.responses.length}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),

              if (taskState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.xl),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (taskState.responses.isEmpty)
                _buildNoResponses(context, task)
              else
                ...taskState.responses.map((response) {
                  return TaskResponseCard(
                    response: response,
                    taskType: task.taskType,
                    onTap: () => _showResponseDetail(response),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // TASK INFO CARD
  // ══════════════════════════════════════
  Widget _buildTaskInfoCard(BuildContext context, TaskModel task) {
    Color statusColor;
    String statusLabel;

    switch (task.status) {
      case TaskStatus.completed:
        statusColor = AppColors.success;
        statusLabel = 'Concluída';
        break;
      case TaskStatus.skipped:
        statusColor = AppColors.textSecondary;
        statusLabel = 'Pulada';
        break;
      case TaskStatus.expired:
        statusColor = AppColors.error;
        statusLabel = 'Expirada';
        break;
      case TaskStatus.pending:
      default:
        statusColor = task.isOverdue ? AppColors.warning : AppColors.primary;
        statusLabel = task.isOverdue ? 'Atrasada' : 'Pendente';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Center(
                  child: Text(
                    task.typeEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.typeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            task.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(task.dueDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (task.isRecurring) ...[
                const SizedBox(width: AppSizes.md),
                Icon(
                  Icons.repeat,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _getRecurrenceLabel(task.recurrencePattern),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // CONFIG CARD
  // ══════════════════════════════════════
  Widget _buildConfigCard(BuildContext context, TaskModel task) {
    final config = task.taskConfig;

    List<Widget> items = [];

    switch (task.taskType) {
      case TaskType.breathing:
        items = [
          _buildConfigItem(
              'Inspirar', '${config['inhale_seconds'] ?? 4} segundos'),
          _buildConfigItem(
              'Segurar', '${config['hold_seconds'] ?? 4} segundos'),
          _buildConfigItem(
              'Expirar', '${config['exhale_seconds'] ?? 4} segundos'),
          _buildConfigItem('Ciclos', '${config['cycles'] ?? 5}'),
        ];
        break;

      case TaskType.mindfulness:
        items = [
          _buildConfigItem(
              'Duração', '${config['duration_minutes'] ?? 10} minutos'),
          if (config['guidance'] != null)
            _buildConfigItem('Orientação', config['guidance']),
        ];
        break;

      case TaskType.journaling:
        if (config['prompt'] != null) {
          items.add(_buildConfigItem('Prompt', config['prompt']));
        }
        if (config['min_words'] != null) {
          items.add(_buildConfigItem(
              'Mínimo', '${config['min_words']} palavras'));
        }
        break;

      default:
        // Mostra config genérica
        config.forEach((key, value) {
          items.add(_buildConfigItem(key, value.toString()));
        });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // NO RESPONSES
  // ══════════════════════════════════════
  Widget _buildNoResponses(BuildContext context, TaskModel task) {
    String message;
    IconData icon;

    if (task.isPending) {
      message = 'O paciente ainda não completou esta tarefa';
      icon = Icons.hourglass_empty;
    } else if (task.isSkipped) {
      message = 'O paciente pulou esta tarefa';
      icon = Icons.skip_next;
    } else {
      message = 'Nenhuma resposta registrada';
      icon = Icons.inbox_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // SHOW RESPONSE DETAIL
  // ══════════════════════════════════════
  void _showResponseDetail(response) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppSizes.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Text(
                      'Resposta Completa',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: TaskResponseViewer(
                  response: response,
                  taskType: widget.task.taskType,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // CONFIRM DELETE
  // ══════════════════════════════════════
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: const Text(
          'Esta ação não pode ser desfeita. '
          'As respostas do paciente também serão excluídas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(taskProvider.notifier)
                  .deleteTask(widget.task.id);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.error),
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
}