import 'package:common/generic/models/game_status.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:frontend_common/managers/twitch_manager.dart';
import 'package:frontend_common/widgets/header.dart';

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
            titleText: TwitchManager.instance.userHasGrantedIdAccess
                ? switch (GameManager.instance.status) {
                    WordsTrainGameStatus.roundStarted =>
                      'Le train est en route!\n'
                          'Prochaine station : ${GameManager.instance.currentRound + 1}!',
                    WordsTrainGameStatus.uninitialized => 'Le Train de mots!',
                    WordsTrainGameStatus.initializing => 'Le Train de mots!',
                    WordsTrainGameStatus.roundPreparing => 'Le Train de mots!',
                    WordsTrainGameStatus.roundReady => 'Le Train de mots!',
                    WordsTrainGameStatus.roundEnding => 'Le Train de mots!',
                    WordsTrainGameStatus.miniGamePreparing =>
                      'Le Train de mots!',
                    WordsTrainGameStatus.miniGameReady => 'Le Train de mots!',
                    WordsTrainGameStatus.miniGameStarted => '',
                    WordsTrainGameStatus.miniGameEnding => 'Le Train de mots!',
                  }
                : 'Le Train de mots!',
          )),
        ),
      ],
    );
  }
}
