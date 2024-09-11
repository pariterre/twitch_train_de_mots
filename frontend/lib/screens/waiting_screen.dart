import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/widgets/header.dart';

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    late final String textToShow;
    if (!gm.isGameRunning) {
      textToShow = 'Bien le bonjour cheminot\u00b7e,\n'
          '\n'
          'Nous sommes en attente du départ du train, veuillez patienter...';
    } else {
      textToShow =
          'Votre cheminot\u00b7e en chef est prêt\u00b7e pour le grand départ vers le Nord! '
          'L\'êtes vous aussi...?';
    }

    return Stack(
      children: [
        const Header(titleText: 'Le Train de mots'),
        Positioned(
            top: MediaQuery.of(context).size.height * 1 / 3,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  textToShow,
                  textAlign: TextAlign.left,
                  style: tm.textFrontendSc,
                ),
              ),
            ))
      ],
    );
  }
}
