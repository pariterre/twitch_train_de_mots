import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/blueberry_war/models/player_agent.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:vector_math/vector_math.dart';

class SerializableBlueberryWarGameState implements SerializableMiniGameState {
  SerializableBlueberryWarGameState({
    required this.isStarted,
    required this.isOver,
    required this.isWon,
    required this.timeRemaining,
    required this.allAgents,
    required this.problem,
  });

  @override
  MiniGames get type => MiniGames.blueberryWar;

  final bool isStarted;
  final bool isOver;
  final bool isWon;
  final Duration timeRemaining;
  final List<Agent> allAgents;
  List<PlayerAgent> get players => allAgents.whereType<PlayerAgent>().toList();
  List<LetterAgent> get letters => allAgents.whereType<LetterAgent>().toList();
  final SerializableLetterProblem problem;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.blueberryWar.index,
      'is_started': isStarted,
      'is_over': isOver,
      'is_won': isWon,
      'time_remaining': timeRemaining.inSeconds,
      'agents': allAgents.map((agent) => agent.serialize()).toList(),
      'problem': problem.serialize(),
    };
  }

  static SerializableBlueberryWarGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableBlueberryWarGameState(
      isStarted: data['is_started'] as bool,
      isOver: data['is_over'] as bool,
      isWon: data['is_won'] as bool,
      timeRemaining: Duration(seconds: data['time_remaining'] as int),
      allAgents: (data['agents'] as List)
          .map((agentData) => Agent.deserialize(agentData))
          .toList(),
      problem: SerializableLetterProblem.deserialize(data['problem']),
    );
  }

  @override
  SerializableBlueberryWarGameState copyWith({
    bool? isStarted,
    Duration? timeRemaining,
    bool? isOver,
    bool? isWon,
    Vector2? playerFieldRatio,
    List<Agent>? allAgents,
    SerializableLetterProblem? problem,
  }) {
    return SerializableBlueberryWarGameState(
      isStarted: isStarted ?? this.isStarted,
      isOver: isOver ?? this.isOver,
      isWon: isWon ?? this.isWon,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      allAgents: allAgents ?? this.allAgents,
      problem: problem ?? this.problem,
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
