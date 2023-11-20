import 'package:flutter/material.dart';
import 'package:train_de_mots/models/game_manager.dart';
import 'package:train_de_mots/models/twitch_interface.dart';
import 'package:train_de_mots/widgets/leader_board.dart';
import 'package:train_de_mots/widgets/solutions_displayer.dart';
import 'package:train_de_mots/widgets/word_displayer.dart';
import 'package:twitch_manager/twitch_manager.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const route = '/game-screen';

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Future<void> _resquestNextRound() async {
    GameManager.instance.nextRound();
  }

  Future<void> _setTwitchManager() async {
    final manager = await showDialog<TwitchManager>(
        context: context,
        builder: (context) => TwitchAuthenticationScreen(
              isMockActive: TwitchInterface.instance.isMockActive,
              debugPanelOptions: TwitchInterface.instance.debugOptions,
              onFinishedConnexion: (manager) {
                Navigator.of(context).pop(manager);
              },
              appInfo: TwitchInterface.instance.appInfo,
              reload: false,
            ));
    if (manager == null) return;
    TwitchInterface.instance.manager = manager;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    GameManager.instance.onRoundIsReady(_onRoundIsReady);
    GameManager.instance.onSolutionFound(_onSolutionFound);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TwitchInterface.instance.hasNotManager) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setTwitchManager());
    }
    if (GameManager.instance.hasNotAnActiveRound) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resquestNextRound());
    }
  }

  @override
  void dispose() {
    super.dispose();

    GameManager.instance.removeOnSolutionFound(_onRoundIsReady);
    GameManager.instance.removeOnSolutionFound(_onSolutionFound);
  }

  void _onRoundIsReady() => setState(() {});
  void _onSolutionFound() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TwitchInterface.instance.hasNotManager
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TwitchInterface.instance.debugOverlay(
              child: SingleChildScrollView(child: _buildGameScreen())),
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
              const SizedBox(height: 20),
              gm.hasNotAnActiveRound
                  ? const Center(child: CircularProgressIndicator())
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
                onPressed: () => setState(() {
                  _resquestNextRound();
                }),
                child: const Text('New word'),
              )
            ],
          ),
        ),
        const Align(alignment: Alignment.topRight, child: LeaderBoard())
      ],
    );
  }
}
