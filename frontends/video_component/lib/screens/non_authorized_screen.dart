import 'package:common/managers/theme_manager.dart';
import 'package:common/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/header.dart';
import 'package:frontend/widgets/opaque_on_hover.dart';

class NonAuthorizedScreen extends StatelessWidget {
  const NonAuthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return OpaqueOnHover(
      opacityMin: 0.1,
      opacityMax: 1.0,
      child: SizedBox(
        width: (TwitchManager.instance is TwitchManagerMock) ? 320 : null,
        height: (TwitchManager.instance is TwitchManagerMock) ? 320 : null,
        child: Background(
          backgroundLayer: Opacity(
            opacity: 0.05,
            child: Image.asset(
              'assets/images/train.png',
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
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
          ),
        ),
      ),
    );
  }
}
