// lib/features/psychologist/screens/create_task_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../models/task_model.dart';
import '../../../providers/task_provider.dart';
import '../widgets/task_template_picker.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> patient;

  const CreateTaskScreen({super.key, required this.patient});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  // ══════════════════════════════════════
  // FORM STATE
  // ══════════════════════════════════════
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskType _selectedType = TaskType.custom;
  DateTime _dueDate = DateTime.now();
  bool _isRecurring = false;
  String? _recurrencePattern;
  bool _isSubmitting = false;

  // Configs específicas por tipo
  // Respiração
  int _breathingCycles = 5;
  String _breathingPattern = '4-4-4'; // inhale-hold-exhale

  // Journaling
  String _journalPrompt = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  // AUTO-PREENCHER POR TIPO
  // ══════════════════════════════════════
  void _onTypeSelected(TaskType type) {
    setState(() {
      _selectedType = type;
    });

    // Auto-preencher título e descrição
    switch (type) {
      case TaskType.breathing:
        _titleController.text = 'Exercício de Respiração';
        _descriptionController.text =
            'Pratique respiração consciente para reduzir ansiedade e acalmar a mente.';
        break;
      case TaskType.thoughtRecord:
        _titleController.text = 'Registro de Pensamento';
        _descriptionController.text =
            'Identifique e questione pensamentos automáticos usando a técnica de reestruturação cognitiva (TCC).';
        break;
      case TaskType.journaling:
        _titleController.text = 'Journaling Guiado';
        _descriptionController.text =
            'Escreva sobre seus pensamentos e sentimentos de forma livre ou guiada.';
        break;
      case TaskType.mindfulness:
        _titleController.text = 'Exercício de Mindfulness';
        _descriptionController.text =
            'Pratique atenção plena no momento presente.';
        break;
      case TaskType.behavioral:
        _titleController.text = 'Atividade Comportamental';
        _descriptionController.text =
            'Realize uma atividade que traga bem-estar ou quebre um padrão.';
        break;
      case TaskType.custom:
        _titleController.text = '';
        _descriptionController.text = '';
        break;
    }
  }

  // ══════════════════════════════════════
  // SUBMIT
  // ══════════════════════════════════════
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final psychologistId = SupabaseService.currentUserId;
    if (psychologistId == null) return;

    // Montar task_config
    final config = <String, dynamic>{};
    switch (_selectedType) {
      case TaskType.breathing:
        config['cycles'] = _breathingCycles;
        config['pattern'] = _breathingPattern;
        break;
      case TaskType.journaling:
        if (_journalPrompt.isNotEmpty) {
          config['prompt'] = _journalPrompt;
        }
        break;
      default:
        break;
    }

    final success = await ref.read(taskProvider.notifier).createTask(
          psychologistId: psychologistId,
          patientId: widget.patient['id'] as String,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          taskType: _selectedType,
          taskConfig: config,
          dueDate: _dueDate,
          isRecurring: _isRecurring,
          recurrencePattern: _isRecurring ? _recurrencePattern : null,
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarefa criada com sucesso! ✅'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(taskProvider).error ?? 'Erro ao criar tarefa',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.patient['full_name'] ?? 'Paciente';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Tarefa'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════
              // PARA QUEM
              // ══════════════════════════════════════
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Tarefa para: $patientName',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              // ══════════════════════════════════════
              // TIPO DE TAREFA
              // ══════════════════════════════════════
              TaskTemplatePicker(
                selected: _selectedType,
                onSelected: _onTypeSelected,
              ),

              const SizedBox(height: AppSizes.lg),

              // ══════════════════════════════════════
              // TÍTULO
              // ══════════════════════════════════════
              Text(
                'Título',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Exercício de respiração matinal',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe um título';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSizes.lg),

              // ══════════════════════════════════════
              // DESCRIÇÃO
              // ══════════════════════════════════════
              Text(
                'Descrição / Instruções',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.sm),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Instruções para o paciente...',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              // ══════════════════════════════════════
              // CONFIGURAÇÕES ESPECÍFICAS
              // ══════════════════════════════════════
              _buildTypeSpecificConfig(),

              // ══════════════════════════════════════
              // DATA
              // ══════════════════════════════════════
              Text(
                'Data de entrega',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.sm),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        _formatDate(_dueDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              // ══════════════════════════════════════
              // RECORRÊNCIA
              // ══════════════════════════════════════
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.repeat,
                                size: 20, color: AppColors.primary),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              'Tarefa recorrente',
                              style:
                                  Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isRecurring,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            setState(() {
                              _isRecurring = value;
                              if (!value) _recurrencePattern = null;
                              if (value && _recurrencePattern == null) {
                                _recurrencePattern = 'daily';
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isRecurring) ...[
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        children: [
                          _RecurrenceChip(
                            label: 'Diária',
                            isSelected: _recurrencePattern == 'daily',
                            onTap: () => setState(
                                () => _recurrencePattern = 'daily'),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          _RecurrenceChip(
                            label: 'Dias úteis',
                            isSelected:
                                _recurrencePattern == 'weekdays',
                            onTap: () => setState(
                                () => _recurrencePattern = 'weekdays'),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          _RecurrenceChip(
                            label: 'Semanal',
                            isSelected: _recurrencePattern == 'weekly',
                            onTap: () => setState(
                                () => _recurrencePattern = 'weekly'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'Será criada automaticamente para os próximos 7 dias',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // ══════════════════════════════════════
              // BOTÃO CRIAR
              // ══════════════════════════════════════
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Criar Tarefa'),
              ),

              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // CONFIG ESPECÍFICA POR TIPO
  // ══════════════════════════════════════
  Widget _buildTypeSpecificConfig() {
    switch (_selectedType) {
      case TaskType.breathing:
        return _buildBreathingConfig();
      case TaskType.journaling:
        return _buildJournalingConfig();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBreathingConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações de Respiração',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              // Ciclos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ciclos de respiração',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _breathingCycles > 1
                            ? () =>
                                setState(() => _breathingCycles--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 28,
                      ),
                      Text(
                        '$_breathingCycles',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                      IconButton(
                        onPressed: _breathingCycles < 20
                            ? () =>
                                setState(() => _breathingCycles++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 28,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              // Padrão
              Text(
                'Padrão de respiração',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  _BreathingPatternChip(
                    label: '4-4-4',
                    subtitle: 'Básico',
                    isSelected: _breathingPattern == '4-4-4',
                    onTap: () =>
                        setState(() => _breathingPattern = '4-4-4'),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  _BreathingPatternChip(
                    label: '4-7-8',
                    subtitle: 'Relaxante',
                    isSelected: _breathingPattern == '4-7-8',
                    onTap: () =>
                        setState(() => _breathingPattern = '4-7-8'),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  _BreathingPatternChip(
                    label: '5-5-5',
                    subtitle: 'Equilibrado',
                    isSelected: _breathingPattern == '5-5-5',
                    onTap: () =>
                        setState(() => _breathingPattern = '5-5-5'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
      ],
    );
  }

  Widget _buildJournalingConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prompt do Journaling',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Opcional: dê uma pergunta ou tema para guiar o paciente.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSizes.sm),
        TextFormField(
          maxLines: 2,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Ex: O que te fez sentir gratidão hoje?',
          ),
          onChanged: (value) => _journalPrompt = value,
        ),
        const SizedBox(height: AppSizes.lg),
      ],
    );
  }

  // ══════════════════════════════════════
  // DATE PICKER
  // ══════════════════════════════════════
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hoje';
    if (d == today.add(const Duration(days: 1))) return 'Amanhã';

    const months = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}

// ══════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════
class _RecurrenceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecurrenceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _BreathingPatternChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _BreathingPatternChip({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color:
                          isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}