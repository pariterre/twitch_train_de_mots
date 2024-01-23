import 'package:flutter/material.dart';
import 'package:train_de_mots/managers/game_manager.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/managers/twitch_manager.dart';
import 'package:train_de_mots/models/success_level.dart';
import 'package:train_de_mots/widgets/animations_overlay.dart';
import 'package:train_de_mots/widgets/leader_board.dart';
import 'package:train_de_mots/widgets/letter_displayer.dart';
import 'package:train_de_mots/widgets/solutions_displayer.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);

    TwitchManager.instance.onTwitchManagerReady.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);

    TwitchManager.instance.onTwitchManagerReady.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return TwitchManager.instance.hasNotManager
        ? Center(child: CircularProgressIndicator(color: tm.mainColor))
        : TwitchManager.instance.debugOverlay(
            child: const Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 32),
                    _Header(),
                    SizedBox(height: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        LetterDisplayer(),
                        SizedBox(height: 20),
                        SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SolutionsDisplayer()),
                      ],
                    ),
                  ],
                ),
              ),
              Align(alignment: Alignment.topRight, child: LeaderBoard()),
              AnimationOverlay(),
            ],
          ));
  }
}

class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onRoundStarted.addListener(_refresh);
    gm.onSolutionFound.addListener(_onSolutionFound);
    gm.onRoundIsOver.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onRoundStarted.removeListener(_refresh);
    gm.onSolutionFound.removeListener(_onSolutionFound);
    gm.onRoundIsOver.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});
  void _onSolutionFound(solution) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    if (gm.problem == null) return Container();

    late String title;

    switch (gm.gameStatus) {
      case GameStatus.roundStarted:
        final pointsToGo =
            GameManager.instance.completedLevel == SuccessLevel.failed
                ? GameManager.instance.remainingPointsToNextLevel()
                : 0;

        late String toGoText;
        if (pointsToGo > 0) {
          toGoText = ' ($pointsToGo points avant destination)';
        } else {
          toGoText = ' (Destination atteinte!)';
        }

        title =
            ' En direction de la Station N\u00b0${gm.roundCount + 1}! $toGoText';
        break;
      case GameStatus.revealAnswers:
        title = 'Après avoir bien voyagé, le Train du Nord s\'arrête...';
        break;
      case GameStatus.roundReady:
      case GameStatus.roundPreparing:
      case GameStatus.initializing:
        title = 'Le Train de mots!';
        break;
    }

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: tm.titleSize,
              color: tm.textColor),
        ),
        const SizedBox(height: 20),
        Card(
          color: tm.mainColor,
          elevation: 10,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: _HeaderTimer(),
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

    final gm = GameManager.instance;
    gm.onRoundStarted.addListener(_refresh);
    gm.onNextProblemReady.addListener(_refresh);
    gm.onTimerTicks.addListener(_refresh);
    gm.onRoundIsOver.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onRoundStarted.removeListener(_refresh);
    gm.onNextProblemReady.removeListener(_refresh);
    gm.onTimerTicks.removeListener(_refresh);
    gm.onRoundIsOver.removeListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    final tm = ThemeManager.instance;

    int timeRemaining = gm.timeRemaining ?? 0;

    late String text;
    switch (gm.gameStatus) {
      case GameStatus.roundStarted:
        text = timeRemaining > 0
            ? 'Temps restant à la manche : $timeRemaining secondes'
            : 'Arrivée en gare';
        break;
      case GameStatus.roundPreparing:
        text = 'Préparation de la manche...';
        break;
      case GameStatus.roundReady:
        text = 'Prochaine manche prête!';
        break;
      case GameStatus.revealAnswers:
        text = 'Les solutions étaient :';
        break;
      case GameStatus.initializing:
        text = 'Initialisation...';
        break;
    }

    return Text(
      text,
      style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 26, color: tm.textColor),
    );
  }
}
