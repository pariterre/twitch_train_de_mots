import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/header.dart';

class NonAuthorizedScreen extends StatelessWidget {
  const NonAuthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bonjour cheminot\u00b7e,\n'
                      'Afin de profiter d\'embarquer dans le train, vous '
                      'devez autoriser l\'accès à votre identifiant Twitch.',
                      textAlign: TextAlign.left,
                      style: tm.textFrontendSc,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () =>
                            TwitchManager.instance.requestIdShare(),
                        child: const Text('Ouvrir l\'autorisation')),
                  ],
                ),
              )),
        )
      ],
    );
  }
}
