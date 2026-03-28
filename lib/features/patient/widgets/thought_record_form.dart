// lib/features/patient/widgets/thought_record_form.dart

import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../config/constants/app_constants.dart';

class ThoughtRecordForm extends StatefulWidget {
  final Function(Map<String, dynamic> result) onComplete;

  const ThoughtRecordForm({super.key, required this.onComplete});

  @override
  State<ThoughtRecordForm> createState() => _ThoughtRecordFormState();
}

class _ThoughtRecordFormState extends State<ThoughtRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  int _currentStep = 0;
  final int _totalSteps = 6;

  // ══════════════════════════════════════
  // FORM DATA
  // ══════════════════════════════════════
  final _situationController = TextEditingController();
  final _automaticThoughtController = TextEditingController();
  String? _selectedEmotion;
  double _emotionIntensity = 5;
  final _evidenceForController = TextEditingController();
  final _evidenceAgainstController = TextEditingController();
  final _alternativeThoughtController = TextEditingController();
  double _newEmotionIntensity = 5;

  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _situationController.dispose();
    _automaticThoughtController.dispose();
    _evidenceForController.dispose();
    _evidenceAgainstController.dispose();
    _alternativeThoughtController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // Validação específica por step
      if (!_validateCurrentStep()) return;

      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_situationController.text.trim().isEmpty) {
          _showError('Descreva a situação');
          return false;
        }
        break;
      case 1:
        if (_automaticThoughtController.text.trim().isEmpty) {
          _showError('Descreva o pensamento');
          return false;
        }
        break;
      case 2:
        if (_selectedEmotion == null) {
          _showError('Selecione uma emoção');
          return false;
        }
        break;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _submitForm() {
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : null;

    widget.onComplete({
      'situation': _situationController.text.trim(),
      'automatic_thought': _automaticThoughtController.text.trim(),
      'emotion': _selectedEmotion,
      'emotion_intensity': _emotionIntensity.round(),
      'evidence_for': _evidenceForController.text.trim(),
      'evidence_against': _evidenceAgainstController.text.trim(),
      'alternative_thought': _alternativeThoughtController.text.trim(),
      'new_emotion_intensity': _newEmotionIntensity.round(),
      'duration_seconds': duration,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ══════════════════════════════════════
        // PROGRESS BAR
        // ══════════════════════════════════════
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.md),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Passo ${_currentStep + 1} de $_totalSteps',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    _getStepTitle(_currentStep),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        // ══════════════════════════════════════
        // FORM PAGES
        // ══════════════════════════════════════
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSituationStep(),
              _buildThoughtStep(),
              _buildEmotionStep(),
              _buildEvidenceForStep(),
              _buildEvidenceAgainstStep(),
              _buildAlternativeStep(),
            ],
          ),
        ),

        // ══════════════════════════════════════
        // NAVIGATION BUTTONS
        // ══════════════════════════════════════
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.md),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    child: const Text('Voltar'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: AppSizes.md),
              Expanded(
                flex: _currentStep > 0 ? 2 : 1,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  child: Text(
                    _currentStep == _totalSteps - 1 ? 'Concluir' : 'Próximo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // STEP 1: SITUAÇÃO
  // ══════════════════════════════════════
  Widget _buildSituationStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Qual foi a situação?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Descreva o que aconteceu, onde e quando.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.lg),
          TextField(
            controller: _situationController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText:
                  'Ex: Estava no trabalho, em uma reunião com meu chefe, quando ele criticou meu projeto na frente de todos...',
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _buildTip(
            'Seja específico sobre o contexto: quem estava presente, '
            'o que aconteceu exatamente, quando e onde foi.',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // STEP 2: PENSAMENTO AUTOMÁTICO
  // ══════════════════════════════════════
  Widget _buildThoughtStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💭', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Qual foi o pensamento?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'O que passou pela sua cabeça naquele momento?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.lg),
          TextField(
            controller: _automaticThoughtController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Ex: "Sou incompetente", "Nunca faço nada certo", "Vou ser demitido"...',
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _buildTip(
            'Pensamentos automáticos são rápidos e surgem sem esforço. '
            'Tente capturar exatamente o que pensou, mesmo que pareça irracional.',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // STEP 3: EMOÇÃO + INTENSIDADE
  // ══════════════════════════════════════
  Widget _buildEmotionStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💔', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSizes.sm),
          Text(
            'O que você sentiu?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Selecione a emoção principal e sua intensidade.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.lg),

          // Emotion selector
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: AppConstants.emotions.map((emotion) {
              final isSelected = _selectedEmotion == emotion['key'];
              return GestureDetector(
                onTap: () => setState(() => _selectedEmotion = emotion['key']),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emotion['emoji']!,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        emotion['label']!,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.lg),

          // Intensity slider
          Text(
            'Intensidade: ${_emotionIntensity.round()}/10',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSizes.sm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceVariant,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _emotionIntensity,
              min: 0,
              max: 10,
              divisions: 10,
              label: _emotionIntensity.round().toString(),
              onChanged: (value) => setState(() => _emotionIntensity = value),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Leve', style: Theme.of(context).textTheme.bodySmall),
              Text('Intensa', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // STEP 4: EVIDÊNCIAS A FAVOR
  // ══════════════════════════════════════
  Widget _buildEvidenceForStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Evidências a favor',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Quais fatos apoiam esse pensamento?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.lg),

          // Lembrete do pensamento
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                const Text('💭', style: TextStyle(fontSize: 20)),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    '"${_automaticThoughtController.text}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.md),

          TextField(
            controller: _evidenceForController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Ex: "Meu chefe realmente criticou o projeto", "Já recebi feedback negativo antes"...',
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _buildTip(
            'Liste apenas FATOS observáveis, não interpretações. '
            'O que alguém de fora veria ou ouviria?',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // STEP 5: EVIDÊNCIAS CONTRA
  // ══════════════════════════════════════
  Widget _buildEvidenceAgainstStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('❌', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Evidências contra',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Quais fatos contradizem esse pensamento?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.lg),

          // Lembrete do pensamento
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                const Text('💭', style: TextStyle(fontSize: 20)),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    '"${_automaticThoughtController.text}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.md),

          TextField(
            controller: _evidenceAgainstController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Ex: "Recebi elogios no mês passado", "Fui promovido ano passado", "Meus colegas pediram minha ajuda"...',
            ),
          ),
          const SizedBox(height: AppSizes.md),
          _buildTip(
            'Pense em exceções, conquistas passadas, ou o que um amigo diria sobre você.',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // STEP 6: PENSAMENTO ALTERNATIVO
  // ══════════════════════════════════════
  Widget _buildAlternativeStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌟', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Pensamento alternativo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Considerando as evidências, qual seria um pensamento mais equilibrado?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.lg),

          TextField(
            controller: _alternativeThoughtController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Ex: "Recebi uma crítica, mas isso não significa que sou incompetente. '
                  'Tenho pontos a melhorar e também conquistas no trabalho."',
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // New intensity
          Text(
            'Como você se sente agora? ${_newEmotionIntensity.round()}/10',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSizes.sm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.success,
              inactiveTrackColor: AppColors.surfaceVariant,
              thumbColor: AppColors.success,
              overlayColor: AppColors.success.withOpacity(0.2),
            ),
            child: Slider(
              value: _newEmotionIntensity,
              min: 0,
              max: 10,
              divisions: 10,
              label: _newEmotionIntensity.round().toString(),
              onChanged: (value) =>
                  setState(() => _newEmotionIntensity = value),
            ),
          ),

          // Comparison
          if (_emotionIntensity > _newEmotionIntensity)
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_down, color: AppColors.success),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Intensidade reduziu de ${_emotionIntensity.round()} para ${_newEmotionIntensity.round()}!',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  Widget _buildTip(String text) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Situação';
      case 1:
        return 'Pensamento';
      case 2:
        return 'Emoção';
      case 3:
        return 'Evidências a favor';
      case 4:
        return 'Evidências contra';
      case 5:
        return 'Reestruturação';
      default:
        return '';
    }
  }
}