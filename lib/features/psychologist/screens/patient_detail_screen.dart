// lib/features/psychologist/screens/patient_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../config/constants/app_constants.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../models/checkin_model.dart';
import '../../../models/task_model.dart';
import '../../../providers/alert_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/feature_provider.dart';
import '../widgets/alert_card.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CheckinModel> _checkins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadCheckins();
    final features = ref.read(featureProvider);
    if (features.tasksEnabled) {
      await ref
          .read(taskProvider.notifier)
          .loadTasksForPatient(widget.patient['id'] as String);
    }
  }

  Future<void> _loadCheckins() async {
    try {
      final response = await SupabaseService.client
          .from('checkins')
          .select()
          .eq('patient_id', widget.patient['id'])
          .order('created_at', ascending: false)
          .limit(90);

      setState(() {
        _checkins = (response as List)
            .map((json) => CheckinModel.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.patient['full_name'] ?? 'Paciente';
    final status = widget.patient['status'] ?? 'pending';
    final patientId = widget.patient['id'] as String;
    final alertState = ref.watch(alertProvider);
    final patientAlerts = alertState.alertsForPatient(patientId);
    final featureState = ref.watch(featureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
        actions: [
          if (status == 'pending')
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showInviteCode(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(icon: Icon(Icons.mood), text: 'Humor'),
            Tab(
              icon: Icon(
                Icons.assignment_outlined,
                color: featureState.tasksEnabled
                    ? null
                    : AppColors.textLight.withOpacity(0.5),
              ),
              text: 'Tarefas',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: patientAlerts.isNotEmpty,
                label: Text(
                  '${patientAlerts.length}',
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
              text: 'Alertas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMoodTab(),
          _buildTasksTab(featureState, patientId),
          _buildAlertsTab(patientAlerts),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // TAB TAREFAS (feature-aware)
  // ══════════════════════════════════════
  Widget _buildTasksTab(FeatureState featureState, String patientId) {
    if (!featureState.tasksEnabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: AppColors.textLight.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Tarefas desativadas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Ative esta funcionalidade nas configurações para criar tarefas terapêuticas para seus pacientes.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              OutlinedButton.icon(
                onPressed: () => context.push('/psi/settings'),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Ir para Configurações'),
              ),
            ],
          ),
        ),
      );
    }

    final taskState = ref.watch(taskProvider);

    if (taskState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: ElevatedButton.icon(
            onPressed: () async {
              await context.push('/psi/create-task', extra: widget.patient);
              _loadData();
            },
            icon: const Icon(Icons.add),
            label: const Text('Nova Tarefa'),
          ),
        ),
        if (taskState.tasks.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: AppColors.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Nenhuma tarefa criada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Crie tarefas terapêuticas para este paciente.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
        else
          // Expanded(
          //   child: RefreshIndicator(
          //     onRefresh: _loadData,
          //     child: ListView.builder(
          //       padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          //       itemCount: taskState.tasks.length,
          //       itemBuilder: (context, index) {
          //         final task = taskState.tasks[index];
          //         return _PsiTaskCard(
          //           task: task,
          //           onDelete: () => _deleteTask(task.id),
          //         );
          //       },
          //     ),
          //   ),
          // ),
          Expanded(
  child: RefreshIndicator(
    onRefresh: _loadData,
    child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      itemCount: taskState.tasks.length,
      itemBuilder: (context, index) {
        final task = taskState.tasks[index];
        return _PsiTaskCard(
          task: task,
          onTap: () async {
            await context.push('/psi/task', extra: task);
            _loadData(); // Recarregar após voltar
          },
          onDelete: () => _deleteTask(task.id),
        );
      },
    ),
  ),
)
      ],
    );
  }

  Future<void> _deleteTask(String taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar tarefa?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(taskProvider.notifier).deleteTask(taskId);
    }
  }

  // ══════════════════════════════════════
  // TAB ALERTAS
  // ══════════════════════════════════════
  Widget _buildAlertsTab(List<AlertItem> alerts) {
    if (alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Nenhum alerta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Este paciente está com indicadores normais.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        return AlertCard(alert: alerts[index]);
      },
    );
  }

  // ══════════════════════════════════════
  // TAB HUMOR
  // ══════════════════════════════════════
  Widget _buildMoodTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_checkins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mood_bad_outlined,
              size: 64,
              color: AppColors.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Nenhum check-in registrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'O paciente ainda não fez nenhum check-in.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCheckins,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Humor - Últimos 7 dias',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            _buildMoodChart(),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Emoções mais frequentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            _buildEmotionDistribution(),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Histórico de Check-ins',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            _buildCheckinHistory(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // CARDS DE RESUMO
  // ══════════════════════════════════════
  Widget _buildSummaryCards() {
    final avgMood = _checkins.isEmpty
        ? 0.0
        : _checkins.fold<int>(0, (sum, c) => sum + c.moodScore) /
            _checkins.length;

    final avgSleep = _checkins.where((c) => c.sleepQuality != null).isEmpty
        ? 0.0
        : _checkins
                .where((c) => c.sleepQuality != null)
                .fold<int>(0, (sum, c) => sum + c.sleepQuality!) /
            _checkins.where((c) => c.sleepQuality != null).length;

    final avgEnergy = _checkins.where((c) => c.energyLevel != null).isEmpty
        ? 0.0
        : _checkins
                .where((c) => c.energyLevel != null)
                .fold<int>(0, (sum, c) => sum + c.energyLevel!) /
            _checkins.where((c) => c.energyLevel != null).length;

    final hasToday = _checkins.isNotEmpty &&
        _checkins.first.createdAt.day == DateTime.now().day &&
        _checkins.first.createdAt.month == DateTime.now().month;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: hasToday ? Icons.check_circle : Icons.cancel_outlined,
            label: 'Hoje',
            value: hasToday
                ? AppConstants.moodEmojis[_checkins.first.moodScore]!
                : '—',
            color: hasToday ? AppColors.success : AppColors.error,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _SummaryCard(
            icon: Icons.mood,
            label: 'Humor médio',
            value: avgMood.toStringAsFixed(1),
            color: AppColors.moodColor(avgMood.round().clamp(1, 5)),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _SummaryCard(
            icon: Icons.bedtime,
            label: 'Sono médio',
            value: '${avgSleep.toStringAsFixed(1)}⭐',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _SummaryCard(
            icon: Icons.bolt,
            label: 'Energia',
            value: avgEnergy.toStringAsFixed(1),
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // GRÁFICO DE HUMOR
  // ══════════════════════════════════════
  Widget _buildMoodChart() {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day - (6 - i));
    });

    final Map<String, CheckinModel> dailyMap = {};
    for (final checkin in _checkins) {
      final key =
          '${checkin.createdAt.year}-${checkin.createdAt.month}-${checkin.createdAt.day}';
      if (!dailyMap.containsKey(key)) {
        dailyMap[key] = checkin;
      }
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final key = '${day.year}-${day.month}-${day.day}';

      if (dailyMap.containsKey(key)) {
        spots.add(FlSpot(
          i.toDouble(),
          dailyMap[key]!.moodScore.toDouble(),
        ));
      }
    }

    if (spots.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const Center(
          child: Text('Sem dados suficientes para o gráfico'),
        ),
      );
    }

    final weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.sm,
        AppSizes.md,
        AppSizes.md,
        AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade100,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final intVal = value.toInt();
                  if (intVal < 1 || intVal > 5 || value != intVal.toDouble()) {
                    return const SizedBox();
                  }
                  return Text(
                    AppConstants.moodEmojis[intVal] ?? '',
                    style: const TextStyle(fontSize: 14),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (value != idx.toDouble()) return const SizedBox();
                  if (idx < 0 || idx >= days.length) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      weekDays[days[idx].weekday % 7],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0.5,
          maxY: 5.5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.moodColor(spot.y.round()),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // DISTRIBUIÇÃO DE EMOÇÕES
  // ══════════════════════════════════════
  Widget _buildEmotionDistribution() {
    final emotionCount = <String, int>{};
    for (final checkin in _checkins) {
      emotionCount[checkin.primaryEmotion] =
          (emotionCount[checkin.primaryEmotion] ?? 0) + 1;
    }

    final sorted = emotionCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = _checkins.length;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: sorted.take(5).map((entry) {
          final percentage = (entry.value / total * 100).round();
          final color =
              AppColors.emotions[entry.key] ?? AppColors.textLight;

          final emotionData = AppConstants.emotions.firstWhere(
            (e) => e['key'] == entry.key,
            orElse: () => {'emoji': '❓', 'label': entry.key},
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Row(
              children: [
                Text(
                  emotionData['emoji']!,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            emotionData['label']!,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '$percentage%',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════
  // HISTÓRICO
  // ══════════════════════════════════════
  Widget _buildCheckinHistory() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _checkins.length.clamp(0, 20),
      itemBuilder: (context, index) {
        final checkin = _checkins[index];
        return _CheckinHistoryCard(checkin: checkin);
      },
    );
  }

  // ══════════════════════════════════════
  // INVITE CODE
  // ══════════════════════════════════════
  void _showInviteCode() {
    final code = widget.patient['invite_code'] ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código de Convite'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Envie este código para o paciente:'),
            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: SelectableText(
                code,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PsiTaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;  // NOVO
  final VoidCallback onDelete;

  const _PsiTaskCard({
    required this.task,
    this.onTap,  // NOVO
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: InkWell(  // MUDOU: era Padding, agora InkWell
        onTap: onTap,  // NOVO
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              // Emoji tipo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? AppColors.successLight
                      : task.isOverdue  // NOVO: cor diferente se atrasada
                          ? AppColors.errorLight
                          : AppColors.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Center(
                  child: task.isCompleted
                      ? const Icon(Icons.check, color: AppColors.success)
                      : Text(
                          task.typeEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                ),
              ),
              const SizedBox(width: AppSizes.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
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
                        const SizedBox(width: AppSizes.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(task).withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            _statusLabel(task),  // MUDOU: usa helper
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(task),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Para: ${_formatDate(task.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: task.isOverdue && task.isPending
                                ? AppColors.error
                                : null,
                          ),
                    ),
                  ],
                ),
              ),

              // NOVO: Seta indicando clicável (ou delete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete button
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Excluir tarefa',
                  ),
                  // Arrow (indica que é clicável)
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MUDOU: agora considera isOverdue
  Color _statusColor(TaskModel task) {
    if (task.isOverdue && task.isPending) {
      return AppColors.error;
    }
    switch (task.status) {
      case TaskStatus.pending:
        return AppColors.warning;
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.skipped:
        return AppColors.textLight;
      case TaskStatus.expired:
        return AppColors.error;
    }
  }

  // NOVO: label considerando overdue
  String _statusLabel(TaskModel task) {
    if (task.isOverdue && task.isPending) {
      return 'Atrasada';
    }
    return task.status.label;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hoje';
    if (d == today.add(const Duration(days: 1))) return 'Amanhã';
    if (d == today.subtract(const Duration(days: 1))) return 'Ontem';
    return '${date.day}/${date.month}';
  }
}

class _CheckinHistoryCard extends StatelessWidget {
  final CheckinModel checkin;

  const _CheckinHistoryCard({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final emotionData = AppConstants.emotions.firstWhere(
      (e) => e['key'] == checkin.primaryEmotion,
      orElse: () => {'emoji': '❓', 'label': checkin.primaryEmotion},
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.moodBackgroundColor(checkin.moodScore),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Center(
                child: Text(
                  AppConstants.moodEmojis[checkin.moodScore]!,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppConstants.moodLabels[checkin.moodScore]!,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        '${emotionData['emoji']} ${emotionData['label']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (checkin.notes != null &&
                      checkin.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      checkin.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (checkin.energyLevel != null)
                        Text(
                          '🔋${checkin.energyLevel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (checkin.sleepQuality != null) ...[
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          '😴${checkin.sleepQuality}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              _formatDate(checkin.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkinDay = DateTime(date.year, date.month, date.day);

    if (checkinDay == today) return 'Hoje';
    if (checkinDay == today.subtract(const Duration(days: 1))) {
      return 'Ontem';
    }
    return '${date.day}/${date.month}';
  }
}