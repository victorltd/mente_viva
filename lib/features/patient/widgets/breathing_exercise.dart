// lib/features/patient/widgets/breathing_exercise.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';

class BreathingExercise extends StatefulWidget {
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int totalCycles;
  final Function(Map<String, dynamic> result) onComplete;

  const BreathingExercise({
    super.key,
    this.inhaleSeconds = 4,
    this.holdSeconds = 4,
    this.exhaleSeconds = 4,
    this.totalCycles = 5,
    required this.onComplete,
  });

  @override
  State<BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<BreathingExercise>
    with TickerProviderStateMixin {
  // ══════════════════════════════════════
  // STATE
  // ══════════════════════════════════════
  late AnimationController _breathController;
  late AnimationController _pulseController;
  late Animation<double> _breathAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _phaseTimer;
  Timer? _countdownTimer;

  bool _isRunning = false;
  bool _isCompleted = false;
  int _currentCycle = 0;
  int _countdown = 0;
  BreathingPhase _currentPhase = BreathingPhase.ready;
  DateTime? _startTime;

  // Feeling after (1-5)
  int _feelingAfter = 3;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Animação principal de respiração
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.inhaleSeconds),
    );

    _breathAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Animação de pulso sutil
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════
  // BREATHING LOGIC
  // ══════════════════════════════════════
  void _startExercise() {
    setState(() {
      _isRunning = true;
      _currentCycle = 1;
      _startTime = DateTime.now();
    });

    HapticFeedback.mediumImpact();
    _startPhase(BreathingPhase.inhale);
  }

  void _startPhase(BreathingPhase phase) {
    setState(() {
      _currentPhase = phase;
    });

    int duration;
    switch (phase) {
      case BreathingPhase.inhale:
        duration = widget.inhaleSeconds;
        _breathController.duration = Duration(seconds: duration);
        _breathController.forward(from: 0);
        break;
      case BreathingPhase.hold:
        duration = widget.holdSeconds;
        break;
      case BreathingPhase.exhale:
        duration = widget.exhaleSeconds;
        _breathController.duration = Duration(seconds: duration);
        _breathController.reverse(from: 1);
        break;
      default:
        return;
    }

    // Countdown
    _countdown = duration;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });

    // Próxima fase
    _phaseTimer?.cancel();
    _phaseTimer = Timer(Duration(seconds: duration), () {
      _nextPhase();
    });

    // Haptic no início de cada fase
    HapticFeedback.lightImpact();
  }

  void _nextPhase() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        if (widget.holdSeconds > 0) {
          _startPhase(BreathingPhase.hold);
        } else {
          _startPhase(BreathingPhase.exhale);
        }
        break;
      case BreathingPhase.hold:
        _startPhase(BreathingPhase.exhale);
        break;
      case BreathingPhase.exhale:
        if (_currentCycle < widget.totalCycles) {
          setState(() => _currentCycle++);
          _startPhase(BreathingPhase.inhale);
        } else {
          _completeExercise();
        }
        break;
      default:
        break;
    }
  }

  void _completeExercise() {
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();

    setState(() {
      _isRunning = false;
      _isCompleted = true;
      _currentPhase = BreathingPhase.completed;
    });

    HapticFeedback.heavyImpact();
  }

  void _submitResult() {
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : null;

    widget.onComplete({
      'cycles': widget.totalCycles,
      'pattern':
          '${widget.inhaleSeconds}-${widget.holdSeconds}-${widget.exhaleSeconds}',
      'feeling_after': _feelingAfter,
      'duration_seconds': duration,
      'completed': true,
    });
  }

  void _pauseExercise() {
    _phaseTimer?.cancel();
    _countdownTimer?.cancel();
    _breathController.stop();

    setState(() {
      _isRunning = false;
    });
  }

  void _resumeExercise() {
    setState(() {
      _isRunning = true;
    });

    // Retomar a fase atual
    _startPhase(_currentPhase);
  }

  // ══════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionView();
    }

    return Column(
      children: [
        // ══════════════════════════════════════
        // PROGRESS
        // ══════════════════════════════════════
        if (_isRunning || _currentCycle > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.totalCycles, (index) {
                final cycleNum = index + 1;
                final isCompleted = cycleNum < _currentCycle;
                final isCurrent = cycleNum == _currentCycle;

                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.success
                        : isCurrent
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                    border: isCurrent
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                );
              }),
            ),
          ),

        // ══════════════════════════════════════
        // BREATHING CIRCLE
        // ══════════════════════════════════════
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_breathAnimation, _pulseAnimation]),
              builder: (context, child) {
                final scale = _isRunning
                    ? _breathAnimation.value * _pulseAnimation.value
                    : 0.5 * _pulseAnimation.value;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _getPhaseColor().withOpacity(0.3),
                          _getPhaseColor().withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: _getPhaseColor(),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getPhaseColor().withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getPhaseEmoji(),
                            style: const TextStyle(fontSize: 40),
                          ),
                          if (_isRunning) ...[
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              '$_countdown',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: _getPhaseColor(),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ══════════════════════════════════════
        // PHASE LABEL
        // ══════════════════════════════════════
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: _getPhaseColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(
            _getPhaseLabel(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _getPhaseColor(),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),

        const SizedBox(height: AppSizes.lg),

        // ══════════════════════════════════════
        // CONTROLS
        // ══════════════════════════════════════
        if (!_isRunning && _currentPhase == BreathingPhase.ready)
          _buildStartButton()
        else if (_isRunning)
          _buildPauseButton()
        else
          _buildResumeButtons(),

        const SizedBox(height: AppSizes.md),

        // ══════════════════════════════════════
        // INFO
        // ══════════════════════════════════════
        Text(
          'Padrão: ${widget.inhaleSeconds}s inspirar • '
          '${widget.holdSeconds}s segurar • '
          '${widget.exhaleSeconds}s expirar',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startExercise,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar Exercício'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        ),
      ),
    );
  }

  Widget _buildPauseButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _pauseExercise,
        icon: const Icon(Icons.pause),
        label: const Text('Pausar'),
      ),
    );
  }

  Widget _buildResumeButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _currentCycle = 0;
                _currentPhase = BreathingPhase.ready;
              });
            },
            child: const Text('Reiniciar'),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _resumeExercise,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Continuar'),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // COMPLETION VIEW
  // ══════════════════════════════════════
  Widget _buildCompletionView() {
    return Column(
      children: [
        const Spacer(),

        // Success icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successLight,
          ),
          child: const Center(
            child: Text('🧘', style: TextStyle(fontSize: 56)),
          ),
        ),

        const SizedBox(height: AppSizes.lg),

        Text(
          'Exercício Completo!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.success,
              ),
        ),

        const SizedBox(height: AppSizes.xs),

        Text(
          '${widget.totalCycles} ciclos de respiração',
          style: Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: AppSizes.xl),

        // Feeling rating
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
              Text(
                'Como você se sente agora?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  final isSelected = _feelingAfter == value;
                  return GestureDetector(
                    onTap: () => setState(() => _feelingAfter = value),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getFeelingEmoji(value),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitResult,
            child: const Text('Concluir'),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  Color _getPhaseColor() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return AppColors.info;
      case BreathingPhase.hold:
        return AppColors.warning;
      case BreathingPhase.exhale:
        return AppColors.secondary;
      case BreathingPhase.completed:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _getPhaseLabel() {
    switch (_currentPhase) {
      case BreathingPhase.ready:
        return 'Preparado?';
      case BreathingPhase.inhale:
        return 'Inspire';
      case BreathingPhase.hold:
        return 'Segure';
      case BreathingPhase.exhale:
        return 'Expire';
      case BreathingPhase.completed:
        return 'Completo!';
    }
  }

  String _getPhaseEmoji() {
    switch (_currentPhase) {
      case BreathingPhase.ready:
        return '🫁';
      case BreathingPhase.inhale:
        return '💨';
      case BreathingPhase.hold:
        return '⏸️';
      case BreathingPhase.exhale:
        return '😮‍💨';
      case BreathingPhase.completed:
        return '✨';
    }
  }

  String _getFeelingEmoji(int value) {
    switch (value) {
      case 1:
        return '😣';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '😌';
      case 5:
        return '😊';
      default:
        return '😐';
    }
  }
}

// ══════════════════════════════════════
// ENUM
// ══════════════════════════════════════
enum BreathingPhase {
  ready,
  inhale,
  hold,
  exhale,
  completed,
}