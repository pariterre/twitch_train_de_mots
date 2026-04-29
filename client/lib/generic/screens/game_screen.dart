import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/screens/blueberry_war_game_screen.dart';
import 'package:train_de_mots/fix_tracks/screens/fix_tracks_game_screen.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/treasure_hunt/screens/treasure_hunt_game_screen.dart';
import 'package:train_de_mots/warehouse_cleaning/screens/warehouse_cleaning_game_screen.dart';
import 'package:train_de_mots/words_train/screens/words_train_game_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final twitchManager = Managers.instance.twitch;
    final tm = Managers.instance.train;

    return twitchManager.isNotConnected
        ? Center(
            child: CircularProgressIndicator(
                color: ThemeManager.instance.mainColor))
        : twitchManager.debugOverlay(
            child: tm.isRoundAMiniGame
                ? switch (Managers.instance.miniGames.currentOrPrevious) {
                    MiniGames.blueberryWar => const BlueberryWarGameScreen(),
                    MiniGames.treasureHunt => const TreasureHuntGameScreen(),
                    MiniGames.warehouseCleaning =>
                      const WarehouseCleaningGameScreen(),
                    MiniGames.fixTracks => const FixTracksGameScreen(),
                  }
                : const WordsTrainGameScreen(),
          );
  }
}
