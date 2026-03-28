// lib/features/patient/widgets/journaling_form.dart

import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../config/constants/app_constants.dart';

class JournalingForm extends StatefulWidget {
  final String? prompt;
  final int? minWords;
  final Function(Map<String, dynamic> result) onComplete;

  const JournalingForm({
    super.key,
    this.prompt,
    this.minWords,
    required this.onComplete,
  });

  @override
  State<JournalingForm> createState() => _JournalingFormState();
}

class _JournalingFormState extends State<JournalingForm> {
  final _entryController = TextEditingController();
  final _focusNode = FocusNode();

  String? _selectedMood;
  DateTime? _startTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _entryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _wordCount {
    final text = _entryController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  bool get _canSubmit {
    if (_entryController.text.trim().isEmpty) return false;
    if (widget.minWords != null && _wordCount < widget.minWords!) return false;
    return true;
  }

  void _submit() {
    if (!_canSubmit || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : null;

    widget.onComplete({
      'entry': _entryController.text.trim(),
      'prompt': widget.prompt,
      'mood': _selectedMood,
      'word_count': _wordCount,
      'duration_seconds': duration,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ══════════════════════════════════════
        // PROMPT (se houver)
        // ══════════════════════════════════════
        if (widget.prompt != null && widget.prompt!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: AppColors.primaryLight.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.format_quote,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      'Reflexão sugerida',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  widget.prompt!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
        ],

        // ══════════════════════════════════════
        // MOOD SELECTOR (opcional)
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Como você está se sentindo agora?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...['😢', '😟', '😐', '🙂', '😊'].asMap().entries.map((e) {
                      final emoji = e.value;
                      final isSelected = _selectedMood == emoji;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSizes.sm),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMood = emoji),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? null
                                  : Border.all(color: Colors.grey.shade200),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.md),

        // ══════════════════════════════════════
        // TEXT AREA
        // ══════════════════════════════════════
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Expanded(
                  child: TextField(
                    controller: _entryController,
                    focusNode: _focusNode,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Comece a escrever...\n\n'
                          'Deixe seus pensamentos fluírem livremente. '
                          'Não se preocupe com gramática ou estrutura.',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppSizes.md),
                      hintStyle: TextStyle(
                        color: AppColors.textLight.withOpacity(0.5),
                        height: 1.6,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),
                ),

                // Word counter
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppSizes.radiusLg),
                      bottomRight: Radius.circular(AppSizes.radiusLg),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.text_fields,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_wordCount palavras',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getWordCountColor(),
                                    ),
                          ),
                        ],
                      ),
                      if (widget.minWords != null)
                        Text(
                          'Mínimo: ${widget.minWords} palavras',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSizes.md),

        // ══════════════════════════════════════
        // TIPS
        // ══════════════════════════════════════
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.infoLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: 6),
                  Text(
                    'Dicas para seu diário',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                '• Escreva sem julgamentos\n'
                '• Não existe certo ou errado\n'
                '• Seja honesto(a) consigo mesmo(a)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.md),

        // ══════════════════════════════════════
        // SUBMIT BUTTON
        // ══════════════════════════════════════
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canSubmit ? _submit : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Salvar no Diário'),
          ),
        ),
      ],
    );
  }

  Color _getWordCountColor() {
    if (widget.minWords == null) return AppColors.textSecondary;
    if (_wordCount >= widget.minWords!) return AppColors.success;
    if (_wordCount >= widget.minWords! * 0.5) return AppColors.warning;
    return AppColors.textLight;
  }
}