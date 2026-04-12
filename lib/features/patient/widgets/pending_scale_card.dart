// lib/features/patient/widgets/pending_scale_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/scale_assignment_model.dart';
import '../../../models/scale_template_model.dart';
import '../../../providers/scale_templates_provider.dart';

// ═══════════════════════════════════════════════════════
// PENDING SCALE CARD
// Card exibido na home do paciente para escalas pendentes
// ═══════════════════════════════════════════════════════

class PendingScaleCard extends StatelessWidget {
  final ScaleAssignmentModel assignment;
  final String scaleName;
  final String? scaleDescription;
  final String estimatedTime;
  final VoidCallback? onTap;

  const PendingScaleCard({
    super.key,
    required this.assignment,
    required this.scaleName,
    this.scaleDescription,
    required this.estimatedTime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = assignment.isOverdue;

    return GestureDetector(
      onTap: onTap ?? () => _navigateToAnswer(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isOverdue
                ? AppColors.error.withOpacity(0.3)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: isOverdue
                  ? AppColors.error.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════
            // HEADER: Nome + Badge
            // ══════════════════════════════════════
            Row(
              children: [
                // Ícone por categoria
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _categoryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    _categoryIcon(),
                    color: _categoryColor(),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scaleName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (scaleDescription != null)
                        Text(
                          scaleDescription!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Badge de status
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Atrasada',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSizes.sm),

            // ══════════════════════════════════════
            // FOOTER: Tempo + Botão
            // ══════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tempo estimado + frequência
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      estimatedTime,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (assignment.frequency != ScaleFrequency.once) ...[
                      const SizedBox(width: AppSizes.sm),
                      const Icon(
                        Icons.repeat_rounded,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        assignment.frequency.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),

                // Botão "Responder"
                InkWell(
                  onTap: onTap ?? () => _navigateToAnswer(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: const Text(
                      'Responder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // NAVEGAÇÃO
  // ══════════════════════════════════════
  void _navigateToAnswer(BuildContext context) {
    context.push('/app/scale-answer', extra: assignment.id);
  }

  // ══════════════════════════════════════
  // CORES E ÍCONES POR CATEGORIA
  // ══════════════════════════════════════
  Color _categoryColor() {
    if (!assignment.isTemplate) return AppColors.secondary;

    // Mapeamento simples por nome do template
    final id = assignment.scaleTemplateId?.toLowerCase() ?? '';
    if (id.contains('phq') || id.contains('bd')) return AppColors.error;
    if (id.contains('gad') || id.contains('bai')) return AppColors.warning;
    if (id.contains('oq')) return AppColors.info;

    return AppColors.primary;
  }

  IconData _categoryIcon() {
    if (!assignment.isTemplate) return Icons.edit_note_rounded;

    final id = assignment.scaleTemplateId?.toLowerCase() ?? '';
    if (id.contains('phq') || id.contains('bd')) {
      return Icons.cloud_rounded;
    }
    if (id.contains('gad') || id.contains('bai')) {
      return Icons.bolt_rounded;
    }
    if (id.contains('oq')) {
      return Icons.trending_up_rounded;
    }

    return Icons.assignment_rounded;
  }
}

// ═══════════════════════════════════════════════════════
// SKELETON CARD (loading)
// ═══════════════════════════════════════════════════════

class PendingScaleCardSkeleton extends StatelessWidget {
  const PendingScaleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Container(
                height: 12,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 32,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
