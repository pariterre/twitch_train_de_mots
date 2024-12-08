import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/header.dart';

class DraggingScreen extends StatelessWidget {
  const DraggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const SizedBox(width: double.infinity),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Center(
            child: Header(
                titleText: TwitchManager.instance.userHasGrantedIdAccess &&
                        GameManager.instance.isRoundRunning
                    ? 'Le train est en route!\n'
                        'Prochaine station : ${GameManager.instance.currentRound + 1}!'
                    : 'Le Train de mots!'),
          ),
        ),
      ],
    );
  }
}
