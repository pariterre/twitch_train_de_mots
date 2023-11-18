import 'package:flutter/material.dart';
import 'package:train_de_mots/models/configuration.dart';
import 'package:train_de_mots/models/word_manipulation.dart';
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
  WordProblem? _currentProblem;
  TwitchManager? _twitchManager;

  Future<void> _pickANewWord() async {
    _currentProblem = null;
    setState(() {});

    _currentProblem = await WordProblem.generate();
    setState(() {});
  }

  Future<void> _getTwitchManager() async {
    _twitchManager = await showDialog<TwitchManager>(
        context: context,
        builder: (context) => TwitchAuthenticationScreen(
              isMockActive: Configuration.instance.isTwitchMockActive,
              debugPanelOptions: Configuration.instance.twitchDebugOptions,
              onFinishedConnexion: (manager) {
                Navigator.of(context).pop(manager);
              },
              appInfo: Configuration.instance.twitchAppInfo,
              reload: false,
            ));

    // Register to chat callback
    _twitchManager!.chat.onMessageReceived((sender, message) {
      if (_currentProblem?.trySolution(sender, message) ?? false) {
        setState(() {});
      }
    });
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_twitchManager == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _getTwitchManager());
    }
    if (_currentProblem == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickANewWord());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _twitchManager == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TwitchDebugOverlay(
              manager: _twitchManager!,
              child: _buildGameScreen(),
            ),
    );
  }

  Widget _buildGameScreen() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _currentProblem == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        WordDisplayer(word: _currentProblem!.word),
                        const SizedBox(height: 20),
                        SolutionsDisplayer(
                            solutions: _currentProblem!.solutions),
                      ],
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() {
                  _pickANewWord();
                }),
                child: const Text('New word'),
              )
            ],
          ),
        ),
        Align(
            alignment: Alignment.topRight,
            child: LeaderBoard(wordProblem: _currentProblem))
      ],
    );
  }
}
