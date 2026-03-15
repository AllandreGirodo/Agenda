import 'dart:async';
import 'dart:math';
import 'dart:ui'; // Necessário para PointMode
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agenda/core/utils/custom_theme_data.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  final List<_Heart> _hearts = []; // Lista para Dia da Mulher
  final List<_Sparkle> _sparkles = []; // Lista para Outubro Rosa
  final List<_Fish> _fishes = []; // Lista para Peixinhos (Férias)
  final List<_Bubble> _bubbles = []; // Lista para Bolhas dos Peixes
  final List<_HalloweenItem> _halloweenItems = []; // Lista para Halloween
  double _wavePhase = 0.0; // Fase da onda para animação
  int _vacationIndex = 0; // 0: Sol, 1: Bola, 2: Máscara, 3: Peixes
  Timer? _vacationTimer;
  final Random _random = Random();
  late AnimationController _controller;
  double _lightningOpacity = 0.0; // Controle da opacidade do raio
  double _continuousTime = 0.0; // Tempo contínuo para animações sem loop (ex: peixes)
  
  // Variáveis para o efeito Parallax
  double _parallaxX = 0.0, _parallaxY = 0.0;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;

  @override
  void initState() {
    super.initState();
    // Controller rápido para animação fluida (60fps)
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    
    // Adiciona listener para atualizar a física de cada efeito
    _controller.addListener(_updateSnowPhysics);
    _controller.addListener(_updateGlitchPhysics);
    _controller.addListener(_updateRainPhysics);
    _controller.addListener(_updateConfettiPhysics);
    _controller.addListener(_updateHeartPhysics);
    _controller.addListener(_updateSparklePhysics);
    _controller.addListener(_updateWavePhysics);
    _controller.addListener(_updateVacationPhysics);
    _controller.addListener(_updateHalloweenPhysics);
    _generateItems();
    _initSensors();
  }

  void _initSensors() {
    if (kIsWeb) return;

    // Escuta o acelerômetro para criar o efeito de profundidade
    _sensorSubscription = accelerometerEventStream().listen(
      (event) {
        if (mounted) {
          setState(() {
            // Filtro simples (Low-pass) para suavizar o movimento e evitar tremedeira
            _parallaxX = _parallaxX * 0.9 + (-event.x * 0.1);
            _parallaxY = _parallaxY * 0.9 + (event.y * 0.1);
          });
        }
      },
      onError: (_) {
        _sensorSubscription?.cancel();
        _sensorSubscription = null;
      },
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeType != widget.themeType) {
      _generateItems();
      if (widget.themeType.toString() == 'AppThemeType.ferias') {
        _startVacationTimer();
      } else {
        _vacationTimer?.cancel();
      }
    } else if (widget.themeType.toString() == 'AppThemeType.ferias' && _vacationTimer == null) {
      _startVacationTimer();
    }
  }

  void _startVacationTimer() {
    _vacationTimer?.cancel();
    _vacationTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) setState(() => _vacationIndex = (_vacationIndex + 1) % 4);
    });
  }

  // --- FÍSICA ---

  void _updateSnowPhysics() {
    if (widget.themeType == AppThemeType.natal) {
      for (var flake in _snowflakes) {
        flake.y += flake.speed;
        flake.x += sin(flake.y * 10) * 0.002;
        if (flake.y > 1.0) {
          flake.y = -0.05;
          flake.x = _random.nextDouble();
        }
      }
    }
  }

  void _updateGlitchPhysics() {
    if (widget.themeType == AppThemeType.cyberpunk) {
      if (_random.nextDouble() > 0.8) {
        _glitchBars.clear();
        int count = _random.nextInt(5) + 2;
        for (int i = 0; i < count; i++) {
          _glitchBars.add(_GlitchBar(
            y: _random.nextDouble(),
            height: _random.nextDouble() * 0.05 + 0.01,
            color: _random.nextBool() ? Colors.cyanAccent : Colors.pinkAccent,
          ));
        }
      }
    }
  }

  void _updateRainPhysics() {
    if (widget.themeType == AppThemeType.tempestade) {
      for (var drop in _rainDrops) {
        drop.y += drop.speed;
        if (drop.y > 1.0) {
          drop.y = -0.1 - _random.nextDouble() * 0.2;
          drop.x = _random.nextDouble();
        }
      }
      if (_lightningOpacity > 0) {
        _lightningOpacity -= 0.05;
        if (_lightningOpacity < 0) _lightningOpacity = 0;
      } else {
        if (_random.nextDouble() > 0.99) { 
          _lightningOpacity = 0.6 + _random.nextDouble() * 0.3;
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

  void _updateHeartPhysics() {
    if (widget.themeType.toString() == 'AppThemeType.diaDaMulher') {
      for (var heart in _hearts) {
        heart.y -= heart.speed;
        heart.x += sin(heart.y * 5) * 0.005;
        if (heart.y < -0.1) {
          heart.y = 1.1;
          heart.x = _random.nextDouble();
        }
      }
    }
  }

  void _updateSparklePhysics() {
    if (widget.themeType.toString() == 'AppThemeType.outubroRosa') {
      for (var sparkle in _sparkles) {
        sparkle.y -= sparkle.speed;
        sparkle.opacity += sparkle.pulseSpeed;
        if (sparkle.opacity > 1.0 || sparkle.opacity < 0.2) {
          sparkle.pulseSpeed = -sparkle.pulseSpeed;
        }
        if (sparkle.y < -0.1) {
          sparkle.y = 1.1;
          sparkle.x = _random.nextDouble();
        }
      }
    }
  }

  void _updateWavePhysics() {
    if (widget.themeType.toString() == 'AppThemeType.ferias') {
      _wavePhase += 0.05;
    }
  }

  void _updateVacationPhysics() {
    if (widget.themeType.toString() == 'AppThemeType.ferias' && _vacationIndex == 3) {
       _continuousTime += 0.05;
       for (var fish in _fishes) {
         fish.x -= fish.speed;
         if (fish.x < -0.1) fish.x = 1.1;
         fish.y += sin(_continuousTime + fish.x * 10) * 0.001;
         
         if (_random.nextDouble() < 0.1) {
           _bubbles.add(_Bubble(
             x: fish.x + (fish.size * 0.0015),
             y: fish.y,
             size: 2 + _random.nextDouble() * 3,
             speed: 0.001 + _random.nextDouble() * 0.002,
           ));
         }
       }
    }
    
    for (var bubble in _bubbles) {
      bubble.y -= bubble.speed;
      bubble.x += sin(bubble.y * 20) * 0.0005;
      bubble.opacity -= 0.01;
    }
    _bubbles.removeWhere((b) => b.opacity <= 0);
  }

  void _updateHalloweenPhysics() {
    if (widget.themeType.toString() == 'AppThemeType.halloween') {
      for (var item in _halloweenItems) {
        if (item.type == 0) { // Morcego
          item.x += item.speed;
          item.y += sin(item.x * 10) * 0.005; // Voo ondulado
          item.wingFlap += 0.5; // Animação de bater asas
          
          if (item.x > 1.1) {
            item.x = -0.1;
            item.y = 0.1 + _random.nextDouble() * 0.6;
          }
        } else { // Abóbora
          item.y += item.speed * 0.5;
          item.x += sin(item.y * 5) * 0.002;
          if (item.y > 1.1) {
            item.y = -0.1;
            item.x = _random.nextDouble();
          }
        }
      }
    }
  }

  // --- GERAÇÃO DE ITENS ---

  void _generateItems() {
    _items.clear();
    _snowflakes.clear();
    _glitchBars.clear();
    _rainDrops.clear();
    _confetti.clear();
    _hearts.clear();
    _sparkles.clear();
    _fishes.clear();
    _bubbles.clear();
    _halloweenItems.clear();
    
    final data = CustomThemeData.getData(widget.themeType);
    if (data.iconAsset == null) return;

    // Ícones flutuantes padrão
    for (int i = 0; i < 15; i++) {
      _items.add(_FloatingItem(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 20 + _random.nextDouble() * 40,
        speed: 0.2 + _random.nextDouble() * 0.5,
        opacity: 0.1 + _random.nextDouble() * 0.3,
      ));
    }

    // Natal
    if (widget.themeType == AppThemeType.natal) {
      for (int i = 0; i < 100; i++) {
        _snowflakes.add(_Snowflake(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: 1 + _random.nextDouble() * 3,
          speed: 0.001 + _random.nextDouble() * 0.003,
        ));
      }
    }

    // Tempestade
    if (widget.themeType == AppThemeType.tempestade) {
      for (int i = 0; i < 100; i++) {
        _rainDrops.add(_RainDrop(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          length: 0.02 + _random.nextDouble() * 0.03,
          speed: 0.015 + _random.nextDouble() * 0.01,
        ));
      }
    }

    // Carnaval
    if (widget.themeType == AppThemeType.carnaval) {
      for (int i = 0; i < 50; i++) {
        _confetti.add(_Confetti(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 5 + _random.nextDouble() * 5,
          speed: 0.005 + _random.nextDouble() * 0.01,
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.2, // Rotação bidirecional
          color: Colors.primaries[_random.nextInt(Colors.primaries.length)], // Cores variadas
        ));
      }
    }

    // Dia da Mulher
    if (widget.themeType.toString() == 'AppThemeType.diaDaMulher') {
      for (int i = 0; i < 40; i++) {
        _hearts.add(_Heart(
          x: _random.nextDouble(),
          y: 1.1 + _random.nextDouble() * 0.2,
          size: 10 + _random.nextDouble() * 15,
          speed: 0.002 + _random.nextDouble() * 0.003,
          color: Colors.pinkAccent.withValues(alpha: 0.6 + _random.nextDouble() * 0.4),
        ));
      }
    }

    // Outubro Rosa
    if (widget.themeType.toString() == 'AppThemeType.outubroRosa') {
      for (int i = 0; i < 60; i++) {
        _sparkles.add(_Sparkle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 5 + _random.nextDouble() * 10,
          speed: 0.001 + _random.nextDouble() * 0.002,
          opacity: _random.nextDouble(),
          pulseSpeed: 0.01 + _random.nextDouble() * 0.02,
        ));
      }
    }

    // Férias
    if (widget.themeType.toString() == 'AppThemeType.ferias') {
      for (int i = 0; i < 6; i++) {
        _fishes.add(_Fish(
          x: 1.0 + _random.nextDouble(),
          y: 0.7 + _random.nextDouble() * 0.2,
          size: 8 + _random.nextDouble() * 6,
          speed: 0.001 + _random.nextDouble() * 0.002,
          color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        ));
      }
    }

    // Halloween
    if (widget.themeType.toString() == 'AppThemeType.halloween') {
      // Morcegos
      for (int i = 0; i < 8; i++) {
        _halloweenItems.add(_HalloweenItem(
          x: _random.nextDouble(),
          y: 0.1 + _random.nextDouble() * 0.6,
          size: 20 + _random.nextDouble() * 15,
          speed: 0.003 + _random.nextDouble() * 0.003,
          type: 0, // Morcego
        ));
      }
      // Abóboras
      for (int i = 0; i < 6; i++) {
        _halloweenItems.add(_HalloweenItem(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 25 + _random.nextDouble() * 15,
          speed: 0.001 + _random.nextDouble() * 0.002,
          type: 1, // Abóbora
        ));
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateHalloweenPhysics);
    _controller.dispose();
    _vacationTimer?.cancel();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = CustomThemeData.getData(widget.themeType);

    List<Color> bgColors = data.gradientColors;
    
    // Simulação de Entardecer para Férias
    if (widget.themeType.toString() == 'AppThemeType.ferias') {
       double t = (sin(_controller.value * 2 * pi) + 1) / 2; 
       bgColors = [
         Color.lerp(const Color(0xFF4facfe), const Color(0xFFFF7E5F), t)!,
         Color.lerp(const Color(0xFF00f2fe), const Color(0xFFFEB47B), t)!,
       ];
    }

    if (bgColors.isEmpty) {
      bgColors = [Colors.transparent, Colors.transparent];
    }

    final Offset bgOffset = Offset(_parallaxX * 3, _parallaxY * 3);
    final Offset particleOffset = Offset(_parallaxX * 6, _parallaxY * 6);

    return Stack(
      children: [
        // 1. Fundo Gradiente
        Transform.translate(
          offset: bgOffset,
          child: AnimatedContainer(
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
        ),
        
        // 1.2. Camada de Raios (Tempestade)
        if (widget.themeType == AppThemeType.tempestade)
          Transform.translate(
            offset: bgOffset,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Container(
                color: Colors.white.withValues(alpha: _lightningOpacity),
              ),
            ),
          ),

        // 2. Camada de Partículas com Transição Suave
        Transform.translate(
          offset: particleOffset,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: _buildParticleLayer(data),
          ),
        ),

        // 3. Conteúdo do App
        widget.child,
      ],
    );
  }

  Widget _buildParticleLayer(CustomThemeData data) {
    if (widget.themeType == AppThemeType.natal) {
      return AnimatedBuilder(
        key: const ValueKey('natal'),
        animation: _controller,
        builder: (context, child) => RepaintBoundary(
          child: CustomPaint(painter: _SnowPainter(_snowflakes), size: Size.infinite),
        ),
      );
    } else if (widget.themeType == AppThemeType.cyberpunk) {
      return AnimatedBuilder(
        key: const ValueKey('cyberpunk'),
        animation: _controller,
        builder: (context, child) => RepaintBoundary(
          child: CustomPaint(painter: _GlitchPainter(_glitchBars), size: Size.infinite),
        ),
      );
    } else if (widget.themeType == AppThemeType.tempestade) {
      return AnimatedBuilder(
        key: const ValueKey('tempestade'),
        animation: _controller,
        builder: (context, child) => RepaintBoundary(
          child: CustomPaint(painter: _RainPainter(_rainDrops), size: Size.infinite),
        ),
      );
    } else if (widget.themeType == AppThemeType.carnaval) {
      return AnimatedBuilder(
        key: const ValueKey('carnaval'),
        animation: _controller,
        builder: (context, child) => RepaintBoundary(
          child: CustomPaint(painter: _ConfettiPainter(_confetti), size: Size.infinite),
        ),
      );
    } else if (widget.themeType.toString() == 'AppThemeType.diaDaMulher') {
      return AnimatedBuilder(
        key: const ValueKey('diaDaMulher'),
        animation: _controller,
        builder: (context, child) => RepaintBoundary(
          child: CustomPaint(painter: _HeartPainter(_hearts), size: Size.infinite),
        ),
      );
    } else if (widget.themeType.toString() == 'AppThemeType.outubroRosa') {
      return AnimatedBuilder(
        key: const ValueKey('outubroRosa'),
        animation: _controller,
        builder: (context, child) => RepaintBoundary(
          child: CustomPaint(painter: _SparklePainter(_sparkles), size: Size.infinite),
        ),
      );
    } else if (widget.themeType.toString() == 'AppThemeType.ferias') {
      return AnimatedBuilder(
        key: const ValueKey('ferias'),
        animation: _controller,
        builder: (context, child) => Stack(
          children: [
            RepaintBoundary(child: CustomPaint(painter: _SandPainter(), size: Size.infinite)),
            RepaintBoundary(child: CustomPaint(painter: _WavePainter(_wavePhase), size: Size.infinite)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: _buildVacationItem(),
            ),
          ],
        ),
      );
    } else if (widget.themeType.toString() == 'AppThemeType.halloween') {
      return AnimatedBuilder(
        key: const ValueKey('halloween'),
        animation: _controller,
        builder: (context, child) => RepaintBoundary(
          child: CustomPaint(painter: _HalloweenPainter(_halloweenItems), size: Size.infinite),
        ),
      );
    } else if (data.iconAsset != null) {
      return AnimatedBuilder(
        key: ValueKey('icons_${widget.themeType}'),
        animation: _controller,
        builder: (context, child) {
          return Stack(
              children: _items.map((item) {
                double currentY = (item.y + _controller.value * item.speed) % 1.0;
                return Positioned(
                  left: item.x * MediaQuery.of(context).size.width,
                  top: currentY * MediaQuery.of(context).size.height,
                  child: Icon(data.iconAsset, size: item.size, color: data.iconColor.withValues(alpha: item.opacity)),
                );
              }).toList(),
          );
        },
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  Widget _buildVacationItem() {
    switch (_vacationIndex) {
      case 0: return RepaintBoundary(key: const ValueKey(0), child: CustomPaint(painter: _SunPainter(), size: Size.infinite));
      case 1: return RepaintBoundary(key: const ValueKey(1), child: CustomPaint(painter: _BeachBallPainter(), size: Size.infinite));
      case 2: return RepaintBoundary(key: const ValueKey(2), child: CustomPaint(painter: _MaskPainter(), size: Size.infinite));
      case 3: return Stack(
        key: const ValueKey(3),
        children: [
          RepaintBoundary(child: CustomPaint(painter: _BubblePainter(_bubbles), size: Size.infinite)),
          RepaintBoundary(child: CustomPaint(painter: _FishPainter(_fishes), size: Size.infinite)),
        ],
      );
      default: return const SizedBox.shrink();
    }
  }
}

// --- CLASSES AUXILIARES ---

class _FloatingItem {
  double x, y, size, speed, opacity;
  _FloatingItem({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
}

class _Snowflake {
  double x, y, radius, speed;
  _Snowflake({required this.x, required this.y, required this.radius, required this.speed});
}

class _GlitchBar {
  double y, height;
  Color color;
  _GlitchBar({required this.y, required this.height, required this.color});
}

class _RainDrop {
  double x, y, length, speed;
  _RainDrop({required this.x, required this.y, required this.length, required this.speed});
}

class _Confetti {
  double x, y, size, speed, rotation, rotationSpeed;
  Color color;
  _Confetti({required this.x, required this.y, required this.size, required this.speed, required this.rotation, required this.rotationSpeed, required this.color});
}

class _Heart {
  double x, y, size, speed;
  Color color;
  _Heart({required this.x, required this.y, required this.size, required this.speed, required this.color});
}

class _Sparkle {
  double x, y, size, speed, opacity, pulseSpeed;
  _Sparkle({required this.x, required this.y, required this.size, required this.speed, required this.opacity, required this.pulseSpeed});
}

class _Fish {
  double x, y, size, speed;
  Color color;
  _Fish({required this.x, required this.y, required this.size, required this.speed, required this.color});
}

class _Bubble {
  double x, y, size, speed, opacity = 0.8;
  _Bubble({required this.x, required this.y, required this.size, required this.speed});
}

class _HalloweenItem {
  double x, y, size, speed;
  int type; // 0: Bat, 1: Pumpkin
  double wingFlap = 0.0;
  _HalloweenItem({required this.x, required this.y, required this.size, required this.speed, required this.type});
}

// --- PAINTERS ---

class _SnowPainter extends CustomPainter {
  final List<_Snowflake> snowflakes;
  _SnowPainter(this.snowflakes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    final List<Offset> smallFlakes = [];
    final List<Offset> mediumFlakes = [];
    final List<Offset> largeFlakes = [];

    for (var flake in snowflakes) {
      final offset = Offset(flake.x * size.width, flake.y * size.height);
      if (flake.radius < 2.0) {
        smallFlakes.add(offset);
      } else if (flake.radius < 3.0) {
        mediumFlakes.add(offset);
      } else {
        largeFlakes.add(offset);
      }
    }

    paint.strokeWidth = 3.0;
    paint.strokeCap = StrokeCap.round;
    canvas.drawPoints(PointMode.points, smallFlakes, paint);
    paint.strokeWidth = 5.0;
    canvas.drawPoints(PointMode.points, mediumFlakes, paint);
    paint.strokeWidth = 8.0;
    canvas.drawPoints(PointMode.points, largeFlakes, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HalloweenPainter extends CustomPainter {
  final List<_HalloweenItem> items;
  _HalloweenPainter(this.items);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (var item in items) {
      final cx = item.x * size.width;
      final cy = item.y * size.height;
      
      if (item.type == 0) { // Morcego
        paint.color = Colors.black.withValues(alpha: 0.8);
        paint.style = PaintingStyle.fill;
        
        // Corpo
        canvas.drawCircle(Offset(cx, cy), item.size * 0.2, paint);
        
        // Asas
        final path = Path();
        double flap = sin(item.wingFlap) * item.size * 0.2;
        
        // Asa Esquerda
        path.moveTo(cx - item.size * 0.2, cy);
        path.quadraticBezierTo(cx - item.size * 0.6, cy - item.size * 0.4 + flap, cx - item.size, cy + flap);
        path.quadraticBezierTo(cx - item.size * 0.6, cy + item.size * 0.2 + flap, cx - item.size * 0.2, cy + item.size * 0.1);
        
        // Asa Direita
        path.moveTo(cx + item.size * 0.2, cy);
        path.quadraticBezierTo(cx + item.size * 0.6, cy - item.size * 0.4 + flap, cx + item.size, cy + flap);
        path.quadraticBezierTo(cx + item.size * 0.6, cy + item.size * 0.2 + flap, cx + item.size * 0.2, cy + item.size * 0.1);
        
        canvas.drawPath(path, paint);
        
      } else { // Abóbora
        paint.color = Colors.orange;
        paint.style = PaintingStyle.fill;
        
        // Formato base
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: item.size, height: item.size * 0.8), paint);
        
        // Gomos
        paint.color = Colors.deepOrange;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy), width: item.size * 0.5, height: item.size * 0.8), 0, pi * 2, false, paint);
        
        // Talo
        paint.color = Colors.green;
        paint.style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - item.size * 0.4), width: item.size * 0.15, height: item.size * 0.2), paint);
        
        // Olhos e Boca (Jack-o'-lantern)
        paint.color = Colors.black;
        final facePath = Path();
        // Olhos
        facePath.addPolygon([Offset(cx - item.size * 0.2, cy - item.size * 0.1), Offset(cx - item.size * 0.3, cy + item.size * 0.05), Offset(cx - item.size * 0.1, cy + item.size * 0.05)], true);
        facePath.addPolygon([Offset(cx + item.size * 0.2, cy - item.size * 0.1), Offset(cx + item.size * 0.3, cy + item.size * 0.05), Offset(cx + item.size * 0.1, cy + item.size * 0.05)], true);
        // Boca
        facePath.moveTo(cx - item.size * 0.25, cy + item.size * 0.15);
        facePath.quadraticBezierTo(cx, cy + item.size * 0.35, cx + item.size * 0.25, cy + item.size * 0.15);
        canvas.drawPath(facePath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  _BubblePainter(this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1;
    for (var b in bubbles) {
      paint.color = Colors.white.withValues(alpha: b.opacity.clamp(0.0, 0.5));
      canvas.drawCircle(Offset(b.x * size.width, b.y * size.height), b.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE6C288);
    final path = Path();
    path.moveTo(0, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.82, size.width, size.height * 0.85);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  final double phase;
  _WavePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    paint.color = Colors.blue.shade800.withValues(alpha: 0.5);
    final path1 = Path();
    path1.moveTo(0, size.height);
    for (double i = 0; i <= size.width; i++) {
      path1.lineTo(i, size.height - 40 - 10 * sin((i / size.width * 2 * pi) + phase));
    }
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    paint.color = Colors.blue.shade400.withValues(alpha: 0.6);
    final path2 = Path();
    path2.moveTo(0, size.height);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(i, size.height - 30 - 12 * sin((i / size.width * 2 * pi) + phase + 1.5));
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.phase != phase;
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.yellowAccent;
    final center = Offset(size.width * 0.85, size.height * 0.15);
    canvas.drawCircle(center, 25, paint);
    
    paint.strokeWidth = 3;
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4);
      final p1 = center + Offset(cos(angle), sin(angle)) * 30;
      final p2 = center + Offset(cos(angle), sin(angle)) * 40;
      canvas.drawLine(p1, p2, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BeachBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.2, size.height * 0.75);
    final radius = 20.0;
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = [Colors.red, Colors.blue, Colors.yellow, Colors.green, Colors.white, Colors.orange];
    for (int i = 0; i < 6; i++) {
      paint.color = colors[i];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), (i * pi / 3), pi / 3, true, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = 3;
    final center = Offset(size.width * 0.5, size.height * 0.5);
    canvas.drawOval(Rect.fromCenter(center: center, width: 60, height: 30), paint);
    paint.color = Colors.black54;
    canvas.drawArc(Rect.fromCenter(center: center, width: 55, height: 25), pi, pi, false, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FishPainter extends CustomPainter {
  final List<_Fish> fishes;
  _FishPainter(this.fishes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var fish in fishes) {
      paint.color = fish.color;
      final center = Offset(fish.x * size.width, fish.y * size.height);
      canvas.drawOval(Rect.fromCenter(center: center, width: fish.size * 1.5, height: fish.size), paint);
      final tailPath = Path();
      tailPath.moveTo(center.dx + fish.size * 0.6, center.dy);
      tailPath.lineTo(center.dx + fish.size * 1.2, center.dy - fish.size * 0.4);
      tailPath.lineTo(center.dx + fish.size * 1.2, center.dy + fish.size * 0.4);
      tailPath.close();
      canvas.drawPath(tailPath, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HeartPainter extends CustomPainter {
  final List<_Heart> hearts;
  _HeartPainter(this.hearts);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var heart in hearts) {
      paint.color = heart.color;
      final path = Path();
      final cx = heart.x * size.width;
      final cy = heart.y * size.height;
      final s = heart.size;

      path.moveTo(cx, cy + s * 0.2);
      path.cubicTo(cx - s, cy - s * 0.5, cx - s, cy - s, cx, cy - s * 0.5);
      path.cubicTo(cx + s, cy - s, cx + s, cy - s * 0.5, cx, cy + s * 0.2);
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  _SparklePainter(this.sparkles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var s in sparkles) {
      paint.color = Colors.white.withValues(alpha: s.opacity.clamp(0.0, 1.0));
      final cx = s.x * size.width;
      final cy = s.y * size.height;
      canvas.drawCircle(Offset(cx, cy), s.size * 0.2, paint);
      canvas.drawLine(Offset(cx - s.size, cy), Offset(cx + s.size, cy), paint..strokeWidth = 1);
      canvas.drawLine(Offset(cx, cy - s.size), Offset(cx, cy + s.size), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  _ConfettiPainter(this.confetti);

  @override
  void paint(Canvas canvas, Size size) {
    for (var conf in confetti) {
      final paint = Paint()..color = conf.color.withValues(alpha: 0.6); // Opacidade adicionada para suavidade
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

class _RainPainter extends CustomPainter {
  final List<_RainDrop> drops;
  _RainPainter(this.drops);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    for (var drop in drops) {
      canvas.drawLine(Offset(drop.x * size.width, drop.y * size.height), Offset(drop.x * size.width, (drop.y + drop.length) * size.height), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GlitchPainter extends CustomPainter {
  final List<_GlitchBar> bars;
  _GlitchPainter(this.bars);

  @override
  void paint(Canvas canvas, Size size) {
    for (var bar in bars) {
      final paint = Paint()..color = bar.color.withValues(alpha: 0.6)..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, bar.y * size.height, size.width, bar.height * size.height), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
