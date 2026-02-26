import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/custom_theme_data.dart';

class AnimatedBackground extends StatefulWidget {
  final AppThemeType themeType;
  final Widget child;

  const AnimatedBackground({super.key, required this.themeType, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  final List<_FloatingItem> _items = [];
  final List<_Snowflake> _snowflakes = []; // Lista específica para neve
  final List<_GlitchBar> _glitchBars = []; // Lista para efeito Cyberpunk
  final List<_RainDrop> _rainDrops = []; // Lista para efeito de Chuva
  final List<_Confetti> _confetti = []; // Lista para efeito de Confete
  final Random _random = Random();
  late AnimationController _controller;
  double _lightningOpacity = 0.0; // Controle da opacidade do raio

  @override
  void initState() {
    super.initState();
    // Controller rápido para animação fluida (60fps)
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    
    // Adiciona listener para atualizar a física da neve a cada frame
    _controller.addListener(_updateSnowPhysics);
    _controller.addListener(_updateGlitchPhysics);
    _controller.addListener(_updateRainPhysics);
    _controller.addListener(_updateConfettiPhysics);
    _generateItems();
  }

  @override
  void didUpdateWidget(covariant AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeType != widget.themeType) {
      _generateItems();
    }
  }

  void _updateSnowPhysics() {
    if (widget.themeType == AppThemeType.natal) {
      // Atualiza a posição de cada floco de neve
      for (var flake in _snowflakes) {
        flake.y += flake.speed;
        flake.x += sin(flake.y * 10) * 0.002; // Movimento lateral suave (seno)
        
        // Se sair da tela, reinicia no topo
        if (flake.y > 1.0) {
          flake.y = -0.05;
          flake.x = _random.nextDouble();
        }
      }
    }
  }

  void _updateGlitchPhysics() {
    if (widget.themeType == AppThemeType.cyberpunk) {
      // Regenera as barras de glitch aleatoriamente a cada poucos frames
      if (_random.nextDouble() > 0.8) { // 20% de chance por frame de mudar
        _glitchBars.clear();
        int count = _random.nextInt(5) + 2; // 2 a 7 barras
        for (int i = 0; i < count; i++) {
          _glitchBars.add(_GlitchBar(
            y: _random.nextDouble(),
            height: _random.nextDouble() * 0.05 + 0.01,
            color: _random.nextBool() ? Colors.cyanAccent : Colors.magentaAccent,
          ));
        }
      }
    }
  }

  void _updateRainPhysics() {
    if (widget.themeType == AppThemeType.tempestade) {
      // Chuva
      for (var drop in _rainDrops) {
        drop.y += drop.speed;
        if (drop.y > 1.0) {
          drop.y = -0.1 - _random.nextDouble() * 0.2; // Reinicia acima da tela
          drop.x = _random.nextDouble();
        }
      }
      
      // Raios (Flashes Aleatórios)
      if (_lightningOpacity > 0) {
        _lightningOpacity -= 0.05; // Fade out rápido
        if (_lightningOpacity < 0) _lightningOpacity = 0;
      } else {
        // Pequena chance de um raio cair a cada frame
        if (_random.nextDouble() > 0.99) { 
          _lightningOpacity = 0.6 + _random.nextDouble() * 0.3; // Brilho intenso (0.6 a 0.9)
        }
      }
    } else {
      _lightningOpacity = 0.0;
    }
  }

  void _updateConfettiPhysics() {
    if (widget.themeType == AppThemeType.carnaval) {
      for (var conf in _confetti) {
        conf.y += conf.speed;
        conf.rotation += conf.rotationSpeed;
        if (conf.y > 1.0) {
          conf.y = -0.1;
          conf.x = _random.nextDouble();
        }
      }
    }
  }

  void _generateItems() {
    _items.clear();
    _snowflakes.clear();
    _glitchBars.clear();
    _rainDrops.clear();
    _confetti.clear();
    final data = CustomThemeData.getData(widget.themeType);
    if (data.iconAsset == null) return; // Temas padrão não têm animação de fundo

    // Cria 15 elementos flutuantes
    for (int i = 0; i < 15; i++) {
      _items.add(_FloatingItem(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 20 + _random.nextDouble() * 40,
        speed: 0.2 + _random.nextDouble() * 0.5,
        opacity: 0.1 + _random.nextDouble() * 0.3,
      ));
    }

    // Se for Natal, gera flocos de neve para o CustomPainter
    if (widget.themeType == AppThemeType.natal) {
      for (int i = 0; i < 100; i++) { // 100 flocos
        _snowflakes.add(_Snowflake(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: 1 + _random.nextDouble() * 3, // Tamanho variado
          speed: 0.001 + _random.nextDouble() * 0.003, // Velocidade variada
        ));
      }
    }

    // Se for Tempestade, gera gotas de chuva
    if (widget.themeType == AppThemeType.tempestade) {
      for (int i = 0; i < 100; i++) { // 100 gotas
        _rainDrops.add(_RainDrop(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          length: 0.02 + _random.nextDouble() * 0.03, // Comprimento variado
          speed: 0.015 + _random.nextDouble() * 0.01, // Velocidade rápida
        ));
      }
    }

    // Se for Carnaval, gera confetes
    if (widget.themeType == AppThemeType.carnaval) {
      for (int i = 0; i < 50; i++) {
        _confetti.add(_Confetti(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 5 + _random.nextDouble() * 5,
          speed: 0.005 + _random.nextDouble() * 0.01,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
          color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        ));
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSnowPhysics);
    _controller.removeListener(_updateGlitchPhysics);
    _controller.removeListener(_updateRainPhysics);
    _controller.removeListener(_updateConfettiPhysics);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = CustomThemeData.getData(widget.themeType);

    // Define as cores para o AnimatedContainer.
    // Se não houver cores (tema padrão), usa transparente para deixar o Scaffold do app aparecer.
    List<Color> bgColors = data.gradientColors;
    if (bgColors.isEmpty) {
      bgColors = [Colors.transparent, Colors.transparent];
    }

    return Stack(
      children: [
        // 1. Gradiente de Fundo
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: bgColors.length >= 2 ? bgColors : [bgColors.first, bgColors.first],
            ),
          ),
        ),
        
        // 1.2. Camada de Raios (Tempestade) - Atrás das partículas, sobre o fundo
        if (widget.themeType == AppThemeType.tempestade)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Container(
              color: Colors.white.withOpacity(_lightningOpacity),
            ),
          ),

        // 2. Camada de Partículas (Neve, Glitch, Ícones) com Transição Suave
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          child: _buildParticleLayer(data),
        ),

        // 3. Conteúdo da Tela (Scaffold)
        widget.child,
      ],
    );
  }

  Widget _buildParticleLayer(CustomThemeData data) {
    // Retorna o widget específico baseado no tema atual para o AnimatedSwitcher
    if (widget.themeType == AppThemeType.natal) {
      return AnimatedBuilder(
        key: const ValueKey('natal'),
        animation: _controller,
        builder: (context, child) => CustomPaint(painter: SnowPainter(_snowflakes), size: Size.infinite),
      );
    } else if (widget.themeType == AppThemeType.cyberpunk) {
      return AnimatedBuilder(
        key: const ValueKey('cyberpunk'),
        animation: _controller,
        builder: (context, child) => CustomPaint(painter: GlitchPainter(_glitchBars), size: Size.infinite),
      );
    } else if (widget.themeType == AppThemeType.tempestade) {
      return AnimatedBuilder(
        key: const ValueKey('tempestade'),
        animation: _controller,
        builder: (context, child) => CustomPaint(painter: RainPainter(_rainDrops), size: Size.infinite),
      );
    } else if (widget.themeType == AppThemeType.carnaval) {
      return AnimatedBuilder(
        key: const ValueKey('carnaval'),
        animation: _controller,
        builder: (context, child) => CustomPaint(painter: ConfettiPainter(_confetti), size: Size.infinite),
      );
    } else if (data.iconAsset != null) {
      return AnimatedBuilder(
        key: ValueKey('icons_${widget.themeType}'),
        animation: _controller,
        builder: (context, child) {
          return Stack(
              children: _items.map((item) {
                // Atualiza posição (simples loop vertical)
                double currentY = (item.y + _controller.value * item.speed) % 1.0;
                
                return Positioned(
                  left: item.x * MediaQuery.of(context).size.width,
                  top: currentY * MediaQuery.of(context).size.height,
                  child: Icon(data.iconAsset, size: item.size, color: data.iconColor.withOpacity(item.opacity)),
                );
              }).toList(),
          );
        },
      );
    }
    // Retorna um container vazio para temas sem partículas (Standard)
    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}

class _FloatingItem {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  _FloatingItem({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
}

class _Snowflake {
  double x;
  double y;
  double radius;
  double speed;
  _Snowflake({required this.x, required this.y, required this.radius, required this.speed});
}

class SnowPainter extends CustomPainter {
  final List<_Snowflake> snowflakes;
  SnowPainter(this.snowflakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);
    for (var flake in snowflakes) {
      canvas.drawCircle(Offset(flake.x * size.width, flake.y * size.height), flake.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Confetti {
  double x;
  double y;
  double size;
  double speed;
  double rotation;
  double rotationSpeed;
  Color color;
  _Confetti({required this.x, required this.y, required this.size, required this.speed, required this.rotation, required this.rotationSpeed, required this.color});
}

class ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  ConfettiPainter(this.confetti);

  @override
  void paint(Canvas canvas, Size size) {
    for (var conf in confetti) {
      final paint = Paint()..color = conf.color;
      canvas.save();
      canvas.translate(conf.x * size.width, conf.y * size.height);
      canvas.rotate(conf.rotation);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: conf.size, height: conf.size * 0.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RainDrop {
  double x;
  double y;
  double length;
  double speed;
  _RainDrop({required this.x, required this.y, required this.length, required this.speed});
}

class RainPainter extends CustomPainter {
  final List<_RainDrop> drops;
  RainPainter(this.drops);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    for (var drop in drops) {
      canvas.drawLine(Offset(drop.x * size.width, drop.y * size.height), Offset(drop.x * size.width, (drop.y + drop.length) * size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GlitchBar {
  double y;
  double height;
  Color color;
  _GlitchBar({required this.y, required this.height, required this.color});
}

class GlitchPainter extends CustomPainter {
  final List<_GlitchBar> bars;
  GlitchPainter(this.bars);

  @override
  void paint(Canvas canvas, Size size) {
    for (var bar in bars) {
      final paint = Paint()..color = bar.color.withOpacity(0.6)..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, bar.y * size.height, size.width, bar.height * size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}