import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:vector_math/vector_math.dart';

class SerializableBlueberryWarGameState implements SerializableMiniGameState {
  SerializableBlueberryWarGameState({
    required this.isStarted,
    required this.isOver,
    required this.isWon,
    required this.timeRemaining,
    required this.fieldSize,
    required this.playerFieldRatio,
    required this.allAgents,
  });

  @override
  MiniGames get type => MiniGames.blueberryWar;

  final bool isStarted;
  final bool isOver;
  final bool isWon;
  final Duration timeRemaining;
  final Vector2 fieldSize;
  final Vector2 playerFieldRatio;
  final List<Agent> allAgents;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.blueberryWar.index,
      'is_started': isStarted,
      'is_over': isOver,
      'is_won': isWon,
      'time_remaining': timeRemaining.inSeconds,
      'field_size': fieldSize,
      'player_field_ratio': playerFieldRatio,
      'agents': allAgents.map((agent) => agent.serialize()).toList(),
    };
  }

  static SerializableBlueberryWarGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableBlueberryWarGameState(
      isStarted: data['is_started'] as bool,
      isOver: data['is_over'] as bool,
      isWon: data['is_won'] as bool,
      timeRemaining: Duration(seconds: data['time_remaining'] as int),
      fieldSize: Vector2Extension.deserialize(data['field_size']),
      playerFieldRatio:
          Vector2Extension.deserialize(data['player_field_ratio']),
      allAgents: (data['agents'] as List)
          .map((agentData) => Agent.deserialize(agentData))
          .toList(),
    );
  }

  @override
  SerializableBlueberryWarGameState copyWith({
    bool? isStarted,
    Duration? timeRemaining,
    bool? isOver,
    bool? isWon,
    Vector2? fieldSize,
    Vector2? playerFieldRatio,
    List<Agent>? allAgents,
  }) {
    return SerializableBlueberryWarGameState(
      isStarted: isStarted ?? this.isStarted,
      isOver: isOver ?? this.isOver,
      isWon: isWon ?? this.isWon,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      fieldSize: fieldSize ?? this.fieldSize,
      playerFieldRatio: playerFieldRatio ?? this.playerFieldRatio,
      allAgents: allAgents ?? this.allAgents,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableBlueberryWarGameState &&
        other.isStarted == isStarted &&
        other.timeRemaining == timeRemaining;
  }

  @override
  int get hashCode => isStarted.hashCode ^ timeRemaining.hashCode;
}
