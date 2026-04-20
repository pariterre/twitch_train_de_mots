import 'package:common/fix_tracks/models/fix_tracks_grid.dart';
import 'package:common/generic/managers/serializable_game_round_manager.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';

class SerializableFixTracksGameState implements SerializableMiniGameState {
  SerializableFixTracksGameState({
    required this.round,
    required this.grid,
  });

  @override
  MiniGames get type => MiniGames.fixTracks;

  final SerializableGameRoundManager round;
  final FixTracksGrid grid;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.fixTracks.index,
      'round': round.serialize(),
      'grid': grid.serialize(),
    };
  }

  static SerializableFixTracksGameState deserialize(Map<String, dynamic> data) {
    return SerializableFixTracksGameState(
      round: SerializableGameRoundManager.deserialize(
          data['round'] as Map<String, dynamic>),
      grid: FixTracksGrid.deserialize(data['grid'] as Map<String, dynamic>),
    );
  }

  @override
  SerializableFixTracksGameState copyWith({
    SerializableGameRoundManager? round,
    FixTracksGrid? grid,
  }) {
    return SerializableFixTracksGameState(
      round: round ?? this.round,
      grid: grid ?? this.grid,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableFixTracksGameState &&
        other.grid == grid &&
        other.round == round;
  }

  @override
  int get hashCode => grid.hashCode ^ round.hashCode;
}
