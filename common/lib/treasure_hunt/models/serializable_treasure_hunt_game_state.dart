import 'package:common/generic/managers/serializable_game_round_manager.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart';

class SerializableTreasureHuntGameState implements SerializableMiniGameState {
  SerializableTreasureHuntGameState({
    required this.round,
    required this.grid,
    required this.triesRemaining,
  });

  @override
  MiniGames get type => MiniGames.treasureHunt;

  final SerializableGameRoundManager round;
  final TreasureHuntGrid grid;
  final int triesRemaining;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.treasureHunt.index,
      'round': round.serialize(),
      'grid': grid.serialize(),
      'tries_remaining': triesRemaining,
    };
  }

  static SerializableTreasureHuntGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableTreasureHuntGameState(
      grid: TreasureHuntGrid.deserialize(data['grid'] as Map<String, dynamic>),
      round: SerializableGameRoundManager.deserialize(
          data['round'] as Map<String, dynamic>),
      triesRemaining: data['tries_remaining'] as int,
    );
  }

  @override
  SerializableTreasureHuntGameState copyWith({
    SerializableGameRoundManager? round,
    TreasureHuntGrid? grid,
    int? triesRemaining,
  }) {
    return SerializableTreasureHuntGameState(
      round: round ?? this.round,
      grid: grid ?? this.grid,
      triesRemaining: triesRemaining ?? this.triesRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableTreasureHuntGameState &&
        other.round == round &&
        other.grid == grid &&
        other.triesRemaining == triesRemaining;
  }

  @override
  int get hashCode => round.hashCode ^ grid.hashCode ^ triesRemaining.hashCode;
}
