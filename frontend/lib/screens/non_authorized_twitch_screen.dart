import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/themed_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/header.dart';
import 'package:frontend/widgets/scaled_screen.dart';

class NonAuthorizedTwitchScreen extends StatelessWidget {
  const NonAuthorizedTwitchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return ScaledScreen(
      header: const Header(titleText: 'Le Train de mots!'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bonjour cheminot·e,\n'
              'Afin d\'embarquer dans\n'
              'le train, vous devez\n'
              'autoriser l\'accès à votre\n'
              'identifiant Twitch.',
              textAlign: TextAlign.left,
              style: tm.textFrontendSc,
            ),
            const SizedBox(height: 20),
            ThemedElevatedButton(
                onPressed: () =>
                    (IntegrationManager.instance as TwitchIntegrationManager)
                        .requestIdShare(),
                buttonText: 'Ouvrir l\'autorisation'),
          ],
        ),
      ),
    );
  }
}
