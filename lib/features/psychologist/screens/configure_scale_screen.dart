// lib/features/psychologist/screens/configure_scale_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/scale_template_model.dart';
import '../../../models/scale_assignment_model.dart';
import '../../../providers/scale_assignments_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/supabase/supabase_service.dart';

// ═══════════════════════════════════════════════════════
// CONFIGURE SCALE SCREEN
// Configura frequência, data e notificações antes de atribuir
// ═══════════════════════════════════════════════════════

class ConfigureScaleScreen extends ConsumerStatefulWidget {
  final ScaleTemplateModel? template;
  final dynamic customScale;
  final String patientId;
  final String patientName;

  const ConfigureScaleScreen({
    super.key,
    this.template,
    this.customScale,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<ConfigureScaleScreen> createState() =>
      _ConfigureScaleScreenState();
}

class _ConfigureScaleScreenState extends ConsumerState<ConfigureScaleScreen> {
  // ══════════════════════════════════════
  // STATE
  // ══════════════════════════════════════
  ScaleFrequency _frequency = ScaleFrequency.once;
  DateTime _startDate = DateTime.now();
  bool _notifyPatient = true;
  final _customInstructionsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _customInstructionsController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  // GETTERS
  // ══════════════════════════════════════
  bool get _isTemplate => widget.template != null;
  String get _scaleName =>
      widget.template?.name ?? widget.customScale?.name ?? 'Escala';
  int get _questionCount => _isTemplate
      ? widget.template!.questions.length
      : (widget.customScale?.questions as List?)?.length ?? 0;
  String get _estimatedTime =>
      widget.template?.estimatedTime ??
      widget.customScale?.estimatedTime ??
      '~5 min';

  // ══════════════════════════════════════
  // ATRIBUIR ESCALA
  // ══════════════════════════════════════
  Future<void> _assignScale() async {
    setState(() => _isLoading = true);

    final psychologistId = SupabaseService.currentUserId;
    if (psychologistId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: psicólogo não autenticado'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final success = await ref
        .read(scaleAssignmentsProvider.notifier)
        .assignScale(
          patientId: widget.patientId,
          psychologistId: psychologistId,
          scaleTemplateId:
              _isTemplate ? widget.template!.id : null,
          customScaleId:
              _isTemplate ? null : widget.customScale?.id,
          frequency: _frequency,
          startDate: _startDate,
          customInstructions: _customInstructionsController.text.trim().isEmpty
              ? null
              : _customInstructionsController.text.trim(),
        );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escala atribuída com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true); // Retorna true para indicar sucesso
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(scaleAssignmentsProvider).error ??
                  'Erro ao atribuir escala',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════
  // SELECIONAR DATA
  // ══════════════════════════════════════
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  // ══════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Escala'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ══════════════════════════════════════
                  // PREVIEW DA ESCALA
                  // ══════════════════════════════════════
                  _buildScalePreview(),

                  const SizedBox(height: AppSizes.lg),

                  // ══════════════════════════════════════
                  // FREQUÊNCIA
                  // ══════════════════════════════════════
                  Text(
                    'Frequência',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  ...ScaleFrequency.values.map((freq) {
                    return RadioListTile<ScaleFrequency>(
                      value: freq,
                      groupValue: _frequency,
                      onChanged: (value) {
                        setState(() => _frequency = value!);
                      },
                      title: Text(freq.label),
                      subtitle: Text(freq.description),
                      activeColor: AppColors.primary,
                    );
                  }).toList(),

                  const Divider(height: AppSizes.xl * 2),

                  // ══════════════════════════════════════
                  // DATA DE INÍCIO
                  // ══════════════════════════════════════
                  Text(
                    'Data de Início',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSizes.md),
                          Text(
                            _formatDate(_startDate),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: AppSizes.xl * 2),

                  // ══════════════════════════════════════
                  // NOTIFICAÇÕES
                  // ══════════════════════════════════════
                  Text(
                    'Notificações',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  SwitchListTile(
                    value: _notifyPatient,
                    onChanged: (value) {
                      setState(() => _notifyPatient = value);
                    },
                    title: const Text('Notificar paciente'),
                    subtitle: const Text(
                      'Enviar notificação quando a escala estiver disponível',
                    ),
                    activeColor: AppColors.primary,
                  ),

                  const Divider(height: AppSizes.xl * 2),

                  // ══════════════════════════════════════
                  // INSTRUÇÕES CUSTOMIZADAS
                  // ══════════════════════════════════════
                  Text(
                    'Instruções Adicionais',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Opcional: adicione uma mensagem pessoal para o paciente.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _customInstructionsController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Preencha com calma, sem pressa...',
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: AppSizes.xxl),

                  // ══════════════════════════════════════
                  // BOTÃO ATRIBUIR
                  // ══════════════════════════════════════
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _assignScale,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(
                        'Atribuir "${_scaleName}" para ${widget.patientName.split(' ').first}',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  // ══════════════════════════════════════
                  // BOTÃO PERSONALIZAR (só para templates)
                  // ══════════════════════════════════════
                  if (_isTemplate) ...[
                    const SizedBox(height: AppSizes.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _editTemplate(context),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Personalizar Perguntas'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // ══════════════════════════════════════
  // SCALE PREVIEW
  // ══════════════════════════════════════
  Widget _buildScalePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (_isTemplate
                          ? _categoryColor()
                          : AppColors.secondary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  _isTemplate ? _categoryIcon() : Icons.edit_note_rounded,
                  color:
                      _isTemplate ? _categoryColor() : AppColors.secondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _scaleName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.question_answer_rounded,
                          label: '$_questionCount perguntas',
                        ),
                        const SizedBox(width: AppSizes.sm),
                        _InfoChip(
                          icon: Icons.access_time_rounded,
                          label: _estimatedTime,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isTemplate && widget.template!.isValidated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // EDIT TEMPLATE
  // ══════════════════════════════════════
  void _editTemplate(BuildContext context) {
    context.push('/psi/edit-scale', extra: {
      'template': widget.template,
      'patientId': widget.patientId,
      'patientName': widget.patientName,
    });
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  Color _categoryColor() {
    switch (widget.template!.category) {
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
    switch (widget.template!.category) {
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

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Hoje';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Amanhã';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

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
