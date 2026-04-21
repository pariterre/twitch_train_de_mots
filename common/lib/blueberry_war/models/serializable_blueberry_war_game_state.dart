import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';

class SerializableBlueberryWarGameState implements SerializableMiniGameState {
  SerializableBlueberryWarGameState({
    required this.roundTimer,
    required this.allAgents,
    required this.problem,
  });

  @override
  MiniGames get type => MiniGames.blueberryWar;

  final SerializableControllableTimer roundTimer;
  final List<Agent> allAgents;
  List<BlueberryAgent> get blueberries =>
      allAgents.whereType<BlueberryAgent>().toList();
  List<LetterAgent> get letters => allAgents.whereType<LetterAgent>().toList();
  final SerializableLetterProblem problem;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.blueberryWar.index,
      'round_timer': roundTimer.serialize(),
      'agents': allAgents.map((agent) => agent.serialize()).toList(),
      'problem': problem.serialize(),
    };
  }

  static SerializableBlueberryWarGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableBlueberryWarGameState(
      roundTimer: SerializableControllableTimer.deserialize(
          data['round_timer'] as Map<String, dynamic>),
      allAgents: (data['agents'] as List)
          .map((agentData) => Agent.deserialize(agentData))
          .toList(),
      problem: SerializableLetterProblem.deserialize(data['problem']),
    );
  }

  @override
  SerializableBlueberryWarGameState copyWith({
    SerializableControllableTimer? roundTimer,
    bool? isWon,
    List<Agent>? allAgents,
    SerializableLetterProblem? problem,
  }) {
    return SerializableBlueberryWarGameState(
      roundTimer: roundTimer ?? this.roundTimer,
      allAgents: allAgents ?? this.allAgents,
      problem: problem ?? this.problem,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableBlueberryWarGameState &&
        other.roundTimer == roundTimer &&
        other.allAgents == allAgents &&
        other.problem == problem;
  }

  @override
  int get hashCode =>
      roundTimer.hashCode ^ allAgents.hashCode ^ problem.hashCode;
}
