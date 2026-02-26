import 'package:flutter/material.dart';
import 'background_sound_manager.dart';
import 'package:agenda/widgets/background_sound_manager.dart';

class SoundControl extends StatelessWidget {
  const SoundControl({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: BackgroundSoundManager.isMuted,
      builder: (context, isMuted, child) {
        return IconButton(
          icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
          tooltip: isMuted ? 'Ativar Som' : 'Mutar Som',
          onPressed: () {
            BackgroundSoundManager.isMuted.value = !isMuted;
          },
        );
      },
    );
  }
}