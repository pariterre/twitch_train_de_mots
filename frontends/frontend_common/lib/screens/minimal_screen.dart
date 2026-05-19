import 'package:common/generic/models/game_status.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:frontend_common/managers/twitch_manager.dart';
import 'package:frontend_common/widgets/header.dart';

class MinimalScreen extends StatelessWidget {
  const MinimalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const SizedBox(width: double.infinity),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Center(
              child: Header(
            titleText: TwitchManager.instance.userHasGrantedIdAccess
                ? switch (gm.status) {
                    WordsTrainGameStatus.roundStarted => gm.isMiniGameActive
                        ? 'Le Train de mots'
                        : ('Le train est en route!\n'
                            'Prochaine station : ${gm.currentRound + 1}!'),
                    WordsTrainGameStatus.uninitialized => 'Le Train de mots!',
                    WordsTrainGameStatus.initializing => 'Le Train de mots!',
                    WordsTrainGameStatus.roundPreparing => 'Le Train de mots!',
                    WordsTrainGameStatus.roundReady => 'Le Train de mots!',
                    WordsTrainGameStatus.roundEnding => 'Le Train de mots!',
                  }
                : 'Le Train de mots!',
          )),
        ),
      ],
    );
  }
}
