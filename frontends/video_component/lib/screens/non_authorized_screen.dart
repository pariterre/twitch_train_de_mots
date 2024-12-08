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
      alignment: Alignment.topCenter,
      children: [
        const FittedBox(
            fit: BoxFit.scaleDown,
            child: Header(titleText: 'Le Train de mots!')),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bonjour cheminot\u00b7e,\n'
                    'Afin de profiter d\'embarquer\n'
                    'dans le train, vous devez\n'
                    'autoriser l\'accès à votre\n'
                    'identifiant Twitch.',
                    textAlign: TextAlign.left,
                    style: tm.textFrontendSc,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () => TwitchManager.instance.requestIdShare(),
                      child: const Text('Ouvrir l\'autorisation')),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
