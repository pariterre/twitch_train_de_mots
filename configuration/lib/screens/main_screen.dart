import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/widgets/background.dart';
import 'package:configuration/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    return Background(
      backgroundLayer: Opacity(
        opacity: 0.05,
        child: Image.asset(
          'packages/common/assets/images/train.png',
          height: MediaQuery.of(context).size.height,
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          const Header(titleText: 'Le Train de mots'),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 160.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Il n\'y a pas de configuration à faire ici. '
                    'Pour configurer et lancer le jeu, rendez-vous sur ',
                    textAlign: TextAlign.left,
                    style: tm.clientMainTextStyle.copyWith(fontSize: 26),
                  ),
                  // Change the cursor to a pointer when hovering over the link
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () => launchUrl(
                            Uri.parse('https://traindemots.pariterre.net')),
                        child: Text(
                          'https://traindemots.pariterre.net',
                          textAlign: TextAlign.left,
                          style: tm.clientMainTextStyle.copyWith(
                            fontSize: 26,
                            decoration: TextDecoration.underline,
                            decorationColor: tm.textColor,
                          ),
                        )),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
