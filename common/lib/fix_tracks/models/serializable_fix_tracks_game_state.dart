import 'package:common/fix_tracks/models/fix_tracks_grid.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';

class SerializableFixTracksGameState implements SerializableMiniGameState {
  SerializableFixTracksGameState({
    required this.roundTimer,
    required this.grid,
  });

  @override
  MiniGames get type => MiniGames.fixTracks;

  final SerializableControllableTimer roundTimer;
  final FixTracksGrid grid;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.fixTracks.index,
      'round_timer': roundTimer.serialize(),
      'grid': grid.serialize(),
    };
  }

  static SerializableFixTracksGameState deserialize(Map<String, dynamic> data) {
    return SerializableFixTracksGameState(
      roundTimer: SerializableControllableTimer.deserialize(
          data['round_timer'] as Map<String, dynamic>),
      grid: FixTracksGrid.deserialize(data['grid'] as Map<String, dynamic>),
    );
  }

  @override
  SerializableFixTracksGameState copyWith({
    SerializableControllableTimer? roundTimer,
    FixTracksGrid? grid,
  }) {
    return SerializableFixTracksGameState(
      roundTimer: roundTimer ?? this.roundTimer,
      grid: grid ?? this.grid,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableFixTracksGameState &&
        other.grid == grid &&
        other.roundTimer == roundTimer;
  }

  @override
  int get hashCode => grid.hashCode ^ roundTimer.hashCode;
}
