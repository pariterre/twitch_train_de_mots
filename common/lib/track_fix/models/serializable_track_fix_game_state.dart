import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/track_fix/models/track_fix_grid.dart';

class SerializableTrackFixGameState implements SerializableMiniGameState {
  SerializableTrackFixGameState({
    required this.grid,
    required this.isTimerRunning,
    required this.timeRemaining,
  });

  @override
  MiniGames get type => MiniGames.trackFix;

  final Grid grid;

  final bool isTimerRunning;
  final Duration timeRemaining;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.trackFix.index,
      'grid': grid.serialize(),
      'is_timer_running': isTimerRunning,
      'time_remaining': timeRemaining.inSeconds,
    };
  }

  static SerializableTrackFixGameState deserialize(Map<String, dynamic> data) {
    return SerializableTrackFixGameState(
      grid: Grid.deserialize(data['grid'] as Map<String, dynamic>),
      isTimerRunning: data['is_timer_running'] as bool,
      timeRemaining: Duration(seconds: data['time_remaining'] as int),
    );
  }

  @override
  SerializableTrackFixGameState copyWith({
    Grid? grid,
    bool? isTimerRunning,
    Duration? timeRemaining,
    int? triesRemaining,
  }) {
    return SerializableTrackFixGameState(
      grid: grid ?? this.grid,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      timeRemaining: timeRemaining ?? this.timeRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableTrackFixGameState &&
        other.grid == grid &&
        other.isTimerRunning == isTimerRunning &&
        other.timeRemaining == timeRemaining;
  }

  @override
  int get hashCode =>
      grid.hashCode ^ isTimerRunning.hashCode ^ timeRemaining.hashCode;
}
