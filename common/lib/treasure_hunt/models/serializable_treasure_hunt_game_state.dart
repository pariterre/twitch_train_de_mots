import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart';

class SerializableTreasureHuntGameState implements SerializableMiniGameState {
  SerializableTreasureHuntGameState({
    required this.roundTimer,
    required this.grid,
    required this.triesRemaining,
  });

  @override
  MiniGames get type => MiniGames.treasureHunt;

  final SerializableControllableTimer roundTimer;
  final TreasureHuntGrid grid;
  final int triesRemaining;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.treasureHunt.index,
      'round_timer': roundTimer.serialize(),
      'grid': grid.serialize(),
      'tries_remaining': triesRemaining,
    };
  }

  static SerializableTreasureHuntGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableTreasureHuntGameState(
      grid: TreasureHuntGrid.deserialize(data['grid'] as Map<String, dynamic>),
      roundTimer: SerializableControllableTimer.deserialize(
          data['round_timer'] as Map<String, dynamic>),
      triesRemaining: data['tries_remaining'] as int,
    );
  }

  @override
  SerializableTreasureHuntGameState copyWith({
    SerializableControllableTimer? roundTimer,
    TreasureHuntGrid? grid,
    int? triesRemaining,
  }) {
    return SerializableTreasureHuntGameState(
      roundTimer: roundTimer ?? this.roundTimer,
      grid: grid ?? this.grid,
      triesRemaining: triesRemaining ?? this.triesRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableTreasureHuntGameState &&
        other.roundTimer == roundTimer &&
        other.grid == grid &&
        other.triesRemaining == triesRemaining;
  }

  @override
  int get hashCode =>
      roundTimer.hashCode ^ grid.hashCode ^ triesRemaining.hashCode;
}
