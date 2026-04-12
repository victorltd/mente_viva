// lib/features/psychologist/widgets/patient_scales_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/scale_assignment_model.dart';
import '../../../providers/scale_assignments_provider.dart';
import '../../../providers/scale_responses_provider.dart';
import '../../../providers/scale_templates_provider.dart';
import '../../../core/supabase/supabase_service.dart';

// ═══════════════════════════════════════════════════════
// PATIENT SCALES TAB
// Aba de escalas dentro do PatientDetailScreen
// ═══════════════════════════════════════════════════════

class PatientScalesTab extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const PatientScalesTab({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<PatientScalesTab> createState() => _PatientScalesTabState();
}

class _PatientScalesTabState extends ConsumerState<PatientScalesTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    // Carrega TODAS as escalas (ativas, pausadas, completadas)
    final client = SupabaseService.client;
    final response = await client
        .from('scale_assignments')
        .select()
        .eq('patient_id', widget.patientId)
        .order('created_at', ascending: false);

    final assignments = (response as List)
        .map((json) => ScaleAssignmentModel.fromJson(json))
        .toList();

    ref.read(scaleAssignmentsProvider.notifier).state =
        ref.read(scaleAssignmentsProvider).copyWith(assignments: assignments);

    // Carregar templates para nomes
    if (ref.read(scaleTemplatesProvider).templates.isEmpty) {
      await ref.read(scaleTemplatesProvider.notifier).loadTemplates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(scaleAssignmentsProvider);
    final templatesState = ref.watch(scaleTemplatesProvider);

    if (assignmentsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (assignmentsState.assignments.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
              80, // Space for FAB
            ),
            itemCount: assignmentsState.assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignmentsState.assignments[index];
              String scaleName = assignment.scaleLabel;
              String estimatedTime = '~3 min';

              if (assignment.isTemplate) {
                final template =
                    templatesState.getTemplateById(assignment.scaleId);
                if (template != null) {
                  scaleName = template.name;
                  estimatedTime = template.estimatedTime;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: _ScaleAssignmentCard(
                  assignment: assignment,
                  scaleName: scaleName,
                  estimatedTime: estimatedTime,
                  onViewResults: () =>
                      _navigateToResults(context, assignment.id),
                  onPauseResume: () => _togglePause(context, assignment),
                  onDelete: () => _confirmDelete(context, assignment),
                ),
              );
            },
          ),
        ),
        // FAB
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _showSelectScale(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
                Icons.analytics_outlined,
                size: 48,
                color: AppColors.textLight.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Nenhuma escala atribuída',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Atribua escalas validadas para acompanhar a evolução do paciente.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton.icon(
              onPressed: () => _showSelectScale(context),
              icon: const Icon(Icons.add),
              label: const Text('Atribuir Escala'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToResults(BuildContext context, String assignmentId) {
    context.push('/psi/scale-results', extra: assignmentId);
  }

  Future<void> _togglePause(BuildContext context, ScaleAssignmentModel assignment) async {
    final notifier = ref.read(scaleAssignmentsProvider.notifier);
    if (assignment.status == AssignmentStatus.paused) {
      await notifier.resumeAssignment(assignment.id);
    } else {
      await notifier.pauseAssignment(assignment.id);
    }
  }

  Future<void> _confirmDelete(BuildContext context, ScaleAssignmentModel assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover escala?'),
        content: Text(
          'A escala "${assignment.scaleLabel}" será removida deste paciente. '
          'As respostas já registradas serão mantidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(scaleAssignmentsProvider.notifier)
          .deactivateAssignment(assignment.id);
    }
  }

  void _showSelectScale(BuildContext context) {
    context.push('/psi/select-scale', extra: {
      'patientId': widget.patientId,
      'patientName': widget.patientName,
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════
// SCALE ASSIGNMENT CARD
// ═══════════════════════════════════════════════════════

class _ScaleAssignmentCard extends StatelessWidget {
  final ScaleAssignmentModel assignment;
  final String scaleName;
  final String estimatedTime;
  final VoidCallback onViewResults;
  final VoidCallback onPauseResume;
  final VoidCallback onDelete;

  const _ScaleAssignmentCard({
    required this.assignment,
    required this.scaleName,
    required this.estimatedTime,
    required this.onViewResults,
    required this.onPauseResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // ══════════════════════════════════════
          // HEADER
          // ══════════════════════════════════════
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  _getCategoryIcon(),
                  color: _getCategoryColor(),
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
                    ),
                    Text(
                      assignment.frequency.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  assignment.status.label,
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.md),

          // ══════════════════════════════════════
          // INFO ROW
          // ══════════════════════════════════════
          Row(
            children: [
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: estimatedTime,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.sm),
              if (assignment.nextDueDate != null)
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: 'Próx: ${_formatDate(assignment.nextDueDate!)}',
                  color: AppColors.textSecondary,
                ),
              if (assignment.lastCompletedAt != null)
                _InfoChip(
                  icon: Icons.check_circle_outline,
                  label: 'Respondida',
                  color: AppColors.success,
                ),
            ],
          ),

          const SizedBox(height: AppSizes.sm),

          // ══════════════════════════════════════
          // ACTIONS
          // ══════════════════════════════════════
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Pausar/Retomar
              Tooltip(
                message: assignment.status == AssignmentStatus.paused
                    ? 'Retomar'
                    : 'Pausar',
                child: IconButton(
                  icon: Icon(
                    assignment.status == AssignmentStatus.paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    size: 20,
                  ),
                  onPressed: onPauseResume,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              // Deletar
              Tooltip(
                message: 'Remover',
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: onDelete,
                  color: AppColors.error,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              // Resultados (InkWell sem constraints)
              InkWell(
                onTap: onViewResults,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bar_chart,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Resultados',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    final id = assignment.scaleTemplateId?.toLowerCase() ?? '';
    if (id.contains('phq') || id.contains('bd')) return AppColors.error;
    if (id.contains('gad') || id.contains('bai')) return AppColors.warning;
    if (id.contains('oq')) return AppColors.info;
    return AppColors.primary;
  }

  IconData _getCategoryIcon() {
    final id = assignment.scaleTemplateId?.toLowerCase() ?? '';
    if (id.contains('phq') || id.contains('bd')) return Icons.cloud_rounded;
    if (id.contains('gad') || id.contains('bai')) return Icons.bolt_rounded;
    if (id.contains('oq')) return Icons.trending_up_rounded;
    return Icons.analytics_outlined;
  }

  Color _getStatusColor() {
    switch (assignment.status) {
      case AssignmentStatus.active:
        return AppColors.success;
      case AssignmentStatus.paused:
        return AppColors.warning;
      case AssignmentStatus.completed:
        return AppColors.textLight;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
