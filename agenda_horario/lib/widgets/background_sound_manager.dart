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

  @override
  void initState() {
    super.initState();
    BackgroundSoundManager.isMuted.addListener(_onMuteChanged);
    _updateSound();
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

    // Se o som é o mesmo que já está tocando, não faz nada
    if (_currentAsset == assetToPlay) return;

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

      _currentAsset = assetToPlay;
      
      await _player.setReleaseMode(ReleaseMode.loop); // Loop infinito
      // Começa mudo para fazer o Fade In
      await _player.setVolume(0); 
      await _player.play(AssetSource(assetToPlay));

      // Fade In
      double targetVol = BackgroundSoundManager.isMuted.value ? 0 : 0.15;
      for (int i = 1; i <= 10; i++) {
        if (!mounted || _currentAsset != assetToPlay) return;
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