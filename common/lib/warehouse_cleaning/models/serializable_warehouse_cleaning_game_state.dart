import 'package:common/generic/managers/serializable_game_round_manager.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';

class SerializableWarehouseCleaningGameState
    implements SerializableMiniGameState {
  SerializableWarehouseCleaningGameState({
    required this.round,
    required this.grid,
    required this.triesRemaining,
  });

  @override
  MiniGames get type => MiniGames.warehouseCleaning;

  final SerializableGameRoundManager round;
  final WarehouseCleaningGrid grid;
  final int triesRemaining;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.warehouseCleaning.index,
      'round': round.serialize(),
      'grid': grid.serialize(),
      'tries_remaining': triesRemaining,
    };
  }

  static SerializableWarehouseCleaningGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableWarehouseCleaningGameState(
      round: SerializableGameRoundManager.deserialize(
          data['round'] as Map<String, dynamic>),
      grid: WarehouseCleaningGrid.deserialize(
          data['grid'] as Map<String, dynamic>),
      triesRemaining: data['tries_remaining'] as int,
    );
  }

  @override
  SerializableWarehouseCleaningGameState copyWith({
    SerializableGameRoundManager? round,
    WarehouseCleaningGrid? grid,
    int? triesRemaining,
  }) {
    return SerializableWarehouseCleaningGameState(
      round: round ?? this.round,
      grid: grid ?? this.grid,
      triesRemaining: triesRemaining ?? this.triesRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableWarehouseCleaningGameState &&
        other.round == round &&
        other.grid == grid &&
        other.triesRemaining == triesRemaining;
  }

  @override
  int get hashCode => round.hashCode ^ grid.hashCode ^ triesRemaining.hashCode;
}
