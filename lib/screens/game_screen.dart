import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';
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
  Widget build(BuildContext context) {
    final gm = ref.watch(gameManagerProvider);
    final scheme = ref.watch(schemeProvider);

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
                      color: scheme.mainColor,
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

    ref.read(gameManagerProvider).onRoundStarted.addListener(_onRoundStarted);
    ref.read(gameManagerProvider).onSolutionFound.addListener(_onSolutionFound);
    ref.read(gameManagerProvider).onRoundIsOver.addListener(_onRoundEnded);
  }

  @override
  void dispose() {
    super.dispose();

    ref
        .read(gameManagerProvider)
        .onRoundStarted
        .removeListener(_onRoundStarted);
    ref
        .read(gameManagerProvider)
        .onSolutionFound
        .removeListener(_onSolutionFound);
    ref.read(gameManagerProvider).onRoundIsOver.removeListener(_onRoundEnded);
  }

  void _onRoundStarted() => setState(() {});
  void _onSolutionFound(_) => setState(() {});
  void _onRoundEnded() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = ref.watch(gameManagerProvider);
    final scheme = ref.watch(schemeProvider);

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
                    fontSize: scheme.titleSize,
                    color: scheme.textColor),
              ),
            if (gm.gameStatus == GameStatus.roundStarted)
              Text(
                ' En direction de la Station N\u00b0${gm.roundCount + 1}! $toGoText',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: scheme.titleSize,
                    color: scheme.textColor),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          color: scheme.mainColor,
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

    ref.read(gameManagerProvider).onRoundStarted.addListener(_onRoundStarted);
    ref
        .read(gameManagerProvider)
        .onNextProblemReady
        .addListener(_onNextProblemReady);
    ref.read(gameManagerProvider).onTimerTicks.addListener(_onClockTicks);
    ref.read(gameManagerProvider).onRoundIsOver.addListener(_onRoundIsOver);
  }

  @override
  void dispose() {
    super.dispose();

    ref
        .read(gameManagerProvider)
        .onRoundStarted
        .removeListener(_onRoundStarted);
    ref
        .read(gameManagerProvider)
        .onNextProblemReady
        .removeListener(_onNextProblemReady);
    ref.read(gameManagerProvider).onTimerTicks.removeListener(_onClockTicks);
    ref.read(gameManagerProvider).onRoundIsOver.removeListener(_onRoundIsOver);
  }

  void _onRoundStarted() => setState(() {});
  void _onNextProblemReady() => setState(() {});
  void _onClockTicks() => setState(() {});
  void _onRoundIsOver() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = ref.watch(gameManagerProvider);
    final scheme = ref.watch(schemeProvider);

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
          fontWeight: FontWeight.bold, fontSize: 26, color: scheme.textColor),
    );
  }
}
