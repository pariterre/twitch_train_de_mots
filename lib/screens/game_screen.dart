import 'package:flutter/material.dart';
import 'package:train_de_mots/models/color_scheme.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/twitch_interface.dart';
import 'package:train_de_mots/widgets/background.dart';
import 'package:train_de_mots/widgets/leader_board.dart';
import 'package:train_de_mots/widgets/solutions_displayer.dart';
import 'package:train_de_mots/widgets/splash_screen.dart';
import 'package:train_de_mots/widgets/word_displayer.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const route = '/game-screen';

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Future<void> _resquestTerminateRound() async =>
      await GameManager.instance.requestTerminateRound();

  Future<void> _resquestStartNewRound() async =>
      await GameManager.instance.requestStartNewRound();

  Future<void> _setTwitchManager() async {
    await TwitchInterface.instance.showConnectManagerDialog(context);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    GameManager.instance.onRoundIsPreparing.addListener(_onRoundIsPreparing);
    GameManager.instance.onNextProblemReady.addListener(_onRoundIsReady);
    GameManager.instance.onRoundStarted.addListener(_onRoundStarted);
    GameManager.instance.onTimerTicks.addListener(_onClockTicks);
    GameManager.instance.onSolutionFound.addListener(_onSolutionFound);
    GameManager.instance.onRoundIsOver.addListener(_onRoundIsOver);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TwitchInterface.instance.hasNotManager) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setTwitchManager());
    }
  }

  @override
  void dispose() {
    super.dispose();

    GameManager.instance.onRoundIsPreparing.removeListener(_onRoundIsPreparing);
    GameManager.instance.onNextProblemReady.removeListener(_onRoundIsReady);
    GameManager.instance.onRoundStarted.removeListener(_onRoundStarted);
    GameManager.instance.onTimerTicks.removeListener(_onClockTicks);
    GameManager.instance.onSolutionFound.removeListener(_onSolutionFound);
    GameManager.instance.onRoundIsOver.removeListener(_onRoundIsOver);
  }

  void _onRoundIsPreparing() => setState(() {});
  void _onRoundIsReady() => setState(() {});
  void _onRoundStarted() => setState(() {});
  void _onClockTicks() => setState(() {});
  void _onSolutionFound(_) => setState(() {});
  void _onRoundIsOver() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;

    return Scaffold(
      body: TwitchInterface.instance.hasNotManager
          ? Center(
              child: CircularProgressIndicator(
                  color: CustomColorScheme.instance.mainColor),
            )
          : TwitchInterface.instance.debugOverlay(
              child: SingleChildScrollView(
                  child: Background(
              child: gm.gameStatus == GameStatus.uninitialized
                  ? const SplashScreen()
                  : _buildGameScreen(),
            ))),
    );
  }

  Widget _buildGameScreen() {
    final gm = GameManager.instance;

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
              gm.hasNotAnActiveRound
                  ? Center(
                      child: CircularProgressIndicator(
                      color: CustomColorScheme.instance.mainColor,
                    ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        WordDisplayer(word: gm.problem!.word),
                        const SizedBox(height: 20),
                        const SizedBox(
                          height: 600,
                          child: SolutionsDisplayer(),
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
              Card(
                elevation: 10,
                child: ElevatedButton(
                  onPressed: gm.gameStatus == GameStatus.roundStarted
                      ? _resquestTerminateRound
                      : gm.isNextProblemReady
                          ? _resquestStartNewRound
                          : null,
                  style: CustomColorScheme.instance.elevatedButtonStyle,
                  child: Text(
                    gm.gameStatus == GameStatus.roundStarted
                        ? 'Terminer la manche'
                        : 'Prochaine manche',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              )
            ],
          ),
        ),
        const Align(alignment: Alignment.topRight, child: LeaderBoard()),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Le Train de mots! Tchou Tchou!',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: CustomColorScheme.instance.textColor),
        ),
        const SizedBox(height: 20),
        Card(
          color: CustomColorScheme.instance.mainColor,
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

    GameManager.instance.onRoundStarted.addListener(_onRoundStarted);
    GameManager.instance.onTimerTicks.addListener(_onClockTicks);
    GameManager.instance.onRoundIsOver.addListener(_onRoundIsOver);
  }

  @override
  void dispose() {
    super.dispose();

    GameManager.instance.onRoundStarted.removeListener(_onRoundStarted);
    GameManager.instance.onTimerTicks.removeListener(_onClockTicks);
    GameManager.instance.onRoundIsOver.removeListener(_onRoundIsOver);
  }

  void _onRoundStarted() => setState(() {});
  void _onClockTicks() => setState(() {});
  void _onRoundIsOver() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = GameManager.instance;
    return Text(
      gm.gameStatus == GameStatus.roundOver
          ? 'Manche terminée!'
          : gm.isNextProblemReady
              ? 'Prochaine manche prête!'
              : 'Temps restant à la manche : ${gm.gameTimer}',
      style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 26,
          color: CustomColorScheme.instance.textColor),
    );
  }
}
