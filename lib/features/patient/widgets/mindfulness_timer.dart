// lib/features/patient/widgets/mindfulness_timer.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_sizes.dart';

class MindfulnessTimer extends StatefulWidget {
  final int durationMinutes;
  final String? guidance;
  final Function(Map<String, dynamic> result) onComplete;

  const MindfulnessTimer({
    super.key,
    this.durationMinutes = 10,
    this.guidance,
    required this.onComplete,
  });

  @override
  State<MindfulnessTimer> createState() => _MindfulnessTimerState();
}

class _MindfulnessTimerState extends State<MindfulnessTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;

  bool _isRunning = false;
  bool _isCompleted = false;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  DateTime? _startTime;

  int _feelingAfter = 3;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
    });

    HapticFeedback.mediumImpact();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resumeTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _completeSession() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();

    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });
  }

  void _endEarly() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });
  }

  void _submitResult() {
    final actualDuration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : _totalSeconds - _remainingSeconds;

    widget.onComplete({
      'target_duration_minutes': widget.durationMinutes,
      'actual_duration_seconds': actualDuration,
      'completed_full': _remainingSeconds == 0,
      'feeling_after': _feelingAfter,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionView();
    }

    return Column(
      children: [
        // ══════════════════════════════════════
        // GUIDANCE
        // ══════════════════════════════════════
        if (widget.guidance != null && !_isRunning) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.self_improvement,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      'Orientação',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  widget.guidance!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],

        // ══════════════════════════════════════
        // TIMER CIRCLE
        // ══════════════════════════════════════
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale =
                    _isRunning ? 1.0 + (_pulseController.value * 0.05) : 1.0;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.secondary.withOpacity(0.2),
                          AppColors.secondary.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 4,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress arc
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: 1 - (_remainingSeconds / _totalSeconds),
                            strokeWidth: 8,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.secondary,
                            ),
                          ),
                        ),

                        // Time display
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_remainingSeconds),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 42,
                                  ),
                            ),
                            if (_isRunning)
                              Text(
                                'Respire...',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.secondary,
                                    ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ══════════════════════════════════════
        // BREATHING GUIDE (during session)
        // ══════════════════════════════════════
        if (_isRunning) ...[
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.air,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'Foque na sua respiração natural',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
        ],

        // ══════════════════════════════════════
        // CONTROLS
        // ══════════════════════════════════════
        if (!_isRunning && _remainingSeconds == _totalSeconds)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startTimer,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar Meditação'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              ),
            ),
          )
        else if (_isRunning)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pauseTimer,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausar'),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: TextButton(
                  onPressed: () => _showEndEarlyDialog(),
                  child: const Text(
                    'Encerrar',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _remainingSeconds = _totalSeconds;
                    });
                  },
                  child: const Text('Reiniciar'),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _resumeTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continuar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: AppSizes.md),

        // ══════════════════════════════════════
        // INFO
        // ══════════════════════════════════════
        if (!_isRunning && _remainingSeconds == _totalSeconds)
          Text(
            'Duração: ${widget.durationMinutes} minutos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  // ══════════════════════════════════════
  // COMPLETION VIEW
  // ══════════════════════════════════════
  Widget _buildCompletionView() {
    final completedFull = _remainingSeconds == 0;

    return Column(
      children: [
        const Spacer(),

        // Success icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completedFull
                ? AppColors.successLight
                : AppColors.warningLight,
          ),
          child: Center(
            child: Text(
              completedFull ? '🧘' : '⏱️',
              style: const TextStyle(fontSize: 56),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.lg),

        Text(
          completedFull ? 'Meditação Completa!' : 'Sessão Encerrada',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: completedFull ? AppColors.success : AppColors.warning,
              ),
        ),

        const SizedBox(height: AppSizes.xs),

        Text(
          completedFull
              ? '${widget.durationMinutes} minutos de prática'
              : 'Você praticou por ${_formatTime(_totalSeconds - _remainingSeconds)}',
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
                            ? AppColors.secondary
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
              const SizedBox(height: AppSizes.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Agitado',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text('Calmo', 
                      style: Theme.of(context).textTheme.bodySmall),
                ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
            ),
            child: const Text('Concluir'),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════
  void _showEndEarlyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encerrar meditação?'),
        content: Text(
          'Você ainda tem ${_formatTime(_remainingSeconds)} restantes. '
          'Deseja encerrar agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endEarly();
            },
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getFeelingEmoji(int value) {
    switch (value) {
      case 1:
        return '😰';
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