import 'package:common/managers/theme_manager.dart';
import 'package:common/models/game_status.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/treasure_hunt/screens/treasure_hunt_game_screen.dart';
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
      case WordsTrainGameStatus.uninitialized:
      case WordsTrainGameStatus.initializing:
      case WordsTrainGameStatus.roundPreparing:
      case WordsTrainGameStatus.roundReady:
      case WordsTrainGameStatus.roundStarted:
      case WordsTrainGameStatus.roundEnding:
        return const WordsTrainGameScreen();

      case WordsTrainGameStatus.miniGamePreparing:
      case WordsTrainGameStatus.miniGameReady:
      case WordsTrainGameStatus.miniGameStarted:
      case WordsTrainGameStatus.miniGameEnding:
        return const TreasureHuntGameScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Managers.instance.twitch.isNotConnected
        ? Center(child: CircularProgressIndicator(color: tm.mainColor))
        : Managers.instance.twitch.debugOverlay(child: _currentGameScreen);
  }
}
