import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/screens/blueberry_war_game_screen.dart';
import 'package:train_de_mots/track_fix/screens/track_fix_game_screen.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/treasure_hunt/screens/treasure_hunt_game_screen.dart';
import 'package:train_de_mots/words_train/screens/words_train_game_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final twitchManager = Managers.instance.twitch;
    final tm = ThemeManager.instance;

    return twitchManager.isNotConnected
        ? Center(child: CircularProgressIndicator(color: tm.mainColor))
        : twitchManager.debugOverlay(
            child: switch (Managers.instance.train.gameStatus) {
            WordsTrainGameStatus.uninitialized ||
            WordsTrainGameStatus.initializing ||
            WordsTrainGameStatus.roundPreparing ||
            WordsTrainGameStatus.roundReady ||
            WordsTrainGameStatus.roundStarted ||
            WordsTrainGameStatus.roundEnding =>
              const WordsTrainGameScreen(),
            WordsTrainGameStatus.miniGamePreparing ||
            WordsTrainGameStatus.miniGameReady ||
            WordsTrainGameStatus.miniGameStarted ||
            WordsTrainGameStatus.miniGameEnding =>
              switch (Managers.instance.miniGames.currentOrPrevious) {
                MiniGames.blueberryWar => const BlueberryWarGameScreen(),
                MiniGames.treasureHunt => const TreasureHuntGameScreen(),
                // MiniGames.trackFix => const TrackFixGameScreen(),
              }
          });
  }
}
