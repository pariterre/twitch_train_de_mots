import 'package:common/models/game_status.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/words_train/screens/words_train_game_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Widget get _currentGameScreen {
    final gm = Managers.instance.train;

    switch (gm.gameStatus) {
      case GameStatus.uninitialized:
      case GameStatus.initializing:
      case GameStatus.roundPreparing:
      case GameStatus.roundReady:
      case GameStatus.roundStarted:
      case GameStatus.revealAnswers:
        return const WordsTrainGameScreen();

      case GameStatus.treasureSeeking:
        return const WordsTrainGameScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tm = Managers.instance.theme;

    return Managers.instance.twitch.isNotConnected
        ? Center(child: CircularProgressIndicator(color: tm.mainColor))
        : Managers.instance.twitch.debugOverlay(child: _currentGameScreen);
  }
}
