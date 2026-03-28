// lib/features/patient/screens/achievements_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/achievement_model.dart';
import '../../../providers/achievement_provider.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/checkin_provider.dart';
import '../widgets/streak_calendar.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    final patient = ref.read(patientProvider).patient;
    if (patient != null) {
      await ref.read(achievementProvider.notifier).loadAchievements(patient.id);
      // Marcar todos como vistos
      await ref.read(achievementProvider.notifier).markAllAsSeen(patient.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievementState = ref.watch(achievementProvider);
    final checkinState = ref.watch(checkinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conquistas'),
      ),
      body: achievementState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ══════════════════════════════════════
                    // LEVEL CARD
                    // ══════════════════════════════════════
                    _buildLevelCard(context, achievementState),

                    const SizedBox(height: AppSizes.lg),

                    // ══════════════════════════════════════
                    // CALENDÁRIO DE ATIVIDADES
                    // ══════════════════════════════════════
                    Text(
                      'Calendário de Atividades',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: StreakCalendar(
                        checkins: checkinState.checkins,
                        weeksToShow: 12,
                      ),
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ══════════════════════════════════════
                    // ESTATÍSTICAS
                    // ══════════════════════════════════════
                    _buildStatsRow(context, achievementState),

                    const SizedBox(height: AppSizes.lg),

                    // ══════════════════════════════════════
                    // CONQUISTAS POR CATEGORIA
                    // ══════════════════════════════════════
                    ...AchievementCategory.values.map((category) {
                      return _buildCategorySection(
                        context,
                        category,
                        achievementState,
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  // ══════════════════════════════════════
  // LEVEL CARD
  // ══════════════════════════════════════
  Widget _buildLevelCard(BuildContext context, AchievementState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'NÍVEL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),

              // XP info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.totalXP} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Faltam ${state.xpForNextLevel} XP para o nível ${state.level + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: state.levelProgress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════
  Widget _buildStatsRow(BuildContext context, AchievementState state) {
    final unlocked = state.unlockedAchievements.length;
    final total = AchievementType.values.length;
    final percentage = (unlocked / total * 100).round();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            value: '$unlocked/$total',
            label: 'Conquistas',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.percent,
            value: '$percentage%',
            label: 'Completo',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            value: '${state.totalXP}',
            label: 'XP Total',
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // CATEGORY SECTION
  // ══════════════════════════════════════
  Widget _buildCategorySection(
    BuildContext context,
    AchievementCategory category,
    AchievementState state,
  ) {
    final categoryAchievements =
        AchievementType.values.where((t) => t.category == category).toList();

    final unlocked = state.achievements.map((a) => a.type).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${category.emoji} ${category.title}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              '${categoryAchievements.where((t) => unlocked.contains(t)).length}/${categoryAchievements.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),

        // Grid de conquistas
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: AppSizes.sm,
            crossAxisSpacing: AppSizes.sm,
            childAspectRatio: 0.85,
          ),
          itemCount: categoryAchievements.length,
          itemBuilder: (context, index) {
            final type = categoryAchievements[index];
            final isUnlocked = unlocked.contains(type);
            final achievement = isUnlocked
                ? state.achievements.firstWhere((a) => a.type == type)
                : null;

            return _AchievementTile(
              type: type,
              isUnlocked: isUnlocked,
              unlockedAt: achievement?.unlockedAt,
              onTap: () => _showAchievementDetail(type, isUnlocked),
            );
          },
        ),

        const SizedBox(height: AppSizes.lg),
      ],
    );
  }

  // ══════════════════════════════════════
  // SHOW DETAIL
  // ══════════════════════════════════════
  void _showAchievementDetail(AchievementType type, bool isUnlocked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? type.color.withOpacity(0.2)
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? type.color : AppColors.textLight,
                  width: 3,
                ),
              ),
              child: Center(
                child: isUnlocked
                    ? Text(type.emoji, style: const TextStyle(fontSize: 36))
                    : Icon(
                        Icons.lock,
                        size: 32,
                        color: AppColors.textLight,
                      ),
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // Title
            Text(
              type.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isUnlocked ? type.color : AppColors.textSecondary,
                  ),
            ),

            const SizedBox(height: AppSizes.xs),

            // Description
            Text(
              type.description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.md),

            // XP
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: (isUnlocked ? type.color : AppColors.textLight)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                '⭐ ${type.xpValue} XP',
                style: TextStyle(
                  color: isUnlocked ? type.color : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // Status
            if (isUnlocked)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    'Desbloqueada',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    'Continue para desbloquear!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),

            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
// STAT CARD
// ══════════════════════════════════════
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSizes.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════
// ACHIEVEMENT TILE
// ══════════════════════════════════════
class _AchievementTile extends StatelessWidget {
  final AchievementType type;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final VoidCallback onTap;

  const _AchievementTile({
    required this.type,
    required this.isUnlocked,
    this.unlockedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? type.color.withOpacity(0.1)
              : AppColors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isUnlocked
                ? type.color.withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji ou Lock
            if (isUnlocked)
              Text(
                type.emoji,
                style: const TextStyle(fontSize: 28),
              )
            else
              Icon(
                Icons.lock_outline,
                size: 28,
                color: AppColors.textLight.withOpacity(0.5),
              ),

            const SizedBox(height: 4),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                type.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      color: isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.textLight,
                      fontWeight:
                          isUnlocked ? FontWeight.w600 : FontWeight.normal,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}