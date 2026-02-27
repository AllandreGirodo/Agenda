import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:agenda/utils/custom_theme_data.dart';

class BackgroundSoundManager extends StatefulWidget {
  final AppThemeType themeType;
  final Widget child;

  // Controle global de Mute acessível por qualquer widget
  static final ValueNotifier<bool> isMuted = ValueNotifier(false);

  const BackgroundSoundManager({
    super.key,
    required this.themeType,
    required this.child,
  });

  @override
  State<BackgroundSoundManager> createState() => _BackgroundSoundManagerState();
}

class _BackgroundSoundManagerState extends State<BackgroundSoundManager> {
  final AudioPlayer _player = AudioPlayer();
  String? _currentAsset;
  String? _targetAsset; // Rastreia o ativo que desejamos tocar para evitar condições de corrida
  final AudioCache _audioCache = AudioCache(prefix: 'assets/'); // Cache dedicado

  @override
  void initState() {
    super.initState();
    BackgroundSoundManager.isMuted.addListener(_onMuteChanged);
    _preLoadSounds();
    _updateSound();
  }

  // Sistema de Cache: Pré-carrega sons comuns para evitar delay na primeira execução
  Future<void> _preLoadSounds() async {
    try {
      await _audioCache.loadAll([
        'sounds/ocean_waves.mp3',
        'sounds/space_ambient.mp3',
        'sounds/celebration.mp3',
        // Adicione outros sons do seu projeto aqui
      ]);
    } catch (e) {
      debugPrint('Erro ao pré-carregar sons: $e');
    }
  }

  @override
  void didUpdateWidget(covariant BackgroundSoundManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeType != widget.themeType) {
      _updateSound();
    }
  }

  void _onMuteChanged() {
    if (BackgroundSoundManager.isMuted.value) {
      _player.setVolume(0);
    } else {
      _player.setVolume(0.15);
    }
  }

  Future<void> _updateSound() async {
    final data = CustomThemeData.getData(widget.themeType);
    String? assetToPlay = data.soundAsset;

    // Garante o som de ondas para o tema Férias (caso não esteja no CustomThemeData)
    if (widget.themeType.toString() == 'AppThemeType.ferias') {
      assetToPlay = 'sounds/ocean_waves.mp3';
    }
    
    // Se o tema não tem som ou mudou para um tema sem som
    if (assetToPlay == null) {
      await _player.stop();
      _currentAsset = null;
      return;
    }

    // Se o som alvo já é o que queremos, ignora (evita múltiplas chamadas rápidas)
    if (_targetAsset == assetToPlay) return;
    _targetAsset = assetToPlay;


    try {
      // Fade Out (se estiver tocando algo)
      if (_player.state == PlayerState.playing) {
        double vol = BackgroundSoundManager.isMuted.value ? 0 : 0.15;
        for (int i = 10; i >= 0; i--) {
          if (!mounted) return;
          await _player.setVolume(vol * (i / 10));
          await Future.delayed(const Duration(milliseconds: 50));
        }
        await _player.stop();
      }

      // Verifica se o alvo mudou durante o fade out
      if (_targetAsset != assetToPlay) return;

      _currentAsset = assetToPlay;
      
      await _player.setReleaseMode(ReleaseMode.loop); // Loop infinito
      // Começa mudo para fazer o Fade In
      await _player.setVolume(0); 
      await _player.play(AssetSource(assetToPlay));

      // Fade In
      double targetVol = BackgroundSoundManager.isMuted.value ? 0 : 0.15;
      for (int i = 1; i <= 10; i++) {
        if (!mounted || _targetAsset != assetToPlay) return;
        await _player.setVolume(targetVol * (i / 10));
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      debugPrint('Erro ao tocar som de fundo: $e');
    }
  }

  @override
  void dispose() {
    BackgroundSoundManager.isMuted.removeListener(_onMuteChanged);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}