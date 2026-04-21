import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';

class SerializableWarehouseCleaningGameState
    implements SerializableMiniGameState {
  SerializableWarehouseCleaningGameState({
    required this.roundTimer,
    required this.grid,
    required this.triesRemaining,
  });

  @override
  MiniGames get type => MiniGames.warehouseCleaning;

  final SerializableControllableTimer roundTimer;
  final WarehouseCleaningGrid grid;
  final int triesRemaining;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.warehouseCleaning.index,
      'round_timer': roundTimer.serialize(),
      'grid': grid.serialize(),
      'tries_remaining': triesRemaining,
    };
  }

  static SerializableWarehouseCleaningGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableWarehouseCleaningGameState(
      roundTimer: SerializableControllableTimer.deserialize(
          data['round_timer'] as Map<String, dynamic>),
      grid: WarehouseCleaningGrid.deserialize(
          data['grid'] as Map<String, dynamic>),
      triesRemaining: data['tries_remaining'] as int,
    );
  }

  @override
  SerializableWarehouseCleaningGameState copyWith({
    SerializableControllableTimer? roundTimer,
    WarehouseCleaningGrid? grid,
    int? triesRemaining,
  }) {
    return SerializableWarehouseCleaningGameState(
      roundTimer: roundTimer ?? this.roundTimer,
      grid: grid ?? this.grid,
      triesRemaining: triesRemaining ?? this.triesRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableWarehouseCleaningGameState &&
        other.roundTimer == roundTimer &&
        other.grid == grid &&
        other.triesRemaining == triesRemaining;
  }

  @override
  int get hashCode =>
      roundTimer.hashCode ^ grid.hashCode ^ triesRemaining.hashCode;
}
