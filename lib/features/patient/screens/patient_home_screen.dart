// lib/features/patient/screens/patient_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../config/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/emergency_banner.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/checkin_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/feature_provider.dart';
import '../../../providers/achievement_provider.dart';
import '../../../models/achievement_model.dart';
import '../widgets/achievement_popup.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    await ref.read(patientProvider.notifier).loadMyPatientData();

    final patient = ref.read(patientProvider).patient;
    if (patient != null) {
      await ref.read(checkinProvider.notifier).loadCheckins(patient.id);

      // Carregar features do psicólogo deste paciente
      await ref
          .read(featureProvider.notifier)
          .loadFeaturesForPatient(patient.psychologistId);

      // Se tarefas estão ativas, carregar tarefas
      final features = ref.read(featureProvider);
      if (features.tasksEnabled) {
        await ref.read(taskProvider.notifier).loadPatientTasks(patient.id);
      }

      // ══════════════════════════════════════
      // CARREGAR E VERIFICAR CONQUISTAS
      // ══════════════════════════════════════
      await ref.read(achievementProvider.notifier).loadAchievements(patient.id);

      // Verificar novas conquistas
      final checkins = ref.read(checkinProvider).checkins;
      final tasks = ref.read(taskProvider).tasks;

      await ref.read(achievementProvider.notifier).checkAndUnlockAchievements(
            patientId: patient.id,
            checkins: checkins,
            tasks: tasks,
          );

      // Mostrar popup se houver novas conquistas
      _showNewAchievements();
    }
  }

  void _showNewAchievements() {
    final newlyUnlocked = ref.read(achievementProvider).newlyUnlocked;

    if (newlyUnlocked.isEmpty) return;

    // Mostrar primeiro achievement
    _showAchievementPopup(newlyUnlocked, 0);
  }

  void _showAchievementPopup(List<AchievementType> achievements, int index) {
    if (index >= achievements.length) {
      // Limpar lista de novos
      ref.read(achievementProvider.notifier).clearNewlyUnlocked();
      return;
    }

    AchievementPopup.show(context, achievements[index]).then((_) {
      // Mostrar próximo após fechar
      Future.delayed(const Duration(milliseconds: 300), () {
        _showAchievementPopup(achievements, index + 1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final checkinState = ref.watch(checkinProvider);
    final taskState = ref.watch(taskProvider);
    final featureState = ref.watch(featureProvider);
    final firstName = authState.profile?.fullName?.split(' ').first ?? '';

    // Verificar se precisa mostrar banner de emergência
    final showEmergencyBanner = checkinState.lastCheckin?.moodScore == 1;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            const Text('MenteViva'),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, size: 18, color: AppColors.primary),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Sair', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ══════════════════════════════════════
          // BANNER DE EMERGÊNCIA (se humor crítico)
          // ══════════════════════════════════════
          if (showEmergencyBanner)
            const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: EmergencyBanner(isCompact: true),
            ),

          // ══════════════════════════════════════
          // CONTEÚDO PRINCIPAL
          // ══════════════════════════════════════
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ══════════════════════════════════════
                    // SAUDAÇÃO
                    // ══════════════════════════════════════
                    Text(
                      'Olá, $firstName! 💜',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Como você está se sentindo hoje?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ══════════════════════════════════════
                    // CARD CHECK-IN
                    // ══════════════════════════════════════
                    GestureDetector(
                      onTap: () async {
                        await context.push('/app/checkin');
                        _loadData();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.lg),
                        decoration: BoxDecoration(
                          gradient: checkinState.hasCheckinToday
                              ? LinearGradient(
                                  colors: [
                                    AppColors.success,
                                    AppColors.success.withOpacity(0.8),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark,
                                  ],
                                ),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        child: checkinState.hasCheckinToday
                            ? _buildCheckinDone(checkinState)
                            : _buildCheckinPending(),
                      ),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ══════════════════════════════════════
                    // STREAK
                    // ══════════════════════════════════════
                    if (checkinState.streak > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              '${checkinState.streak} dias seguidos!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.warning),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSizes.lg),

                    // ══════════════════════════════════════
                    // CONQUISTAS RECENTES
                    // ══════════════════════════════════════
                    _buildAchievementsPreview(),

                    const SizedBox(height: AppSizes.lg),

                    // ══════════════════════════════════════
                    // TAREFAS DE HOJE (só se feature ativa)
                    // ══════════════════════════════════════
                    if (featureState.tasksEnabled) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tarefas de Hoje',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (taskState.todayTasks.isNotEmpty)
                            Text(
                              '${taskState.todayCompletedTasks.length}/${taskState.todayTasks.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.primary),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),

                      // Progresso
                      if (taskState.todayTasks.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: taskState.todayProgress,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                      ],

                      if (taskState.todayTasks.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_outlined,
                                  size: 48,
                                  color: AppColors.textLight.withOpacity(0.5)),
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                'Nenhuma tarefa para hoje',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      else
                        ...taskState.todayTasks.map((task) {
                          return _TaskCard(
                            task: task,
                            onTap: () async {
                              await context.push('/app/task', extra: task);
                              _loadData();
                            },
                          );
                        }),

                      const SizedBox(height: AppSizes.lg),
                    ],

                    // ══════════════════════════════════════
                    // HUMOR DA SEMANA
                    // ══════════════════════════════════════
                    if (checkinState.weekCheckins.isNotEmpty) ...[
                      Text(
                        'Sua Semana',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: checkinState.weekCheckins.take(7).map(
                            (checkin) {
                              return Column(
                                children: [
                                  Text(
                                    AppConstants.moodEmojis[checkin.moodScore]!,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _weekDay(checkin.createdAt),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSizes.lg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ══════════════════════════════════════
      // BOTTOM NAV (condicional)
      // ══════════════════════════════════════
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          final items = _getNavItems(featureState.tasksEnabled);
          final tappedItem = items[index];

          switch (tappedItem) {
            case 'home':
              setState(() => _currentNavIndex = 0);
              break;
            case 'checkin':
              context.push('/app/checkin');
              break;
            case 'tasks':
              context.push('/app/tasks');
              break;
            case 'achievements':
              context.push('/app/achievements');
              break;
            case 'evolution':
              context.push('/app/evolution');
              break;
          }
        },
        items: _buildNavBarItems(featureState.tasksEnabled),
      ),
    );
  }

  // ══════════════════════════════════════
  // NAV BAR DINÂMICO
  // ══════════════════════════════════════
  List<String> _getNavItems(bool tasksEnabled) {
    if (tasksEnabled) {
      return ['home', 'checkin', 'tasks', 'achievements', 'evolution'];
    }
    return ['home', 'checkin', 'achievements', 'evolution'];
  }

  List<BottomNavigationBarItem> _buildNavBarItems(bool tasksEnabled) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        activeIcon: Icon(Icons.add_circle),
        label: 'Check-in',
      ),
    ];

    if (tasksEnabled) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        activeIcon: Icon(Icons.assignment),
        label: 'Tarefas',
      ));
    }

    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.emoji_events_outlined),
      activeIcon: Icon(Icons.emoji_events),
      label: 'Conquistas',
    ));

    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.timeline_outlined),
      activeIcon: Icon(Icons.timeline),
      label: 'Evolução',
    ));

    return items;
  }

  // ══════════════════════════════════════
  // ACHIEVEMENTS PREVIEW
  // ══════════════════════════════════════
  Widget _buildAchievementsPreview() {
    final achievementState = ref.watch(achievementProvider);
    final recent = achievementState.unlockedAchievements.take(5).toList();

    return GestureDetector(
      onTap: () => context.push('/app/achievements'),
      child: Container(
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
            Row(
              children: [
                Text(
                  '🏆 Conquistas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nível ${achievementState.level}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• ${achievementState.totalXP} XP',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            if (recent.isEmpty)
              Text(
                'Complete check-ins e tarefas para desbloquear conquistas!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else
              Row(
                children: [
                  ...recent.map((achievement) {
                    return Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: AppSizes.xs),
                      decoration: BoxDecoration(
                        color: achievement.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          achievement.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Ver todas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // CHECK-IN JÁ FEITO HOJE
  // ══════════════════════════════════════
  Widget _buildCheckinDone(CheckinState checkinState) {
    final last = checkinState.lastCheckin!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: AppSizes.sm),
            Text(
              'Check-in de hoje ✅',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Text(
              AppConstants.moodEmojis[last.moodScore]!,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: AppSizes.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.moodLabels[last.moodScore]!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  last.primaryEmotion,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        const Text(
          'Toque para fazer outro check-in',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // CHECK-IN PENDENTE
  // ══════════════════════════════════════
  Widget _buildCheckinPending() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Check-in Emocional',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        const Text(
          'Registre como está se sentindo agora',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final score = index + 1;
            return Text(
              AppConstants.moodEmojis[score]!,
              style: const TextStyle(fontSize: 28),
            );
          }),
        ),
        const SizedBox(height: AppSizes.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: const Text(
            'FAZER CHECK-IN →',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _weekDay(DateTime date) {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return days[date.weekday % 7];
  }
}

// ══════════════════════════════════════
// TASK CARD WIDGET
// ══════════════════════════════════════
class _TaskCard extends StatelessWidget {
  final dynamic task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: InkWell(
        onTap: task.isPending ? onTap : null,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              // Emoji do tipo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? AppColors.successLight
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
                            color: task.isCompleted ? AppColors.textLight : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.typeLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Status
              if (task.isCompleted)
                const Text('✅', style: TextStyle(fontSize: 18))
              else if (task.isSkipped)
                const Text('⏭️', style: TextStyle(fontSize: 18))
              else
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textLight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}