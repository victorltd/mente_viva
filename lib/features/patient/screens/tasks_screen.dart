// lib/features/patient/screens/tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/task_model.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/task_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => _loadTasks());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final patient = ref.read(patientProvider).patient;
    if (patient != null) {
      await ref.read(taskProvider.notifier).loadPatientTasks(patient.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pendentes'),
                  if (taskState.pendingTasks.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${taskState.pendingTasks.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Concluídas'),
            const Tab(text: 'Todas'),
          ],
        ),
      ),
      body: taskState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ══════════════════════════════════════
                // STREAK BANNER
                // ══════════════════════════════════════
                if (taskState.streak > 0)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(AppSizes.md),
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warning,
                          AppColors.warning.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          '${taskState.streak} dias completando tarefas!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ══════════════════════════════════════
                // TAB VIEWS
                // ══════════════════════════════════════
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _TaskList(
                        tasks: taskState.pendingTasks,
                        emptyMessage: 'Nenhuma tarefa pendente 🎉',
                        emptyIcon: Icons.check_circle_outline,
                        onTaskTap: _navigateToTask,
                      ),
                      _TaskList(
                        tasks: taskState.completedTasks,
                        emptyMessage: 'Nenhuma tarefa concluída ainda',
                        emptyIcon: Icons.assignment_outlined,
                        onTaskTap: _navigateToTask,
                      ),
                      _TaskList(
                        tasks: taskState.tasks,
                        emptyMessage: 'Seu psicólogo ainda não criou tarefas',
                        emptyIcon: Icons.assignment_outlined,
                        onTaskTap: _navigateToTask,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _navigateToTask(TaskModel task) async {
    await context.push('/app/task', extra: task);
    _loadTasks();
  }
}

// ══════════════════════════════════════
// TASK LIST WIDGET
// ══════════════════════════════════════
class _TaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final String emptyMessage;
  final IconData emptyIcon;
  final Function(TaskModel) onTaskTap;

  const _TaskList({
    required this.tasks,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                emptyIcon,
                size: 64,
                color: AppColors.textLight.withOpacity(0.5),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Agrupa tarefas por data
    final grouped = _groupTasksByDate(tasks);

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh do parent
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final entry = grouped.entries.elementAt(index);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.sm,
                ),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              // Tasks for this date
              ...entry.value.map((task) => _TaskCard(
                    task: task,
                    onTap: () => onTaskTap(task),
                  )),
              const SizedBox(height: AppSizes.sm),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<TaskModel>> _groupTasksByDate(List<TaskModel> tasks) {
    final Map<String, List<TaskModel>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    for (final task in tasks) {
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );

      String label;
      if (taskDate == today) {
        label = '📅 Hoje';
      } else if (taskDate == yesterday) {
        label = '📅 Ontem';
      } else if (taskDate == tomorrow) {
        label = '📅 Amanhã';
      } else if (taskDate.isBefore(today)) {
        label = '⚠️ Atrasadas';
      } else {
        label = '📅 ${_formatDate(taskDate)}';
      }

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(task);
    }

    // Ordena para "Atrasadas" vir primeiro, depois "Hoje", etc.
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        const order = ['⚠️ Atrasadas', '📅 Hoje', '📅 Amanhã'];
        final aIndex = order.indexOf(a);
        final bIndex = order.indexOf(b);
        if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
        if (aIndex != -1) return -1;
        if (bIndex != -1) return 1;
        return a.compareTo(b);
      });

    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  String _formatDate(DateTime date) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

// ══════════════════════════════════════
// TASK CARD WIDGET
// ══════════════════════════════════════
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    final isCompleted = task.isCompleted;
    final isSkipped = task.isSkipped;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: isOverdue
              ? AppColors.error.withOpacity(0.3)
              : Colors.grey.shade100,
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              // ══════════════════════════════════════
              // EMOJI / STATUS ICON
              // ══════════════════════════════════════
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Center(
                  child: _buildIcon(),
                ),
              ),
              const SizedBox(width: AppSizes.md),

              // ══════════════════════════════════════
              // INFO
              // ══════════════════════════════════════
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted || isSkipped
                                ? AppColors.textLight
                                : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          task.typeLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (task.isRecurring) ...[
                          const SizedBox(width: AppSizes.xs),
                          Icon(
                            Icons.repeat,
                            size: 12,
                            color: AppColors.textLight,
                          ),
                        ],
                      ],
                    ),
                    if (isOverdue && task.isPending) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Atrasada',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              // ══════════════════════════════════════
              // STATUS / ARROW
              // ══════════════════════════════════════
              _buildStatusIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (task.isCompleted) return AppColors.successLight;
    if (task.isSkipped) return AppColors.surfaceVariant;
    if (task.isOverdue) return AppColors.errorLight;
    return AppColors.primaryLight.withOpacity(0.3);
  }

  Widget _buildIcon() {
    if (task.isCompleted) {
      return const Icon(Icons.check, color: AppColors.success);
    }
    if (task.isSkipped) {
      return Icon(Icons.skip_next, color: AppColors.textLight);
    }
    return Text(task.typeEmoji, style: const TextStyle(fontSize: 24));
  }

  Widget _buildStatusIndicator() {
    if (task.isCompleted) {
      return const Text('✅', style: TextStyle(fontSize: 20));
    }
    if (task.isSkipped) {
      return const Text('⏭️', style: TextStyle(fontSize: 20));
    }
    if (task.isExpired) {
      return const Text('⏰', style: TextStyle(fontSize: 20));
    }
    return const Icon(Icons.chevron_right, color: AppColors.textLight);
  }
}