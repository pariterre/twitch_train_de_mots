import 'dart:math';

import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/theme_card.dart';
import 'package:train_de_mots/words_train/models/success_level.dart';
import 'package:train_de_mots/words_train/models/word_solution.dart';
import 'package:train_de_mots/words_train/widgets/help_from_the_controller_card.dart';
import 'package:train_de_mots/words_train/widgets/leader_board.dart';
import 'package:train_de_mots/words_train/widgets/letter_displayer.dart';
import 'package:train_de_mots/words_train/widgets/solutions_displayer.dart';
import 'package:train_de_mots/words_train/widgets/train_path.dart';
import 'package:train_de_mots/words_train/widgets/words_train_animated_text_overlay.dart';

class WordsTrainGameScreen extends StatefulWidget {
  const WordsTrainGameScreen({super.key});

  @override
  State<WordsTrainGameScreen> createState() => _WordsTrainGameScreenState();
}

class _WordsTrainGameScreenState extends State<WordsTrainGameScreen> {
  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.listen(_refresh);

    Managers.instance.twitch.onTwitchManagerHasTriedConnecting
        .listen(_hasTriedConnecting);
  }

  @override
  void dispose() {
    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);

    Managers.instance.twitch.onTwitchManagerHasTriedConnecting
        .cancel(_hasTriedConnecting);

    super.dispose();
  }

  void _hasTriedConnecting({required bool isSuccess}) => setState(() {});
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 50.0),
              child: LeaderBoard(),
            )),
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              _Header(),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  LetterDisplayer(),
                  SizedBox(height: 15),
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SolutionsDisplayer()),
                ],
              ),
            ],
          ),
        ),
        WordsTrainAnimatedTextOverlay(),
      ],
    );
  }
}

class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  int _previousScore = 0;
  final _trainPath = TrainPathController(millisecondsPerStep: 300);

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.train;
    gm.onSolutionFound.listen(_onSolutionFound);
    gm.onStealerPardoned.listen(_onSolutionFound);
    gm.onRoundStarted.listen(_refresh);
    gm.onRoundStarted.listen(_setTrainPath);
    _setTrainPath();

    final tm = ThemeManager.instance;
    tm.onChanged.listen(_refresh);
  }

  @override
  void dispose() {
    final gm = Managers.instance.train;
    gm.onSolutionFound.cancel(_onSolutionFound);
    gm.onStealerPardoned.cancel(_onSolutionFound);
    gm.onRoundStarted.cancel(_refresh);
    gm.onRoundStarted.cancel(_setTrainPath);

    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});
  void _onSolutionFound(WordSolution? solution) {
    if (solution == null) return;

    final gm = Managers.instance.train;
    int currentScore = min(Managers.instance.train.problem!.teamScore,
        gm.problem?.solutions.totalScore ?? 1);
    if (_previousScore < currentScore) {
      for (int i = _previousScore; i < currentScore; i++) {
        _trainPath.moveForward();
      }
    } else {
      for (int i = _previousScore; i > currentScore; i--) {
        _trainPath.moveBackward();
      }
    }
    _previousScore = currentScore;

    setState(() {});
  }

  void _setTrainPath() {
    final gm = Managers.instance.train;

    _previousScore = 0;
    _trainPath.nbSteps = gm.problem?.solutions.totalScore ?? 1;
    _trainPath.starHallMarks = gm.isAttemptingTheBigHeist
        ? [gm.pointsToObtain(SuccessLevel.threeStars)]
        : [
            gm.pointsToObtain(SuccessLevel.oneStar),
            gm.pointsToObtain(SuccessLevel.twoStars),
            gm.pointsToObtain(SuccessLevel.threeStars),
          ];
    _trainPath.boostHallMark = gm.pointsToObtainBoost();
  }

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;
    final tm = ThemeManager.instance;

    if (gm.problem == null) return Container();

    late String title;
    switch (gm.gameStatus) {
      case WordsTrainGameStatus.roundStarted:
        title = ' En direction de la Station N\u00b0${gm.roundCount + 1}!';
        break;
      case WordsTrainGameStatus.roundEnding:
        title = 'Après avoir bien voyagé, le Train du Nord s\'arrête...';
        break;
      case WordsTrainGameStatus.uninitialized:
      case WordsTrainGameStatus.initializing:
      case WordsTrainGameStatus.roundReady:
      case WordsTrainGameStatus.roundPreparing:
        title = 'Le Train de mots!';
        break;
      case WordsTrainGameStatus.miniGamePreparing:
        title = 'Ouverture du sentier...';
        break;
      case WordsTrainGameStatus.miniGameReady:
      case WordsTrainGameStatus.miniGameStarted:
      case WordsTrainGameStatus.miniGameEnding:
        title = 'Promenons-nous dans les bois!';
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: tm.clientMainTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: tm.titleSize,
              color: tm.textColor),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              const SizedBox(width: 1300),
              if (Managers.instance.configuration.canUseControllerHelper)
                const Positioned(
                    right: 0, top: 0, child: HelpFromTheControllerCard()),
              Column(
                children: [
                  ThemeCard(child: _HeaderTimer()),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: TrainPath(
                        controller: _trainPath, pathLength: 600, height: 75),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderTimer extends StatefulWidget {
  const _HeaderTimer();

  @override
  State<_HeaderTimer> createState() => _HeaderTimerState();
}

class _HeaderTimerState extends State<_HeaderTimer> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.train;
    gm.onRoundStarted.listen(_refresh);
    gm.onNextProblemReady.listen(_refresh);
    gm.onClockTicked.listen(_refresh);
    gm.onRoundIsOver.listen(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.listen(_refresh);
  }

  @override
  void dispose() {
    final gm = Managers.instance.train;
    gm.onRoundStarted.cancel(_refresh);
    gm.onNextProblemReady.cancel(_refresh);
    gm.onClockTicked.cancel(_refresh);
    gm.onRoundIsOver.cancel(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;
    final tm = ThemeManager.instance;
    final mgm = Managers.instance.miniGames.manager;

    late String text;
    switch (gm.gameStatus) {
      case WordsTrainGameStatus.roundStarted:
        int timeRemaining = gm.timeRemaining?.inSeconds ?? 0;
        text = timeRemaining > 0
            ? 'Temps restant à la manche : $timeRemaining secondes'
            : 'Arrivée en gare';
        break;
      case WordsTrainGameStatus.roundPreparing:
        text = 'Préparation de la manche...';
        break;
      case WordsTrainGameStatus.roundReady:
        text = 'Prochaine manche prête!';
        break;
      case WordsTrainGameStatus.roundEnding:
        text = 'Les solutions étaient :';
        break;
      case WordsTrainGameStatus.uninitialized:
      case WordsTrainGameStatus.initializing:
        text = 'Initialisation...';
        break;
      case WordsTrainGameStatus.miniGamePreparing:
      case WordsTrainGameStatus.miniGameReady:
      case WordsTrainGameStatus.miniGameStarted:
      case WordsTrainGameStatus.miniGameEnding:
        Duration timeRemaining = mgm!.timeRemaining;
        text = timeRemaining.inSeconds > 0
            ? 'Temps restant à la manche : ${timeRemaining.inSeconds} secondes'
            : 'Retournons à la gare!';
        break;
    }

    return Text(
      text,
      style: tm.clientMainTextStyle.copyWith(
          fontWeight: FontWeight.bold, fontSize: 26, color: tm.textColor),
    );
  }
}
