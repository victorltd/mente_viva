// lib/features/psychologist/screens/create_custom_scale_screen.dart

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
// CREATE CUSTOM SCALE SCREEN
// Criação do zero (sem base em template)
// ═══════════════════════════════════════════════════════

class CreateCustomScaleScreen extends ConsumerStatefulWidget {
  final String patientId;

  const CreateCustomScaleScreen({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<CreateCustomScaleScreen> createState() =>
      _CreateCustomScaleScreenState();
}

class _CreateCustomScaleScreenState
    extends ConsumerState<CreateCustomScaleScreen> {
  // ══════════════════════════════════════
  // STATE
  // ══════════════════════════════════════
  String _name = '';
  String _instructions = '';
  String _description = '';
  final List<Map<String, dynamic>> _questions = [];
  final List<Map<String, dynamic>> _responseOptions = [
    {'value': 0, 'label': 'Nunca'},
    {'value': 1, 'label': 'Às vezes'},
    {'value': 2, 'label': 'Frequentemente'},
    {'value': 3, 'label': 'Sempre'},
  ];
  bool _isSaving = false;

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
      for (int i = 0; i < _questions.length; i++) {
        _questions[i]['order'] = i + 1;
      }
    });
  }

  // ══════════════════════════════════════
  // CRUD OPÇÕES DE RESPOSTA
  // ══════════════════════════════════════
  void _addResponseOption() {
    setState(() {
      _responseOptions.add({
        'value': _responseOptions.length,
        'label': '',
      });
    });
  }

  void _removeResponseOption(int index) {
    if (_responseOptions.length <= 2) return;
    setState(() {
      _responseOptions.removeAt(index);
      for (int i = 0; i < _responseOptions.length; i++) {
        _responseOptions[i]['value'] = i;
      }
    });
  }

  void _updateResponseOption(int index, String value) {
    setState(() {
      _responseOptions[index]['label'] = value;
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

    final hasEmptyQuestion =
        _questions.any((q) => q['text'].toString().trim().isEmpty);
    if (hasEmptyQuestion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas as perguntas devem ter texto'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final hasEmptyOption = _responseOptions.any((o) =>
        o['label'].toString().trim().isEmpty);
    if (hasEmptyOption) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas as opções de resposta devem ter texto'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final psychologistId = SupabaseService.currentUserId!;

    final maxScore = (_questions.length) *
        ((_responseOptions.length - 1));

    final questions = _questions
        .map((q) => ScaleQuestion.fromJson(q))
        .toList();

    final responseOpts = _responseOptions
        .map((r) => ResponseOption.fromJson(r))
        .toList();

    final scoringConfig = ScoringConfig(
      maxScore: maxScore,
      severityRanges: [
        SeverityRange(
          min: 0,
          max: (maxScore * 0.2).round(),
          level: 'minimal',
          label: 'Mínimo',
          color: '#10B981',
        ),
        SeverityRange(
          min: (maxScore * 0.2).round() + 1,
          max: (maxScore * 0.4).round(),
          level: 'mild',
          label: 'Leve',
          color: '#F59E0B',
        ),
        SeverityRange(
          min: (maxScore * 0.4).round() + 1,
          max: (maxScore * 0.6).round(),
          level: 'moderate',
          label: 'Moderado',
          color: '#F97316',
        ),
        SeverityRange(
          min: (maxScore * 0.6).round() + 1,
          max: maxScore,
          level: 'severe',
          label: 'Grave',
          color: '#EF4444',
        ),
      ],
    );

    final customScale = CustomScaleModel(
      id: '',
      psychologistId: psychologistId,
      name: _name.trim(),
      description: _description.trim().isEmpty ? null : _description.trim(),
      instructions: _instructions.trim(),
      responseOptions: responseOpts,
      questions: questions,
      scoring: scoringConfig,
      isValidated: false,
      isDraft: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(customScalesProvider.notifier)
        .createScale(customScale);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escala criada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(customScalesProvider).error ??
                  'Erro ao criar escala',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════
  // PREVIEW
  // ══════════════════════════════════════
  void _showPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_name.isEmpty ? 'Pré-visualização' : _name),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_instructions.isNotEmpty) ...[
                  Text(
                    'Instruções:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(_instructions),
                  const SizedBox(height: AppSizes.md),
                ],
                Text(
                  'Opções de resposta:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                ..._responseOptions.map((o) => Text('• ${o['label']}')),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Perguntas (${_questions.length}):',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                ..._questions.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${e.key + 1}. ${e.value['text']}',
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Escala Personalizada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: _showPreview,
            tooltip: 'Pré-visualizar',
          ),
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
            // NOME
            // ══════════════════════════════════════
            Text(
              'Nome da Escala *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextFormField(
              onChanged: (value) => _name = value,
              decoration: const InputDecoration(
                hintText: 'Ex: Escala de Ansiedade Diária',
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // ══════════════════════════════════════
            // DESCRIÇÃO
            // ══════════════════════════════════════
            Text(
              'Descrição (opcional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextFormField(
              onChanged: (value) => _description = value,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Breve descrição da escala...',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // ══════════════════════════════════════
            // INSTRUÇÕES
            // ══════════════════════════════════════
            Text(
              'Instruções *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextFormField(
              onChanged: (value) => _instructions = value,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Instruções para o paciente...',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // ══════════════════════════════════════
            // OPÇÕES DE RESPOSTA
            // ══════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Opções de Resposta',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: _addResponseOption,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Opção'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            ..._responseOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Row(
                  children: [
                    Text(
                      '${option['value']}: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: option['label'] as String? ?? '',
                        onChanged: (value) =>
                            _updateResponseOption(index, value),
                        decoration: InputDecoration(
                          hintText: 'Rótulo da opção...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: AppSizes.sm,
                          ),
                        ),
                      ),
                    ),
                    if (_responseOptions.length > 2)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: AppColors.error),
                        onPressed: () => _removeResponseOption(index),
                      ),
                  ],
                ),
              );
            }).toList(),

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
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),

            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;

              return _QuestionEditorCard(
                index: index,
                question: question,
                totalQuestions: _questions.length,
                onUpdate: (key, value) => _updateQuestion(index, key, value),
                onRemove: () => _removeQuestion(index),
                onMoveUp:
                    index > 0 ? () => _moveQuestion(index, -1) : null,
                onMoveDown: index < _questions.length - 1
                    ? () => _moveQuestion(index, 1)
                    : null,
              );
            }).toList(),

            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// QUESTION EDITOR CARD
// ═══════════════════════════════════════════════════════

class _QuestionEditorCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final int totalQuestions;
  final Function(String, dynamic) onUpdate;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _QuestionEditorCard({
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
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.secondary,
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
                icon: const Icon(Icons.delete_outline, size: 20,
                    color: AppColors.error),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
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
          Row(
            children: [
              Checkbox(
                value: question['required'] as bool? ?? true,
                onChanged: (value) => onUpdate('required', value ?? true),
              ),
              const Text('Obrigatória', style: TextStyle(fontSize: 13)),
              const SizedBox(width: AppSizes.md),
              Checkbox(
                value: question['is_critical'] as bool? ?? false,
                onChanged: (value) =>
                    onUpdate('is_critical', value ?? false),
              ),
              const Text('Item crítico', style: TextStyle(fontSize: 13)),
            ],
          ),
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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      '≥ este valor dispara alerta',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
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
