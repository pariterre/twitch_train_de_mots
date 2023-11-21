import 'package:flutter/material.dart';
import 'package:train_de_mots/models/color_scheme.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/twitch_interface.dart';
import 'package:train_de_mots/widgets/leader_board.dart';
import 'package:train_de_mots/widgets/solutions_displayer.dart';
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

    GameManager.instance.onRoundIsPreparing(_onRoundIsPreparing);
    GameManager.instance.onRoundIsReady(_onRoundIsReady);
    GameManager.instance.onTimerTicks(_onClockTicks);
    GameManager.instance.onSolutionFound(_onSolutionFound);
    GameManager.instance.onRoundIsOver(_onRoundIsOver);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TwitchInterface.instance.hasNotManager) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setTwitchManager());
    }
    if (GameManager.instance.hasNotAnActiveRound) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _resquestStartNewRound());
    }
  }

  @override
  void dispose() {
    super.dispose();

    GameManager.instance.removeOnRoundIsPreparing(_onRoundIsPreparing);
    GameManager.instance.removeOnRoundIsReady(_onRoundIsReady);
    GameManager.instance.removeOnTimerTicks(_onClockTicks);
    GameManager.instance.removeOnSolutionFound(_onSolutionFound);
    GameManager.instance.removeOnRoundIsOver(_onRoundIsOver);
  }

  void _onRoundIsPreparing() => setState(() {});
  void _onRoundIsReady() => setState(() {});
  void _onClockTicks() => setState(() {});
  void _onSolutionFound() => setState(() {});
  void _onRoundIsOver() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TwitchInterface.instance.hasNotManager
          ? Center(
              child: CircularProgressIndicator(
                  color: CustomColorScheme.instance.mainColor),
            )
          : TwitchInterface.instance.debugOverlay(
              child: SingleChildScrollView(child: _buildGameScreen())),
    );
  }

  Widget _buildGameScreen() {
    final windowSize = MediaQuery.of(context).size;
    final gm = GameManager.instance;

    return Stack(
      children: [
        Container(
          width: windowSize.width,
          height: windowSize.height,
          decoration:
              BoxDecoration(color: CustomColorScheme.instance.backgroundColor),
        ),
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Le Train de mots! Tchou Tchou!',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: CustomColorScheme.instance.textColor),
              ),
              const SizedBox(height: 20),
              Text(
                GameManager.instance.gameTimer == null
                    ? 'Manche terminée!'
                    : 'Temps restant à la manche : ${GameManager.instance.gameTimer}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: CustomColorScheme.instance.textColor),
              ),
              const SizedBox(height: 20),
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
                        SizedBox(
                          height: 600,
                          child: SolutionsDisplayer(
                              solutions: gm.problem!.solutions),
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    GameManager.instance.gameStatus == GameStatus.roundStarted
                        ? _resquestTerminateRound
                        : _resquestStartNewRound,
                style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColorScheme.instance.mainColor),
                child: Text(
                    GameManager.instance.gameStatus == GameStatus.roundStarted
                        ? 'Terminer la manche'
                        : 'Prochaine manche'),
              )
            ],
          ),
        ),
        const Align(alignment: Alignment.topRight, child: LeaderBoard())
      ],
    );
  }
}
