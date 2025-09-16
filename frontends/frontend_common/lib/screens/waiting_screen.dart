import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/widgets/growing_widget.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:frontend_common/managers/twitch_manager.dart';
import 'package:frontend_common/widgets/header.dart';

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
    gm.onGameStatusUpdated.listen(_refresh);
    gm.onAttemptingTheBigHeist.listen(_refresh);
    gm.onMiniGameStateUpdated.listen(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onGameStatusUpdated.cancel(_refresh);
    gm.onAttemptingTheBigHeist.cancel(_refresh);
    gm.onMiniGameStateUpdated.cancel(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});

  Widget _starWidget(bool isSuccess) => Icon(Icons.star,
      color: isSuccess ? Colors.amber : Colors.grey,
      size: 30.0,
      shadows: [Shadow(color: Colors.grey.shade500, blurRadius: 15.0)]);

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    late final String mainText;
    late final bool showStar;
    switch (gm.status) {
      case WordsTrainGameStatus.uninitialized:
        mainText = 'Bien le bonjour cheminot·e!\n'
            '\n'
            'Nous sommes en attente de\n'
            'votre cheminot·e en chef,\n'
            'veuillez patienter...';
        showStar = false;
        break;
      case WordsTrainGameStatus.initializing:
        mainText = 'Votre cheminot·e en chef est\n'
            'prêt·e pour le grand départ!\n'
            '\n'
            'Nous attendons son signal pour\n'
            'lancer le Petit Train du Nord';
        showStar = false;
        break;
      case WordsTrainGameStatus.roundPreparing:
      case WordsTrainGameStatus.roundReady:
      case WordsTrainGameStatus.roundEnding:
      case WordsTrainGameStatus.miniGameEnding:
        mainText = gm.isRoundSuccess
            ? 'Bravo, cheminot·e·s,\n'
                'vous avancez bien!\n'
                '\n'
                'Prochaine station ${gm.currentRound + 1}'
            : 'Malheur, cheminot·e·s!\n'
                'Votre aventure vers le\n'
                'Nord se termine ici...!\n'
                '\n'
                'Dernière station ${gm.currentRound}';
        showStar = true;
        break;
      case WordsTrainGameStatus.miniGamePreparing:
      case WordsTrainGameStatus.miniGameReady:
        mainText = 'Promenez-vous dans les bois...\n';
        showStar = false;
        break;
      case WordsTrainGameStatus.roundStarted:
      case WordsTrainGameStatus.miniGameStarted:
        mainText = '';
        showStar = false;
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
              padding:
                  const EdgeInsets.only(left: 20.0, top: 30.0, right: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showStar)
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: _starWidget(gm.isRoundSuccess),
                        ),
                      Text(mainText,
                          textAlign: TextAlign.left, style: tm.textFrontendSc),
                      if (showStar)
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: _starWidget(gm.isRoundSuccess),
                        ),
                    ],
                  ),
                  if (gm.status != WordsTrainGameStatus.uninitialized)
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
                                    'Un train est immobilisé sur les\n'
                                    'rails. Tenter un braquage pour\n'
                                    'doubler vos stations!',
                                    style: tm.textFrontendSc,
                                  ),
                                  const SizedBox(height: 8.0),
                                  ElevatedButton(
                                      onPressed: TwitchManager
                                          .instance.attemptTheBigHeist,
                                      child:
                                          const Text('Frapper le Grand Coup!')),
                                ],
                              ),
                            ),
                          ),
                        if (gm.isAttemptingTheBigHeist)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white.withAlpha(50),
                            ),
                            child: GrowingWidget(
                              growingFactor: 1.02,
                              duration: const Duration(milliseconds: 2000),
                              child: Text(
                                'Un des cheminot·e·s\n'
                                'a préparé un braquage!\n'
                                'Bonne chance, et ne\n'
                                'vous faites pas attraper!',
                                style: tm.textFrontendSc,
                              ),
                            ),
                          ),
                        if (!gm.canAttemptTheBigHeist &&
                            !gm.isAttemptingTheBigHeist &&
                            gm.currentRound >= 10)
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Column(
                              children: [
                                Text(
                                  'Félicitez vos collègues\n'
                                  'cheminot·e·s avec un',
                                  style: tm.textFrontendSc,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8.0),
                                ElevatedButton(
                                    onPressed: TwitchManager.instance.celebrate,
                                    child: const Text('Feux d\'artifice!')),
                              ],
                            ),
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
