// lib/features/patient/screens/checkin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../config/constants/app_constants.dart';
import '../../../providers/checkin_provider.dart';
import '../../../core/widgets/confidentiality_notice.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/achievement_provider.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  int _currentStep = 0;
  int? _selectedMood;
  String? _selectedEmotion;
  int _energyLevel = 3;
  int _sleepQuality = 3;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Future<void> _submit() async {
  //   final patientState = ref.read(patientProvider);
  //   if (patientState.patient == null) return;

  //   final success = await ref.read(checkinProvider.notifier).submitCheckin(
  //         patientId: patientState.patient!.id,
  //         moodScore: _selectedMood!,
  //         primaryEmotion: _selectedEmotion!,
  //         energyLevel: _energyLevel,
  //         sleepQuality: _sleepQuality,
  //         notes: _notesController.text.trim().isEmpty
  //             ? null
  //             : _notesController.text.trim(),
  //       );

  //   if (success && mounted) {
  //     setState(() => _currentStep = 4); // Tela de sucesso
  //   }
  // }

    Future<void> _submit() async {
    final patientState = ref.read(patientProvider);
    
    // DEBUG
    debugPrint('=== DEBUG CHECKIN ===');
    debugPrint('Patient state loading: ${patientState.isLoading}');
    debugPrint('Patient: ${patientState.patient}');
    debugPrint('Patient ID: ${patientState.patient?.id}');
    debugPrint('Patient error: ${patientState.error}');
    debugPrint('Mood: $_selectedMood');
    debugPrint('Emotion: $_selectedEmotion');
    debugPrint('====================');

    if (patientState.patient == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: dados do paciente não encontrados'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final success = await ref.read(checkinProvider.notifier).submitCheckin(
          patientId: patientState.patient!.id,
          moodScore: _selectedMood!,
          primaryEmotion: _selectedEmotion!,
          energyLevel: _energyLevel,
          sleepQuality: _sleepQuality,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    // DEBUG
    debugPrint('=== RESULTADO ===');
    debugPrint('Success: $success');
    debugPrint('Checkin error: ${ref.read(checkinProvider).error}');
    debugPrint('=================');

    if (success && patientState.patient != null) {
      // Verificar conquistas
      final checkins = ref.read(checkinProvider).checkins;
      final tasks = ref.read(taskProvider).tasks;

      await ref.read(achievementProvider.notifier).checkAndUnlockAchievements(
        patientId: patientState.patient!.id,
        checkins: checkins,
        tasks: tasks,
      );

      setState(() => _currentStep = 4);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(checkinProvider).error ?? 'Erro ao registrar',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep < 4 ? 'Check-in Emocional' : ''),
        leading: _currentStep < 4
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ConfidentialityNotice(isCompact: true),
            const SizedBox(height: AppSizes.md),
            // ══════════════════════════════════════
            // PROGRESSO
            // ══════════════════════════════════════
            if (_currentStep < 4)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.sm,
                ),
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // ══════════════════════════════════════
            // CONTEÚDO
            // ══════════════════════════════════════
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: _buildCurrentStep(),
              ),
            ),

            // ══════════════════════════════════════
            // BOTÕES
            // ══════════════════════════════════════
            if (_currentStep < 4)
              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _currentStep--);
                          },
                          child: const Text('Voltar'),
                        ),
                      ),
                    if (_currentStep > 0)
                      const SizedBox(width: AppSizes.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _canAdvance() ? _handleNext : null,
                        child: Text(
                          _currentStep < 3 ? 'Próximo' : 'Registrar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canAdvance() {
    switch (_currentStep) {
      case 0:
        return _selectedMood != null;
      case 1:
        return _selectedEmotion != null;
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _handleNext() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildMoodStep();
      case 1:
        return _buildEmotionStep();
      case 2:
        return _buildEnergyStep();
      case 3:
        return _buildNotesStep();
      case 4:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
  }

  // ══════════════════════════════════════
  // STEP 0: HUMOR
  // ══════════════════════════════════════
  Widget _buildMoodStep() {
    return Column(
      children: [
        const SizedBox(height: AppSizes.xl),
        Text(
          'Como você está\nse sentindo agora?',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.xxl),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (index) {
              final score = index + 1;
              final isSelected = _selectedMood == score;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedMood = score);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.moodColor(score).withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.moodColor(score)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          AppConstants.moodEmojis[score]!,
                          style: TextStyle(
                            fontSize: isSelected ? 40 : 32,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          AppConstants.moodLabels[score]!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? AppColors.moodColor(score)
                                    : AppColors.textLight,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // STEP 1: EMOÇÃO
  // ══════════════════════════════════════
  Widget _buildEmotionStep() {
    return Column(
      children: [
        const SizedBox(height: AppSizes.xl),
        Text(
          'Qual emoção principal\nvocê está sentindo?',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.xxl),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: AppSizes.sm,
            mainAxisSpacing: AppSizes.sm,
          ),
          itemCount: AppConstants.emotions.length,
          itemBuilder: (context, index) {
            final emotion = AppConstants.emotions[index];
            final isSelected = _selectedEmotion == emotion['key'];
            final color = AppColors.emotions[emotion['key']] ??
                AppColors.textLight;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedEmotion = emotion['key']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.1)
                      : AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      emotion['emoji']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      emotion['label']!,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            color: isSelected
                                ? color
                                : AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // STEP 2: ENERGIA + SONO
  // ══════════════════════════════════════
  Widget _buildEnergyStep() {
    return Column(
      children: [
        const SizedBox(height: AppSizes.xl),
        Text(
          'Como está sua\nenergia e sono?',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.xxl),

        // Energia
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt, color: AppColors.warning),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Nível de Energia',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔋', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    _energyLabel(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              Slider(
                value: _energyLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: AppColors.warning,
                onChanged: (value) {
                  setState(() => _energyLevel = value.round());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sem energia',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text('Muita energia',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.lg),

        // Sono
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bedtime, color: AppColors.info),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Qualidade do Sono',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final score = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _sleepQuality = score);
                    },
                    child: Column(
                      children: [
                        Icon(
                          score <= _sleepQuality
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 36,
                          color: score <= _sleepQuality
                              ? AppColors.warning
                              : AppColors.textLight,
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                _sleepLabel(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // STEP 3: NOTAS
  // ══════════════════════════════════════
  Widget _buildNotesStep() {
    return Column(
      children: [
        const SizedBox(height: AppSizes.xl),
        Text(
          'Quer contar algo\nsobre como se sente?',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Isso é opcional, mas ajuda seu psicólogo a te entender melhor.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.xl),
        TextFormField(
          controller: _notesController,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Escreva aqui o que quiser...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        // Resumo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          child: Column(
            children: [
              Text(
                'Resumo do check-in',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResumoItem(
                    AppConstants.moodEmojis[_selectedMood]!,
                    AppConstants.moodLabels[_selectedMood]!,
                  ),
                  _buildResumoItem(
                    AppConstants.emotions.firstWhere(
                        (e) => e['key'] == _selectedEmotion)['emoji']!,
                    AppConstants.emotions.firstWhere(
                        (e) => e['key'] == _selectedEmotion)['label']!,
                  ),
                  _buildResumoItem(
                    '🔋',
                    _energyLabel(),
                  ),
                  _buildResumoItem(
                    '⭐',
                    '$_sleepQuality/5',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // STEP 4: SUCESSO
  // ══════════════════════════════════════
  Widget _buildSuccessStep() {
    final checkinState = ref.watch(checkinProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSizes.xxl),
          Container(
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 64,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            'Check-in registrado! ✅',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),

          // Streak
          if (checkinState.streak > 1)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    '${checkinState.streak} dias seguidos!',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.warning),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSizes.md),

          // Estatísticas rápidas
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '${checkinState.totalDays}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                    Text(
                      'dias registrados',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                Column(
                  children: [
                    Text(
                      checkinState.averageMood.toStringAsFixed(1),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: AppColors.secondary),
                    ),
                    Text(
                      'humor médio',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.sm),
          Text(
            'Cada registro é um passo\nna sua jornada terapêutica 💜',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xxl),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar para Home'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  Widget _buildResumoItem(String emoji, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _energyLabel() {
    switch (_energyLevel) {
      case 1: return 'Muito baixa';
      case 2: return 'Baixa';
      case 3: return 'Média';
      case 4: return 'Alta';
      case 5: return 'Muito alta';
      default: return 'Média';
    }
  }

  String _sleepLabel() {
    switch (_sleepQuality) {
      case 1: return 'Péssimo';
      case 2: return 'Ruim';
      case 3: return 'Regular';
      case 4: return 'Bom';
      case 5: return 'Excelente';
      default: return 'Regular';
    }
  }
}