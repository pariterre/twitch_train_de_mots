import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/widgets/animations_overlay.dart';
import 'package:train_de_mots/widgets/leader_board.dart';
import 'package:train_de_mots/widgets/solutions_displayer.dart';
import 'package:train_de_mots/widgets/word_displayer.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = ref.watch(gameManagerProvider);
    final tm = ThemeManager.instance;

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              const _Header(),
              const SizedBox(height: 32),
              gm.problem == null
                  ? Center(
                      child: CircularProgressIndicator(
                      color: tm.mainColor,
                    ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        WordDisplayer(problem: gm.problem!),
                        const SizedBox(height: 20),
                        const SizedBox(
                          height: 600,
                          child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SolutionsDisplayer()),
                        ),
                      ],
                    ),
            ],
          ),
        ),
        const Align(alignment: Alignment.topRight, child: LeaderBoard()),
        const AnimationOverlay(),
      ],
    );
  }
}

class _Header extends ConsumerStatefulWidget {
  const _Header();

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  @override
  void initState() {
    super.initState();

    final gm = ref.read(gameManagerProvider);
    gm.onRoundStarted.addListener(_refresh);
    gm.onSolutionFound.addListener(_onSolutionFound);
    gm.onRoundIsOver.addListener(_refresh);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    final gm = ref.read(gameManagerProvider);
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
    final gm = ref.watch(gameManagerProvider);
    final tm = ThemeManager.instance;

    final pointsToGo =
        gm.problem!.thresholdScoreForOneStar - gm.problem!.currentScore;
    late String toGoText;
    if (pointsToGo > 0) {
      toGoText = ' ($pointsToGo points avant destination)';
    } else {
      toGoText = ' (Destination atteinte!)';
    }
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gm.gameStatus != GameStatus.roundStarted)
              Text(
                'Le Train de mots!',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: tm.titleSize,
                    color: tm.textColor),
              ),
            if (gm.gameStatus == GameStatus.roundStarted)
              Text(
                ' En direction de la Station N\u00b0${gm.roundCount + 1}! $toGoText',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: tm.titleSize,
                    color: tm.textColor),
              ),
          ],
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

class _HeaderTimer extends ConsumerStatefulWidget {
  const _HeaderTimer();

  @override
  ConsumerState<_HeaderTimer> createState() => _HeaderTimerState();
}

class _HeaderTimerState extends ConsumerState<_HeaderTimer> {
  @override
  void initState() {
    super.initState();

    final gm = ref.read(gameManagerProvider);
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

    final gm = ref.read(gameManagerProvider);
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
    final gm = ref.watch(gameManagerProvider);
    final tm = ThemeManager.instance;

    late String text;
    switch (gm.gameStatus) {
      case GameStatus.roundStarted:
        text = 'Temps restant à la manche : ${gm.timeRemaining}';
        break;
      case GameStatus.roundPreparing:
        text = 'Préparation de la manche...';
        break;
      case GameStatus.roundReady:
        text = 'Prochaine manche prête!';
        break;
      default:
        text = 'Erreur';
    }

    return Text(
      text,
      style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 26, color: tm.textColor),
    );
  }
}
