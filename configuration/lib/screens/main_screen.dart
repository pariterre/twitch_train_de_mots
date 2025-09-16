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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ô cheminot·e en chef, bienvenue au Train de mots !\n'
                        'Il nous fait grand plaisir de vous accueillir pour ce voyage avec le Petit train du Nord.\n'
                        '\n'
                        'Lorsque vous activerez cette extension, pour une expérience optimale, '
                        'vous êtes invité·e à choisir l\'option "Overlay". Si cela n\'est pas '
                        'possible, alors le mode "Composant" sera la meilleure alternative.\n\n'
                        'Il n\'y a pas d\'autres configurations à faire sur cette page! '
                        'Pour lancer le jeu, rendez-vous sur :',
                        textAlign: TextAlign.left,
                        style: tm.clientMainTextStyle.copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 16),
                      // Change the cursor to a pointer when hovering over the link
                      Center(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                              onTap: () => launchUrl(Uri.parse(
                                  'https://traindemots.pariterre.net')),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
