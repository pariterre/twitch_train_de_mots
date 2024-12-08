import 'package:common/managers/theme_manager.dart';
import 'package:common/models/game_status.dart';
import 'package:common/widgets/growing_widget.dart';
import 'package:flutter/material.dart';
import 'package:frontend/managers/game_manager.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:frontend/widgets/header.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onGameStatusUpdated.addListener(_refresh);
    gm.onAttemptingTheBigHeist.addListener(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onGameStatusUpdated.removeListener(_refresh);
    gm.onAttemptingTheBigHeist.removeListener(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    late final String textToShow;
    switch (gm.status) {
      case GameStatus.uninitialized:
        textToShow = 'Bien le bonjour cheminot\u00b7e,\n'
            '\n'
            'Nous sommes en attente de votre cheminot\u00b7e en chef, veuillez patienter...';
        break;
      case GameStatus.initializing:
      case GameStatus.roundStarted:
      case GameStatus.roundPreparing:
      case GameStatus.roundReady:
      case GameStatus.revealAnswers:
        textToShow =
            'Votre cheminot\u00b7e en chef est\nprêt\u00b7e pour le grand départ vers le Nord!\n'
            '\n'
            'Prochain arrêt: Station ${gm.currentRound + 1}';
        break;
    }

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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    textToShow,
                    textAlign: TextAlign.left,
                    style: tm.textFrontendSc,
                  ),
                  if (gm.status != GameStatus.uninitialized)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        if (gm.canAttemptTheBigHeist)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white.withAlpha(50),
                            ),
                            child: GrowingWidget(
                              growingFactor: 1.02,
                              duration: const Duration(milliseconds: 2000),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Un train est immobilisé sur les rails.\n'
                                    'Tenter un braquage pour doubler\nvos stations!',
                                    style: tm.textFrontendSc,
                                  ),
                                  const SizedBox(height: 8.0),
                                  ElevatedButton(
                                      onPressed: () async {
                                        TwitchManager
                                            .instance.frontendManager.bits
                                            .useBits('big_heist');
                                      },
                                      child:
                                          const Text('Frapper le Grand Coup!')),
                                ],
                              ),
                            ),
                          ),
                        if (!gm.canAttemptTheBigHeist && gm.previousRound >= 10)
                          Column(
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                  'Félicitez vos collègues cheminot\u00b7e\u00b7s '
                                  'avec un feux d\'artifice!',
                                  style: tm.textFrontendSc),
                              const SizedBox(height: 8.0),
                              ElevatedButton(
                                  onPressed: () async {
                                    TwitchManager.instance.frontendManager.bits
                                        .useBits('celebrate');
                                  },
                                  child: const Text('Feux d\'artifice!')),
                            ],
                          ),
                      ],
                    )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
