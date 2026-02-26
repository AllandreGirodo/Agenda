import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiAnimation extends StatefulWidget {
  final Widget child;
  final bool autoPlay;

  const ConfettiAnimation({super.key, required this.child, this.autoPlay = true});

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    if (widget.autoPlay) {
      _generateParticles();
    }
    _controller.addListener(_updateParticles);
  }

  void _generateParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.5, // Começa acima da tela
        size: 5 + _random.nextDouble() * 5,
        color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        speed: 0.005 + _random.nextDouble() * 0.01,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
      ));
    }
  }

  void _updateParticles() {
    for (var p in _particles) {
      p.y += p.speed;
      p.rotation += p.rotationSpeed;
      // Se sair da tela, recicla para o topo (efeito loop)
      if (p.y > 1.1) {
        p.y = -0.1;
        p.x = _random.nextDouble();
      }
    }
  }

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
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return RepaintBoundary(
                child: CustomPaint(
                  painter: _ConfettiPainter(_particles),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x, y, size, speed, rotation, rotationSpeed;
  Color color;
  _ConfettiParticle({required this.x, required this.y, required this.size, required this.color, required this.speed, required this.rotation, required this.rotationSpeed});
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}