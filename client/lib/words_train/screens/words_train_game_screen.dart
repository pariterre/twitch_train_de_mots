import 'dart:math';

import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/mini_games.dart';
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
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 75, right: 75, top: 15.0, bottom: 20.0),
                  child: _Header(),
                ),
              ),
              Expanded(child: SolutionsDisplayer()),
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

    final cm = Managers.instance.configuration;
    cm.onChanged.listen(_refresh);
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

    final cm = Managers.instance.configuration;
    cm.onChanged.cancel(_refresh);
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

    String title = gm.isRoundAMiniGame
        ? switch (gm.nextRoundMiniGame!) {
            MiniGames.blueberryWar => 'La Guerre des Bleuets!',
            MiniGames.treasureHunt => 'La Chasse au Trésor!',
            MiniGames.warehouseCleaning => 'Nettoyons ce Hangar!',
            MiniGames.fixTracks => 'Réparons les Rails!',
          }
        : switch (gm.gameStatus) {
            WordsTrainGameStatus.uninitialized ||
            WordsTrainGameStatus.initializing =>
              'Le Train de mots!',
            WordsTrainGameStatus.roundStarted =>
              ' En direction de la Station N\u00b0${gm.roundCount + 1}!',
            WordsTrainGameStatus.roundReady ||
            WordsTrainGameStatus.roundPreparing ||
            WordsTrainGameStatus.roundEnding =>
              gm.hasPlayedAtLeastOnce
                  ? 'Après un long voyage, Le Train du Nord se repose'
                  : 'Le Train de mots!',
          };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Visibility.maintain(
            visible: Managers.instance.configuration.showLeaderBoard,
            child: LeaderBoard(height: 250)),
        SizedBox(width: MediaQuery.of(context).size.width * 0.05),
        Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: tm.clientMainTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: tm.titleSize,
                  color: tm.textColor),
            ),
            ThemeCard(child: _HeaderTimer()),
            SizedBox(height: 15),
            TrainPath(controller: _trainPath, pathLength: 600, height: 75),
            LetterDisplayer(),
          ],
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.05),
        Visibility.maintain(
          visible: Managers.instance.configuration.canUseControllerHelper,
          child: HelpFromTheControllerCard(),
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
    gm.onRoundIsOver.listen(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.listen(_refresh);

    Managers.instance.tickerManager.onClockTicked.listen(_onClockTicked);
  }

  @override
  void dispose() {
    final gm = Managers.instance.train;
    gm.onRoundStarted.cancel(_refresh);
    gm.onNextProblemReady.cancel(_refresh);
    gm.onRoundIsOver.cancel(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.cancel(_refresh);

    Managers.instance.tickerManager.onClockTicked.cancel(_onClockTicked);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;

    setState(() {});
  }

  void _onClockTicked(Duration deltaTime) => _refresh();

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.train;
    final tm = ThemeManager.instance;
    final mgm = Managers.instance.miniGames.manager;

    final timeRemainning =
        (gm.isRoundAMiniGame ? mgm?.timeRemaining : gm.timeRemaining) ??
            Duration(seconds: -1);
    final timeRemainingInSeconds =
        timeRemainning.isNegative ? 0 : timeRemainning.inSeconds + 1;

    String text = switch (gm.gameStatus) {
      WordsTrainGameStatus.roundPreparing => 'Préparation de la manche...',
      WordsTrainGameStatus.roundReady => 'Prochaine manche prête!',
      WordsTrainGameStatus.roundStarted => timeRemainingInSeconds > 0
          ? 'Temps restant à la manche : $timeRemainingInSeconds secondes'
          : 'Arrivée en gare',
      WordsTrainGameStatus.roundEnding => gm.isRoundAMiniGame
          ? 'Retournons à la gare'
          : 'Les solutions étaient :',
      WordsTrainGameStatus.uninitialized ||
      WordsTrainGameStatus.initializing =>
        'Initialisation...',
    };

    return Text(
      text,
      style: tm.clientMainTextStyle.copyWith(
          fontWeight: FontWeight.bold, fontSize: 26, color: tm.textColor),
    );
  }
}
