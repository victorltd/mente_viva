// lib/features/psychologist/widgets/task_response_card.dart

import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/task_model.dart';
import '../../../models/task_response_model.dart';

class TaskResponseCard extends StatelessWidget {
  final TaskResponseModel response;
  final TaskType taskType;
  final VoidCallback? onTap;
  final bool showFullContent;

  const TaskResponseCard({
    super.key,
    required this.response,
    required this.taskType,
    this.onTap,
    this.showFullContent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════
              // HEADER
              // ══════════════════════════════════════
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Concluída',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.success,
                                  ),
                        ),
                        Text(
                          _formatDateTime(response.completedAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (response.durationSeconds != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: AppSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(response.durationSeconds!),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSizes.md),
              const Divider(height: 1),
              const SizedBox(height: AppSizes.md),

              // ══════════════════════════════════════
              // CONTENT BY TYPE
              // ══════════════════════════════════════
              _buildContentByType(context),

              // ══════════════════════════════════════
              // VIEW MORE (se não for full)
              // ══════════════════════════════════════
              if (!showFullContent && onTap != null) ...[
                const SizedBox(height: AppSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ver detalhes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentByType(BuildContext context) {
    switch (taskType) {
      case TaskType.breathing:
        return _buildBreathingContent(context);
      case TaskType.thoughtRecord:
        return _buildThoughtRecordContent(context);
      case TaskType.journaling:
        return _buildJournalingContent(context);
      case TaskType.mindfulness:
        return _buildMindfulnessContent(context);
      case TaskType.behavioral:
      case TaskType.custom:
      default:
        return _buildGenericContent(context);
    }
  }

  // ══════════════════════════════════════
  // BREATHING CONTENT
  // ══════════════════════════════════════
  Widget _buildBreathingContent(BuildContext context) {
    final cycles = response.breathingCycles;
    final pattern = response.breathingPattern;
    final feeling = response.breathingFeeling;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildMetricChip(
              context,
              icon: Icons.repeat,
              label: '$cycles ciclos',
              color: AppColors.info,
            ),
            const SizedBox(width: AppSizes.sm),
            if (pattern != null)
              _buildMetricChip(
                context,
                icon: Icons.air,
                label: pattern,
                color: AppColors.secondary,
              ),
          ],
        ),
        if (feeling != null) ...[
          const SizedBox(height: AppSizes.sm),
          _buildFeelingIndicator(context, feeling, 'Sensação após'),
        ],
      ],
    );
  }

  // ══════════════════════════════════════
  // THOUGHT RECORD CONTENT
  // ══════════════════════════════════════
  Widget _buildThoughtRecordContent(BuildContext context) {
    final situation = response.situation;
    final thought = response.automaticThought;
    final emotion = response.emotion;
    final emotionIntensity = response.emotionIntensity;
    final newIntensity = response.newEmotionIntensity;
    final alternative = response.alternativeThought;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Situação (resumo)
        if (situation != null) ...[
          _buildLabeledText(
            context,
            label: '📍 Situação',
            text: situation,
            maxLines: showFullContent ? null : 2,
          ),
          const SizedBox(height: AppSizes.sm),
        ],

        // Pensamento automático
        if (thought != null) ...[
          _buildLabeledText(
            context,
            label: '💭 Pensamento',
            text: '"$thought"',
            maxLines: showFullContent ? null : 2,
            isItalic: true,
          ),
          const SizedBox(height: AppSizes.sm),
        ],

        // Emoção + Intensidade
        if (emotion != null) ...[
          Row(
            children: [
              _buildMetricChip(
                context,
                icon: Icons.favorite,
                label: emotion,
                color: AppColors.error,
              ),
              if (emotionIntensity != null) ...[
                const SizedBox(width: AppSizes.sm),
                _buildIntensityChange(
                  context,
                  before: emotionIntensity,
                  after: newIntensity,
                ),
              ],
            ],
          ),
        ],

        // Pensamento alternativo (só no full)
        if (showFullContent && alternative != null) ...[
          const SizedBox(height: AppSizes.md),
          _buildLabeledText(
            context,
            label: '🌟 Pensamento alternativo',
            text: '"$alternative"',
            isItalic: true,
            highlightColor: AppColors.successLight,
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════
  // JOURNALING CONTENT
  // ══════════════════════════════════════
  Widget _buildJournalingContent(BuildContext context) {
    final entry = response.journalEntry;
    final mood = response.journalMood;
    final wordCount = response.responseData['word_count'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mood + Word count
        Row(
          children: [
            if (mood != null)
              Text(mood, style: const TextStyle(fontSize: 24)),
            if (mood != null) const SizedBox(width: AppSizes.sm),
            if (wordCount != null)
              _buildMetricChip(
                context,
                icon: Icons.text_fields,
                label: '$wordCount palavras',
                color: AppColors.secondary,
              ),
          ],
        ),

        // Entry preview
        if (entry != null) ...[
          const SizedBox(height: AppSizes.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              entry,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
              maxLines: showFullContent ? null : 4,
              overflow:
                  showFullContent ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════
  // MINDFULNESS CONTENT
  // ══════════════════════════════════════
  Widget _buildMindfulnessContent(BuildContext context) {
    final targetDuration =
        response.responseData['target_duration_minutes'] as int?;
    final actualDuration =
        response.responseData['actual_duration_seconds'] as int?;
    final completedFull = response.responseData['completed_full'] as bool?;
    final feeling = response.responseData['feeling_after'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildMetricChip(
              context,
              icon: completedFull == true
                  ? Icons.check_circle
                  : Icons.timer_outlined,
              label: completedFull == true
                  ? 'Completa'
                  : 'Encerrada antes',
              color: completedFull == true
                  ? AppColors.success
                  : AppColors.warning,
            ),
            const SizedBox(width: AppSizes.sm),
            if (actualDuration != null)
              _buildMetricChip(
                context,
                icon: Icons.self_improvement,
                label: _formatDuration(actualDuration),
                color: AppColors.secondary,
              ),
          ],
        ),
        if (feeling != null) ...[
          const SizedBox(height: AppSizes.sm),
          _buildFeelingIndicator(context, feeling, 'Nível de calma'),
        ],
      ],
    );
  }

  // ══════════════════════════════════════
  // GENERIC CONTENT
  // ══════════════════════════════════════
  Widget _buildGenericContent(BuildContext context) {
    final rating = response.responseData['rating'] as int?;
    final notes = response.responseData['notes'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rating != null) ...[
          _buildFeelingIndicator(context, rating, 'Avaliação'),
          const SizedBox(height: AppSizes.sm),
        ],
        if (notes != null && notes.isNotEmpty) ...[
          _buildLabeledText(
            context,
            label: '📝 Observações',
            text: notes,
            maxLines: showFullContent ? null : 3,
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════
  Widget _buildMetricChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingIndicator(
    BuildContext context,
    int value,
    String label,
  ) {
    final emojis = ['😣', '😕', '😐', '😌', '😊'];
    final colors = [
      AppColors.error,
      AppColors.warning,
      AppColors.textSecondary,
      AppColors.secondary,
      AppColors.success,
    ];

    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        ...List.generate(5, (index) {
          final isSelected = index < value;
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(
              emojis[index],
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? null : Colors.grey.shade300,
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          '$value/5',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors[value - 1],
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildIntensityChange(
    BuildContext context, {
    required int before,
    int? after,
  }) {
    if (after == null) {
      return _buildMetricChip(
        context,
        icon: Icons.trending_flat,
        label: '$before/10',
        color: AppColors.textSecondary,
      );
    }

    final improved = after < before;
    final color = improved ? AppColors.success : AppColors.warning;
    final icon = improved ? Icons.trending_down : Icons.trending_up;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$before → $after',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledText(
    BuildContext context, {
    required String label,
    required String text,
    int? maxLines,
    bool isItalic = false,
    Color? highlightColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: highlightColor != null
              ? const EdgeInsets.all(AppSizes.sm)
              : null,
          decoration: highlightColor != null
              ? BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                )
              : null,
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: isItalic ? FontStyle.italic : null,
                  height: 1.4,
                ),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // FORMATTERS
  // ══════════════════════════════════════
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (date == today) {
      dateStr = 'Hoje';
    } else if (date == today.subtract(const Duration(days: 1))) {
      dateStr = 'Ontem';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$dateStr às $hour:$minute';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (secs == 0) return '${minutes}min';
    return '${minutes}min ${secs}s';
  }
}