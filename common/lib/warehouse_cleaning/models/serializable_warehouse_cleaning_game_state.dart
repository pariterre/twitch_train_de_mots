import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';

class SerializableWarehouseCleaningGameState
    implements SerializableMiniGameState {
  SerializableWarehouseCleaningGameState({
    required this.grid,
    required this.isTimerRunning,
    required this.timeRemaining,
    required this.triesRemaining,
  });

  @override
  MiniGames get type => MiniGames.warehouseCleaning;

  final WarehouseCleaningGrid grid;

  final bool isTimerRunning;
  final Duration timeRemaining;
  final int triesRemaining;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.warehouseCleaning.index,
      'grid': grid.serialize(),
      'is_timer_running': isTimerRunning,
      'time_remaining': timeRemaining.inSeconds,
      'tries_remaining': triesRemaining,
    };
  }

  static SerializableWarehouseCleaningGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableWarehouseCleaningGameState(
      grid: WarehouseCleaningGrid.deserialize(
          data['grid'] as Map<String, dynamic>),
      isTimerRunning: data['is_timer_running'] as bool,
      timeRemaining: Duration(seconds: data['time_remaining'] as int),
      triesRemaining: data['tries_remaining'] as int,
    );
  }

  @override
  SerializableWarehouseCleaningGameState copyWith({
    WarehouseCleaningGrid? grid,
    bool? isTimerRunning,
    Duration? timeRemaining,
    int? triesRemaining,
  }) {
    return SerializableWarehouseCleaningGameState(
      grid: grid ?? this.grid,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      triesRemaining: triesRemaining ?? this.triesRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableWarehouseCleaningGameState &&
        other.grid == grid &&
        other.isTimerRunning == isTimerRunning &&
        other.timeRemaining == timeRemaining &&
        other.triesRemaining == triesRemaining;
  }

  @override
  int get hashCode =>
      grid.hashCode ^
      isTimerRunning.hashCode ^
      timeRemaining.hashCode ^
      triesRemaining.hashCode;
}
