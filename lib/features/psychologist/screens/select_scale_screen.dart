// lib/features/psychologist/screens/select_scale_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../providers/scale_templates_provider.dart';
import '../../../models/scale_template_model.dart';

// ═══════════════════════════════════════════════════════
// SELECT SCALE SCREEN
// Lista de escalas disponíveis por categoria
// ═══════════════════════════════════════════════════════

class SelectScaleScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const SelectScaleScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<SelectScaleScreen> createState() => _SelectScaleScreenState();
}

class _SelectScaleScreenState extends ConsumerState<SelectScaleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Removida a aba de escalas personalizadas - apenas escalas validadas
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    await ref.read(scaleTemplatesProvider.notifier).loadTemplates();
    // Escalas personalizadas desativadas - não carrega custom scales
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templatesState = ref.watch(scaleTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Escala'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              text: '${ScaleCategory.depression.emoji} Depressão',
            ),
            Tab(
              text: '${ScaleCategory.anxiety.emoji} Ansiedade',
            ),
            Tab(
              text: '${ScaleCategory.progress.emoji} Progresso',
            ),
            // Aba de escalas personalizadas desativada - apenas escalas validadas
          ],
        ),
      ),
      body: templatesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TemplateCategoryList(
                  category: ScaleCategory.depression,
                  patientId: widget.patientId,
                  patientName: widget.patientName,
                ),
                _TemplateCategoryList(
                  category: ScaleCategory.anxiety,
                  patientId: widget.patientId,
                  patientName: widget.patientName,
                ),
                _TemplateCategoryList(
                  category: ScaleCategory.progress,
                  patientId: widget.patientId,
                  patientName: widget.patientName,
                ),
                // Escalas personalizadas desativadas
              ],
            ),
      // FAB de criar escala personalizada desativado - apenas escalas validadas
    );
  }
}

// ═══════════════════════════════════════════════════════
// TEMPLATE CATEGORY LIST
// ═══════════════════════════════════════════════════════

class _TemplateCategoryList extends ConsumerWidget {
  final ScaleCategory category;
  final String patientId;
  final String patientName;

  const _TemplateCategoryList({
    required this.category,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesState = ref.watch(scaleTemplatesProvider);
    final templates = templatesState.byCategory[category] ?? [];

    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Nenhuma escala de ${category.label.toLowerCase()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _ScaleTemplateCard(
          template: template,
          onSelect: () => _navigateToConfigure(context, template),
        );
      },
    );
  }

  void _navigateToConfigure(
    BuildContext context,
    ScaleTemplateModel template,
  ) {
    context.push('/psi/configure-scale', extra: {
      'template': template,
      'patientId': patientId,
      'patientName': patientName,
    });
  }
}

// ═══════════════════════════════════════════════════════
// CUSTOM SCALES LIST - DESATIVADO
// Apenas escalas validadas estão disponíveis
// ═══════════════════════════════════════════════════════
/*
class _CustomScalesList extends ConsumerWidget {
  final String patientId;
  final String patientName;

  const _CustomScalesList({
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customState = ref.watch(customScalesProvider);

    if (customState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customState.scales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎨', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSizes.md),
            Text(
              'Nenhuma escala personalizada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Crie uma escala personalizada ou edite uma existente.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton.icon(
              onPressed: () => context.push(
                '/psi/create-custom-scale',
                extra: {'patientId': patientId},
              ),
              icon: const Icon(Icons.add),
              label: const Text('Criar Escala'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: customState.scales.length,
      itemBuilder: (context, index) {
        final scale = customState.scales[index];
        return _CustomScaleCard(
          scale: scale,
          onSelect: () => _navigateToConfigureCustom(context, scale),
        );
      },
    );
  }

  void _navigateToConfigureCustom(
    BuildContext context,
    dynamic scale,
  ) {
    context.push('/psi/configure-scale', extra: {
      'customScale': scale,
      'patientId': patientId,
      'patientName': patientName,
    });
  }
}
*/

// ═══════════════════════════════════════════════════════
// SCALE TEMPLATE CARD
// ═══════════════════════════════════════════════════════

class _ScaleTemplateCard extends StatelessWidget {
  final ScaleTemplateModel template;
  final VoidCallback onSelect;

  const _ScaleTemplateCard({
    required this.template,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _categoryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    _categoryIcon(),
                    color: _categoryColor(),
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              template.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (template.isValidated)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: AppColors.success),
                                  SizedBox(width: 2),
                                  Text(
                                    'Validado',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (template.description != null)
                        Text(
                          template.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.question_answer_rounded,
                  label: '${template.questions.length} perguntas',
                ),
                const SizedBox(width: AppSizes.sm),
                _InfoChip(
                  icon: Icons.access_time_rounded,
                  label: template.estimatedTime,
                ),
                if (template.reference != null) ...[
                  const SizedBox(width: AppSizes.sm),
                  _InfoChip(
                    icon: Icons.science_rounded,
                    label: template.reference!.split(',').first,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor() {
    switch (template.category) {
      case ScaleCategory.depression:
        return AppColors.error;
      case ScaleCategory.anxiety:
        return AppColors.warning;
      case ScaleCategory.progress:
        return AppColors.info;
      case ScaleCategory.general:
        return AppColors.primary;
    }
  }

  IconData _categoryIcon() {
    switch (template.category) {
      case ScaleCategory.depression:
        return Icons.cloud_rounded;
      case ScaleCategory.anxiety:
        return Icons.bolt_rounded;
      case ScaleCategory.progress:
        return Icons.trending_up_rounded;
      case ScaleCategory.general:
        return Icons.assignment_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════
// CUSTOM SCALE CARD - DESATIVADO
// ═══════════════════════════════════════════════════════
/*
class _CustomScaleCard extends StatelessWidget {
  final dynamic scale;
  final VoidCallback onSelect;

  const _CustomScaleCard({
    required this.scale,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.secondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              scale.name ?? 'Sem nome',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (scale.isDraft == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                              ),
                              child: const Text(
                                'Rascunho',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (scale.description != null)
                        Text(
                          scale.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.question_answer_rounded,
                  label: '${scale.questionCount ?? 0} perguntas',
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.sm),
                _InfoChip(
                  icon: Icons.timer_outlined,
                  label: '~${scale.estimatedTime ?? '5'} min',
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/

// ═══════════════════════════════════════════════════════
// INFO CHIP
// ═══════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
