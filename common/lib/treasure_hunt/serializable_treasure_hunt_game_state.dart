import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/treasure_hunt/serializable_tile.dart';

class SerializableTreasureHuntGameState implements SerializableMiniGameState {
  SerializableTreasureHuntGameState({
    required this.nbRows,
    required this.nbCols,
    required this.rewardsCount,
    required this.isTimerRunning,
    required this.timeRemaining,
    required this.triesRemaining,
    required this.grid,
  });

  @override
  MiniGames get type => MiniGames.treasureHunt;

  final int nbRows;
  final int nbCols;
  final int rewardsCount;

  final bool isTimerRunning;
  final Duration timeRemaining;
  final int triesRemaining;

  final List<SerializableTile> grid;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.treasureHunt.index,
      'nb_rows': nbRows,
      'nb_cols': nbCols,
      'rewards_count': rewardsCount,
      'is_timer_running': isTimerRunning,
      'time_remaining': timeRemaining.inSeconds,
      'tries_remaining': triesRemaining,
      'grid': grid.map((tile) => tile.serialize()).toList(),
    };
  }

  static SerializableTreasureHuntGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableTreasureHuntGameState(
      nbRows: data['nb_rows'] as int,
      nbCols: data['nb_cols'] as int,
      rewardsCount: data['rewards_count'] as int,
      isTimerRunning: data['is_timer_running'] as bool,
      timeRemaining: Duration(seconds: data['time_remaining'] as int),
      triesRemaining: data['tries_remaining'] as int,
      grid: (data['grid'] as List)
          .map((tile) => SerializableTile.deserialize(tile))
          .toList(growable: false),
    );
  }

  @override
  SerializableTreasureHuntGameState copyWith({
    int? nbRows,
    int? nbCols,
    int? rewardsCount,
    bool? isTimerRunning,
    Duration? timeRemaining,
    int? triesRemaining,
    List<SerializableTile>? grid,
  }) {
    return SerializableTreasureHuntGameState(
      nbRows: nbRows ?? this.nbRows,
      nbCols: nbCols ?? this.nbCols,
      rewardsCount: rewardsCount ?? this.rewardsCount,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      triesRemaining: triesRemaining ?? this.triesRemaining,
      grid: grid ?? this.grid,
    );
  }
}
