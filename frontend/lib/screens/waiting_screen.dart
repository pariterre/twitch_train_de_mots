import 'package:common/managers/theme_manager.dart';
import 'package:common/models/game_status.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/header.dart';

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    late final String textToShow;
    switch (gm.status) {
      case GameStatus.uninitialized:
        textToShow = 'Bien le bonjour cheminot\u00b7e,\n'
            '\n'
            'Nous sommes en attente du départ du train, veuillez patienter...';
        break;
      case GameStatus.initializing:
      case GameStatus.roundStarted:
      case GameStatus.roundPreparing:
      case GameStatus.roundReady:
      case GameStatus.revealAnswers:
        textToShow =
            'Votre cheminot\u00b7e en chef est prêt\u00b7e pour le grand départ vers le Nord!\n'
            '\n'
            'Prochain arrêt: Station ${gm.currentRound}';
        break;
    }

    return Stack(
      children: [
        const Header(titleText: 'Le Train de mots'),
        Center(
          child: Transform.scale(
              scale: 0.8,
              child: SizedBox(
                width: (TwitchManager.instance is TwitchManagerMock)
                    ? 320
                    : MediaQuery.of(context).size.width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    textToShow,
                    textAlign: TextAlign.left,
                    style: tm.textFrontendSc,
                  ),
                ),
              )),
        )
      ],
    );
  }
}
