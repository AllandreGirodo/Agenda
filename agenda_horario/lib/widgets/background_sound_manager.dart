import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../utils/custom_theme_data.dart';

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
    
    // Se o tema não tem som ou mudou para um tema sem som
    if (data.soundAsset == null) {
      await _player.stop();
      _currentAsset = null;
      return;
    }

    // Se o som é o mesmo que já está tocando, não faz nada
    if (_currentAsset == data.soundAsset) return;

    try {
      await _player.stop(); // Para o anterior
      _currentAsset = data.soundAsset;
      
      await _player.setReleaseMode(ReleaseMode.loop); // Loop infinito
      await _player.setVolume(BackgroundSoundManager.isMuted.value ? 0 : 0.15);
      await _player.play(AssetSource(data.soundAsset!));
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