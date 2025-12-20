import 'package:common/fix_tracks/models/fix_tracks_grid.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';

class SerializableFixTracksGameState implements SerializableMiniGameState {
  SerializableFixTracksGameState({
    required this.grid,
    required this.isTimerRunning,
    required this.timeRemaining,
  });

  @override
  MiniGames get type => MiniGames.fixTracks;

  final FixTracksGrid grid;

  final bool isTimerRunning;
  final Duration timeRemaining;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.fixTracks.index,
      'grid': grid.serialize(),
      'is_timer_running': isTimerRunning,
      'time_remaining': timeRemaining.inSeconds,
    };
  }

  static SerializableFixTracksGameState deserialize(Map<String, dynamic> data) {
    return SerializableFixTracksGameState(
      grid: FixTracksGrid.deserialize(data['grid'] as Map<String, dynamic>),
      isTimerRunning: data['is_timer_running'] as bool,
      timeRemaining: Duration(seconds: data['time_remaining'] as int),
    );
  }

  @override
  SerializableFixTracksGameState copyWith({
    FixTracksGrid? grid,
    bool? isTimerRunning,
    Duration? timeRemaining,
    int? triesRemaining,
  }) {
    return SerializableFixTracksGameState(
      grid: grid ?? this.grid,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      timeRemaining: timeRemaining ?? this.timeRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableFixTracksGameState &&
        other.grid == grid &&
        other.isTimerRunning == isTimerRunning &&
        other.timeRemaining == timeRemaining;
  }

  @override
  int get hashCode =>
      grid.hashCode ^ isTimerRunning.hashCode ^ timeRemaining.hashCode;
}
