// lib/features/psychologist/widgets/task_response_viewer.dart

import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/task_model.dart';
import '../../../models/task_response_model.dart';

class TaskResponseViewer extends StatelessWidget {
  final TaskResponseModel response;
  final TaskType taskType;

  const TaskResponseViewer({
    super.key,
    required this.response,
    required this.taskType,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══════════════════════════════════════
          // HEADER
          // ══════════════════════════════════════
          _buildHeader(context),

          const SizedBox(height: AppSizes.lg),

          // ══════════════════════════════════════
          // CONTENT BY TYPE
          // ══════════════════════════════════════
          _buildContentByType(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resposta Completa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.success,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(response.completedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
          if (response.durationSeconds != null)
            Column(
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppColors.success, size: 20),
                const SizedBox(height: 2),
                Text(
                  _formatDuration(response.durationSeconds!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContentByType(BuildContext context) {
    switch (taskType) {
      case TaskType.breathing:
        return _buildBreathingView(context);
      case TaskType.thoughtRecord:
        return _buildThoughtRecordView(context);
      case TaskType.journaling:
        return _buildJournalingView(context);
      case TaskType.mindfulness:
        return _buildMindfulnessView(context);
      case TaskType.behavioral:
      case TaskType.custom:
      default:
        return _buildGenericView(context);
    }
  }

  // ══════════════════════════════════════
  // BREATHING VIEW
  // ══════════════════════════════════════
  Widget _buildBreathingView(BuildContext context) {
    final cycles = response.breathingCycles ?? 0;
    final pattern = response.breathingPattern ?? '4-4-4';
    final feeling = response.breathingFeeling ?? 3;

    return Column(
      children: [
        // Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.repeat,
                value: '$cycles',
                label: 'Ciclos',
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.air,
                value: pattern,
                label: 'Padrão',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.md),

        // Feeling scale
        _buildSection(
          context,
          title: 'Como se sentiu após o exercício',
          child: _buildFeelingScale(context, feeling),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // THOUGHT RECORD VIEW
  // ══════════════════════════════════════
  Widget _buildThoughtRecordView(BuildContext context) {
    return Column(
      children: [
        // Situação
        if (response.situation != null)
          _buildSection(
            context,
            title: '📍 Situação',
            child: _buildTextBlock(context, response.situation!),
          ),

        // Pensamento automático
        if (response.automaticThought != null)
          _buildSection(
            context,
            title: '💭 Pensamento Automático',
            child: _buildTextBlock(
              context,
              '"${response.automaticThought}"',
              isQuote: true,
            ),
          ),

        // Emoção
        if (response.emotion != null)
          _buildSection(
            context,
            title: '💔 Emoção Identificada',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    response.emotion!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                if (response.emotionIntensity != null)
                  Text(
                    'Intensidade: ${response.emotionIntensity}/10',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),

        // Evidências a favor
        if (response.evidenceFor != null)
          _buildSection(
            context,
            title: '✅ Evidências a Favor',
            child: _buildTextBlock(context, response.evidenceFor!),
          ),

        // Evidências contra
        if (response.evidenceAgainst != null)
          _buildSection(
            context,
            title: '❌ Evidências Contra',
            child: _buildTextBlock(context, response.evidenceAgainst!),
          ),

        // Pensamento alternativo
        if (response.alternativeThought != null)
          _buildSection(
            context,
            title: '🌟 Pensamento Alternativo',
            child: _buildTextBlock(
              context,
              '"${response.alternativeThought}"',
              isQuote: true,
              highlightColor: AppColors.successLight,
            ),
          ),

        // Mudança de intensidade
        if (response.emotionIntensity != null &&
            response.newEmotionIntensity != null)
          _buildSection(
            context,
            title: '📊 Mudança na Intensidade',
            child: _buildIntensityComparison(
              context,
              before: response.emotionIntensity!,
              after: response.newEmotionIntensity!,
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════
  // JOURNALING VIEW
  // ══════════════════════════════════════
  Widget _buildJournalingView(BuildContext context) {
    final entry = response.journalEntry;
    final prompt = response.journalPrompt;
    final mood = response.journalMood;
    final wordCount = response.responseData['word_count'] as int?;

    return Column(
      children: [
        // Stats
        Row(
          children: [
            if (mood != null)
              Expanded(
                child: _buildStatCard(
                  context,
                  emoji: mood,
                  value: '',
                  label: 'Humor',
                  color: AppColors.primary,
                ),
              ),
            if (mood != null && wordCount != null)
              const SizedBox(width: AppSizes.sm),
            if (wordCount != null)
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.text_fields,
                  value: '$wordCount',
                  label: 'Palavras',
                  color: AppColors.secondary,
                ),
              ),
          ],
        ),

        // Prompt (se houver)
        if (prompt != null && prompt.isNotEmpty)
          _buildSection(
            context,
            title: '💡 Prompt',
            child: _buildTextBlock(
              context,
              prompt,
              isQuote: true,
              textColor: AppColors.primary,
            ),
          ),

        // Entry
        if (entry != null)
          _buildSection(
            context,
            title: '📓 Entrada do Diário',
            child: _buildTextBlock(context, entry),
          ),
      ],
    );
  }

  // ══════════════════════════════════════
  // MINDFULNESS VIEW
  // ══════════════════════════════════════
  Widget _buildMindfulnessView(BuildContext context) {
    final targetDuration =
        response.responseData['target_duration_minutes'] as int?;
    final actualDuration =
        response.responseData['actual_duration_seconds'] as int?;
    final completedFull = response.responseData['completed_full'] as bool?;
    final feeling = response.responseData['feeling_after'] as int?;

    return Column(
      children: [
        // Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: completedFull == true
                    ? Icons.check_circle
                    : Icons.timer_off,
                value: completedFull == true ? 'Sim' : 'Não',
                label: 'Completou',
                color: completedFull == true
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.self_improvement,
                value: actualDuration != null
                    ? _formatDuration(actualDuration)
                    : '-',
                label: 'Duração',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),

        if (targetDuration != null && actualDuration != null)
          _buildSection(
            context,
            title: '⏱️ Progresso',
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (actualDuration / (targetDuration * 60))
                        .clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completedFull == true
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  '${_formatDuration(actualDuration)} de ${targetDuration}min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

        if (feeling != null)
          _buildSection(
            context,
            title: '😌 Nível de Calma',
            child: _buildFeelingScale(context, feeling),
          ),
      ],
    );
  }

  // ══════════════════════════════════════
  // GENERIC VIEW
  // ══════════════════════════════════════
  Widget _buildGenericView(BuildContext context) {
    final rating = response.responseData['rating'] as int?;
    final notes = response.responseData['notes'] as String?;

    return Column(
      children: [
        if (rating != null)
          _buildSection(
            context,
            title: '⭐ Avaliação',
            child: _buildFeelingScale(context, rating),
          ),
        if (notes != null && notes.isNotEmpty)
          _buildSection(
            context,
            title: '📝 Observações',
            child: _buildTextBlock(context, notes),
          ),
      ],
    );
  }

  // ══════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          child,
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    IconData? icon,
    String? emoji,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          if (emoji != null)
            Text(emoji, style: const TextStyle(fontSize: 32))
          else
            Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSizes.xs),
          if (value.isNotEmpty)
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

  Widget _buildTextBlock(
    BuildContext context,
    String text, {
    bool isQuote = false,
    Color? highlightColor,
    Color? textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: highlightColor ?? AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: isQuote
            ? Border(
                left: BorderSide(
                  color: textColor ?? AppColors.primary,
                  width: 3,
                ),
              )
            : null,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: isQuote ? FontStyle.italic : null,
              color: textColor,
              height: 1.6,
            ),
      ),
    );
  }

  Widget _buildFeelingScale(BuildContext context, int value) {
    final emojis = ['😣', '😕', '😐', '😌', '😊'];
    final labels = ['Muito ruim', 'Ruim', 'Ok', 'Bom', 'Ótimo'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final isSelected = index + 1 == value;
          return Column(
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
                    emojis[index],
                    style: TextStyle(
                      fontSize: 24,
                      color: isSelected ? null : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[index],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textLight,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 10,
                    ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildIntensityComparison(
    BuildContext context, {
    required int before,
    required int after,
  }) {
    final improved = after < before;
    final difference = before - after;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: improved ? AppColors.successLight : AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Before
          Column(
            children: [
              Text(
                'Antes',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$before',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
          ),

          // Arrow
          Icon(
            improved ? Icons.trending_down : Icons.trending_up,
            size: 32,
            color: improved ? AppColors.success : AppColors.warning,
          ),

          // After
          Column(
            children: [
              Text(
                'Depois',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: improved
                      ? AppColors.success.withOpacity(0.2)
                      : AppColors.warning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$after',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: improved
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
          ),

          // Difference
          if (improved)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                '-$difference pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // FORMATTERS
  // ══════════════════════════════════════
  String _formatDateTime(DateTime dateTime) {
    final months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.day} ${months[dateTime.month - 1]} às $hour:$minute';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (secs == 0) return '${minutes}min';
    return '${minutes}min ${secs}s';
  }
}