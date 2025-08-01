import 'package:common/blueberry_war/models/serializable_blueberry_war_game_state.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/treasure_hunt/models/serializable_treasure_hunt_game_state.dart';

abstract class SerializableMiniGameState {
  MiniGames get type;

  Map<String, dynamic> serialize();

  static SerializableMiniGameState deserialize(Map<String, dynamic> data) {
    switch (MiniGames.values[data['type']]) {
      case MiniGames.treasureHunt:
        return SerializableTreasureHuntGameState.deserialize(data);
      case MiniGames.blueberryWar:
        return SerializableBlueberryWarGameState.deserialize(data);
    }
  }

  SerializableMiniGameState copyWith();
}
