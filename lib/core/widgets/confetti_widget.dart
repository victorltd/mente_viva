// lib/core/widgets/confetti_widget.dart

import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiWidget extends StatefulWidget {
  final bool isPlaying;
  final Widget child;

  const ConfettiWidget({
    super.key,
    required this.isPlaying,
    required this.child,
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Confetti> _confettiList = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addListener(() {
      setState(() {
        for (final confetti in _confettiList) {
          confetti.update();
        }
        _confettiList.removeWhere((c) => c.y > 1.2);
      });
    });
  }

  @override
  void didUpdateWidget(ConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _confettiList.clear();
    for (int i = 0; i < 100; i++) {
      _confettiList.add(_Confetti(
        x: _random.nextDouble(),
        y: -_random.nextDouble() * 0.5,
        size: _random.nextDouble() * 8 + 4,
        color: _colors[_random.nextInt(_colors.length)],
        speedY: _random.nextDouble() * 0.015 + 0.005,
        speedX: (_random.nextDouble() - 0.5) * 0.01,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      ));
    }
    _controller.forward(from: 0);
  }

  static const _colors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF00BFA6),
    Color(0xFFFFC107),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF10B981),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_confettiList.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(_confettiList),
              ),
            ),
          ),
      ],
    );
  }
}

class _Confetti {
  double x;
  double y;
  double size;
  Color color;
  double speedY;
  double speedX;
  double rotation;
  double rotationSpeed;

  _Confetti({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update() {
    y += speedY;
    x += speedX;
    rotation += rotationSpeed;

    // Adicionar oscilação
    speedX += (Random().nextDouble() - 0.5) * 0.002;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confettiList;

  _ConfettiPainter(this.confettiList);

  @override
  void paint(Canvas canvas, Size size) {
    for (final confetti in confettiList) {
      final paint = Paint()..color = confetti.color;

      canvas.save();
      canvas.translate(
        confetti.x * size.width,
        confetti.y * size.height,
      );
      canvas.rotate(confetti.rotation * pi / 180);

      // Desenhar retângulo (confetti)
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: confetti.size,
          height: confetti.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}