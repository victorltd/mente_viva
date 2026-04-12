// lib/features/psychologist/screens/edit_scale_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/scale_template_model.dart';
import '../../../models/custom_scale_model.dart';
import '../../../providers/custom_scales_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/supabase/supabase_service.dart';

// ═══════════════════════════════════════════════════════
// EDIT SCALE SCREEN
// Editor estilo Google Forms para personalizar escala
// ═══════════════════════════════════════════════════════

class EditScaleScreen extends ConsumerStatefulWidget {
  final ScaleTemplateModel? template;
  final CustomScaleModel? existingScale;
  final String patientId;
  final String patientName;

  const EditScaleScreen({
    super.key,
    this.template,
    this.existingScale,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<EditScaleScreen> createState() => _EditScaleScreenState();
}

class _EditScaleScreenState extends ConsumerState<EditScaleScreen> {
  // ══════════════════════════════════════
  // STATE
  // ══════════════════════════════════════
  late String _name;
  late String _instructions;
  late List<Map<String, dynamic>> _questions;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingScale != null) {
      _name = widget.existingScale!.name;
      _instructions = widget.existingScale!.instructions;
      _questions = widget.existingScale!.questions
          .map((q) => q.toJson())
          .toList();
    } else if (widget.template != null) {
      _name = '${widget.template!.name} (Personalizada)';
      _instructions = widget.template!.instructions;
      _questions =
          widget.template!.questions.map((q) => q.toJson()).toList();
    } else {
      _name = '';
      _instructions = '';
      _questions = [];
    }
  }

  // ══════════════════════════════════════
  // CRUD PERGUNTAS
  // ══════════════════════════════════════
  void _addQuestion() {
    setState(() {
      _questions.add({
        'id': 'q${_questions.length + 1}',
        'order': _questions.length + 1,
        'text': '',
        'required': true,
        'is_critical': false,
        'alert_threshold': null,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      // Reordenar
      for (int i = 0; i < _questions.length; i++) {
        _questions[i]['order'] = i + 1;
      }
    });
  }

  void _updateQuestion(int index, String key, dynamic value) {
    setState(() {
      _questions[index][key] = value;
    });
  }

  void _moveQuestion(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _questions.length) return;

    setState(() {
      final temp = _questions[index];
      _questions[index] = _questions[newIndex];
      _questions[newIndex] = temp;

      // Reordenar
      for (int i = 0; i < _questions.length; i++) {
        _questions[i]['order'] = i + 1;
      }
    });
  }

  // ══════════════════════════════════════
  // SALVAR
  // ══════════════════════════════════════
  Future<void> _saveScale() async {
    if (_name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome da escala'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma pergunta'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final hasEmptyQuestion = _questions.any((q) => q['text'].toString().trim().isEmpty);
    if (hasEmptyQuestion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas as perguntas devem ter texto'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final psychologistId = SupabaseService.currentUserId!;

    // Montar opções de resposta do template ou padrão
    final responseOptions = widget.template?.responseOptions
            .map((r) => r.toJson())
            .toList() ??
        [
          {'value': 0, 'label': 'Nunca'},
          {'value': 1, 'label': 'Às vezes'},
          {'value': 2, 'label': 'Frequentemente'},
          {'value': 3, 'label': 'Sempre'},
        ];

    // Montar scoring
    final scoring = widget.template?.scoring.toJson() ?? {
      'method': 'sum',
      'min_score': 0,
      'max_score': _questions.length * 3,
      'reverse_items': [],
      'severity_ranges': [
        {'min': 0, 'max': 4, 'level': 'minimal', 'label': 'Mínimo', 'color': '#10B981'},
        {'min': 5, 'max': 9, 'level': 'mild', 'label': 'Leve', 'color': '#F59E0B'},
        {'min': 10, 'max': 14, 'level': 'moderate', 'label': 'Moderado', 'color': '#F97316'},
        {'min': 15, 'max': 999, 'level': 'severe', 'label': 'Grave', 'color': '#EF4444'},
      ],
    };

    // Parse questions
    final questions = _questions
        .map((q) => ScaleQuestion.fromJson(q))
        .toList();

    final responseOpts = responseOptions
        .map((r) => ResponseOption.fromJson(r))
        .toList();

    final scoringConfig = ScoringConfig.fromJson(scoring);

    final customScale = CustomScaleModel(
      id: widget.existingScale?.id ?? '',
      psychologistId: psychologistId,
      baseTemplateId: widget.template?.id,
      name: _name.trim(),
      instructions: _instructions.trim(),
      responseOptions: responseOpts,
      questions: questions,
      scoring: scoringConfig,
      isValidated: false,
      isDraft: true,
      createdAt: widget.existingScale?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (widget.existingScale != null) {
      success = await ref
          .read(customScalesProvider.notifier)
          .updateScale(customScale);
    } else {
      success = await ref
          .read(customScalesProvider.notifier)
          .createScale(customScale);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escala salva com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Voltar para configure screen com a escala criada
        context.pop(ref.read(customScalesProvider).scales.first);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(customScalesProvider).error ??
                  'Erro ao salvar escala',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingScale != null
              ? 'Editar Escala'
              : 'Personalizar Escala',
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveScale,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════
            // AVISO (se baseado em template)
            // ══════════════════════════════════════
            if (widget.template != null)
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border:
                      Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.warning, size: 22),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        'Esta escala é baseada em "${widget.template!.name}". '
                        'Alterações podem comprometer a validação científica.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.template != null) const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // NOME DA ESCALA
            // ══════════════════════════════════════
            Text(
              'Nome da Escala',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextFormField(
              initialValue: _name,
              onChanged: (value) => _name = value,
              decoration: const InputDecoration(
                hintText: 'Ex: Avaliação de Humor Semanal',
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // ══════════════════════════════════════
            // INSTRUÇÕES
            // ══════════════════════════════════════
            Text(
              'Instruções',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextFormField(
              initialValue: _instructions,
              onChanged: (value) => _instructions = value,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Instruções para o paciente...',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // ══════════════════════════════════════
            // PERGUNTAS
            // ══════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Perguntas (${_questions.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),

            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;

              return _QuestionCard(
                index: index,
                question: question,
                totalQuestions: _questions.length,
                onUpdate: (key, value) => _updateQuestion(index, key, value),
                onRemove: () => _removeQuestion(index),
                onMoveUp: index > 0
                    ? () => _moveQuestion(index, -1)
                    : null,
                onMoveDown: index < _questions.length - 1
                    ? () => _moveQuestion(index, 1)
                    : null,
              );
            }).toList(),

            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// QUESTION CARD
// ═══════════════════════════════════════════════════════

class _QuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final int totalQuestions;
  final Function(String, dynamic) onUpdate;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.totalQuestions,
    required this.onUpdate,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: question['is_critical'] == true
              ? AppColors.error.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: número + ações
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  'Pergunta ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              // Mover
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: onMoveUp,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 18),
                onPressed: onMoveDown,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Excluir pergunta?'),
                      content: const Text('Esta ação não pode ser desfeita.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onRemove();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.sm),

          // Texto da pergunta
          TextFormField(
            initialValue: question['text'] as String? ?? '',
            onChanged: (value) => onUpdate('text', value),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Digite a pergunta...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: AppSizes.sm),

          // Checkboxes
          Row(
            children: [
              // Obrigatória
              Checkbox(
                value: question['required'] as bool? ?? true,
                onChanged: (value) => onUpdate('required', value ?? true),
              ),
              const Text('Obrigatória', style: TextStyle(fontSize: 13)),

              const SizedBox(width: AppSizes.md),

              // Item crítico
              Checkbox(
                value: question['is_critical'] as bool? ?? false,
                onChanged: (value) => onUpdate('is_critical', value ?? false),
              ),
              const Text('Item crítico', style: TextStyle(fontSize: 13)),
            ],
          ),

          // Threshold (se crítico)
          if (question['is_critical'] == true)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: AppSizes.sm),
              child: Row(
                children: [
                  const Text('Threshold: ', style: TextStyle(fontSize: 13)),
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      initialValue:
                          (question['alert_threshold'] ?? 1).toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final v = int.tryParse(value);
                        if (v != null) onUpdate('alert_threshold', v);
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      '≥ este valor dispara alerta',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
