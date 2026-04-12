// lib/features/patient/screens/answer_scale_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';
import '../../../models/scale_assignment_model.dart';
import '../../../models/scale_template_model.dart';
import '../../../models/scale_response_model.dart';
import '../../../models/custom_scale_model.dart';
import '../../../providers/scale_assignments_provider.dart';
import '../../../providers/scale_templates_provider.dart';
import '../../../providers/custom_scales_provider.dart';
import '../../../providers/scale_responses_provider.dart';
import '../../../providers/patient_provider.dart';
import '../../../core/supabase/supabase_service.dart';

// ═══════════════════════════════════════════════════════
// ANSWER SCALE SCREEN
// Tela onde o paciente responde uma escala atribuída
// ═══════════════════════════════════════════════════════

class AnswerScaleScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const AnswerScaleScreen({
    super.key,
    required this.assignmentId,
  });

  @override
  ConsumerState<AnswerScaleScreen> createState() => _AnswerScaleScreenState();
}

class _AnswerScaleScreenState extends ConsumerState<AnswerScaleScreen>
    with SingleTickerProviderStateMixin {
  // ══════════════════════════════════════
  // STATE
  // ══════════════════════════════════════
  ScaleAssignmentModel? _assignment;
  ScaleTemplateModel? _template;
  CustomScaleModel? _customScale;
  bool _loading = true;
  String? _error;

  int _currentQuestionIndex = 0;
  final Map<String, int> _answers = {};
  late AnimationController _animationController;
  late Animation<double> _animation;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    Future.microtask(() => _loadScale());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════
  // CARREGAR ESCALA
  // ══════════════════════════════════════
  Future<void> _loadScale() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // 1. Carregar assignment
      final assignmentNotifier =
          ref.read(scaleAssignmentsProvider.notifier);

      // Busca assignment do banco
      final client = SupabaseService.client;
      final assignmentData = await client
          .from('scale_assignments')
          .select()
          .eq('id', widget.assignmentId)
          .maybeSingle();

      if (assignmentData == null) {
        setState(() {
          _error = 'Escala não encontrada';
          _loading = false;
        });
        return;
      }

      _assignment = ScaleAssignmentModel.fromJson(assignmentData);

      // 2. Carregar template ou custom scale
      if (_assignment!.isTemplate) {
        final templateId = _assignment!.scaleTemplateId!;
        _template = await ref
            .read(scaleTemplatesProvider.notifier)
            .getTemplateById(templateId);

        if (_template == null) {
          // Carrega todos os templates
          await ref
              .read(scaleTemplatesProvider.notifier)
              .loadTemplates();
          _template = ref
              .read(scaleTemplatesProvider)
              .getTemplateById(templateId);
        }
      } else {
        _customScale = await ref
            .read(customScalesProvider.notifier)
            .getScaleById(_assignment!.customScaleId!);
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar escala: $e';
        _loading = false;
      });
    }
  }

  // ══════════════════════════════════════
  // GETTERS
  // ══════════════════════════════════════
  List<ScaleQuestion> get _questions {
    return _template?.questions ?? _customScale?.questions ?? [];
  }

  List<ResponseOption> get _responseOptions {
    return _template?.responseOptions ??
        _customScale?.responseOptions ??
        [];
  }

  String get _scaleName {
    return _template?.name ?? _customScale?.name ?? 'Escala';
  }

  String get _instructions {
    return _template?.instructions ??
        _customScale?.instructions ??
        'Responda as perguntas abaixo:';
  }

  ScoringConfig get _scoring {
    return _template?.scoring ??
        _customScale?.scoring ??
        ScoringConfig(
          maxScore: 100,
          severityRanges: [],
        );
  }

  List<Subscale> get _subscales {
    return _template?.subscales ?? _customScale?.subscales ?? [];
  }

  bool get _hasQuestions => _questions.isNotEmpty;

  ScaleQuestion get _currentQuestion => _questions[_currentQuestionIndex];

  bool get _isFirstQuestion => _currentQuestionIndex == 0;

  bool get _isLastQuestion =>
      _currentQuestionIndex == _questions.length - 1;

  double get _progress {
    if (_questions.isEmpty) return 0;
    return (_currentQuestionIndex + 1) / _questions.length;
  }

  // ══════════════════════════════════════
  // NAVEGAÇÃO
  // ══════════════════════════════════════
  void _nextQuestion() {
    if (_isLastQuestion) {
      _submitResponse();
    } else {
      _animationController.reset();
      setState(() => _currentQuestionIndex++);
      _animationController.forward();
    }
  }

  void _previousQuestion() {
    if (!_isFirstQuestion) {
      _animationController.reset();
      setState(() => _currentQuestionIndex--);
      _animationController.forward();
    }
  }

  bool _canAdvance() {
    if (!_currentQuestion.required) return true;
    return _answers.containsKey(_currentQuestion.id);
  }

  // ══════════════════════════════════════
  // SUBMETER RESPOSTA
  // ══════════════════════════════════════
  Future<void> _submitResponse() async {
    if (_assignment == null) return;

    // Calcular duração
    final durationSeconds = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : null;

    // Montar objeto de scoring
    final scoringJson = _template?.scoring.toJson() ??
        _customScale?.scoring.toJson() ??
        {};

    final success = await ref
        .read(scaleResponsesProvider.notifier)
        .submitResponseAuto(
          assignmentId: widget.assignmentId,
          patientId: _assignment!.patientId,
          answers: _answers,
          scaleScoring: scoringJson,
          questions: _questions,
          subscales: _subscales,
          durationSeconds: durationSeconds,
        );

    if (!mounted) return;

    if (success) {
      // Verificar se há itens críticos
      final response =
          ref.read(scaleResponsesProvider).latestResponse;
      final hasCritical = response?.isCritical ?? false;

      debugPrint('=== APÓS RESPOSTA ENVIADA ===');
      debugPrint('Has Critical: $hasCritical');
      debugPrint('Assignment ID: ${_assignment!.id}');
      debugPrint('Patient ID: ${_assignment!.patientId}');

      // O assignment já foi atualizado pelo submitResponse
      // Verificar o estado do assignment
      final client = SupabaseService.client;
      final updatedAssignment = await client
          .from('scale_assignments')
          .select()
          .eq('id', _assignment!.id)
          .maybeSingle();

      if (updatedAssignment != null) {
        debugPrint('=== ESTADO DO ASSIGNMENT APÓS ATUALIZAÇÃO ===');
        debugPrint('Status: ${updatedAssignment['status']}');
        debugPrint('lastCompletedAt: ${updatedAssignment['last_completed_at']}');
        debugPrint('nextDueDate: ${updatedAssignment['next_due_date']}');
        debugPrint('frequency: ${updatedAssignment['frequency']}');
      } else {
        debugPrint('⚠️ Assignment não encontrado após resposta!');
      }

      // Forçar refresh das escalas pendentes ANTES de navegar
      await ref
          .read(scaleAssignmentsProvider.notifier)
          .loadPendingForPatient(_assignment!.patientId);

      if (context.mounted) {
        context.go(
          '/app/scale-completed',
          extra: {
            'hasCritical': hasCritical,
            'scaleName': _scaleName,
          },
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(scaleResponsesProvider).error ??
                  'Erro ao enviar resposta',
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
        title: Text(_scaleName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.md),
            child: Text(
              '${_currentQuestionIndex + 1}/${_questions.length}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : !_hasQuestions
                  ? _buildNoQuestions()
                  : _buildQuestion(),
    );
  }

  // ══════════════════════════════════════
  // ERROR VIEW
  // ══════════════════════════════════════
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              _error ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // NO QUESTIONS
  // ══════════════════════════════════════
  Widget _buildNoQuestions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Esta escala não possui perguntas',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // QUESTION VIEW
  // ══════════════════════════════════════
  Widget _buildQuestion() {
    return Column(
      children: [
        // ══════════════════════════════════════
        // PROGRESS BAR
        // ══════════════════════════════════════
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: AppColors.surfaceVariant,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),

        // ══════════════════════════════════════
        // CONTEÚDO
        // ══════════════════════════════════════
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instruções (só mostra na primeira pergunta)
                if (_currentQuestionIndex == 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              'Instruções',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          _instructions,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                ],

                // ══════════════════════════════════════
                // PERGUNTA
                // ══════════════════════════════════════
                FadeTransition(
                  opacity: _animation,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Número da pergunta
                      Text(
                        'Pergunta ${_currentQuestionIndex + 1} de ${_questions.length}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: AppSizes.sm),

                      // Destaque para item crítico
                      if (_currentQuestion.isCritical)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Item importante',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: AppSizes.md),

                      // Texto da pergunta
                      Text(
                        _currentQuestion.text,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xl),

                      // ══════════════════════════════════════
                      // OPÇÕES DE RESPOSTA
                      // ══════════════════════════════════════
                      ..._responseOptions.map((option) {
                        final isSelected =
                            _answers[_currentQuestion.id] ==
                                option.value;

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSizes.sm,
                          ),
                          child: _buildOption(option, isSelected),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ══════════════════════════════════════
        // BOTÕES DE NAVEGAÇÃO
        // ══════════════════════════════════════
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Botão Anterior
              if (!_isFirstQuestion)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previousQuestion,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Anterior'),
                  ),
                ),
              if (!_isFirstQuestion)
                const SizedBox(width: AppSizes.sm),

              // Botão Próximo/Finalizar
              Expanded(
                flex: _isFirstQuestion ? 1 : 2,
                child: ElevatedButton.icon(
                  onPressed: _canAdvance() ? _nextQuestion : null,
                  icon: Icon(
                    _isLastQuestion
                        ? Icons.check_rounded
                        : Icons.arrow_forward,
                    size: 18,
                  ),
                  label: Text(
                    _isLastQuestion ? 'Finalizar' : 'Próxima',
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
  // OPÇÃO DE RESPOSTA (Radio Button Grande)
  // ══════════════════════════════════════
  Widget _buildOption(ResponseOption option, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _answers[_currentQuestion.id] = option.value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSizes.md),
            // Label
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // CONFIRMAR SAÍDA
  // ══════════════════════════════════════
  Future<void> _confirmExit(BuildContext context) async {
    final answered = _answers.length;
    final total = _questions.length;

    if (answered > 0 && answered < total) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sair da escala?'),
          content: Text(
            'Você respondeu $answered de $total perguntas. '
            'Seu progresso será perdido.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair'),
            ),
          ],
        ),
      );

      if (shouldExit == true && context.mounted) {
        context.pop();
      }
    } else {
      if (context.mounted) {
        context.pop();
      }
    }
  }
}
