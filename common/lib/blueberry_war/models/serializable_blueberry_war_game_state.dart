import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/generic/managers/serializable_game_round_manager.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';

class SerializableBlueberryWarGameState implements SerializableMiniGameState {
  SerializableBlueberryWarGameState({
    required this.round,
    required this.allAgents,
    required this.problem,
  });

  @override
  MiniGames get type => MiniGames.blueberryWar;

  final SerializableGameRoundManager round;
  final List<Agent> allAgents;
  List<BlueberryAgent> get blueberries =>
      allAgents.whereType<BlueberryAgent>().toList();
  List<LetterAgent> get letters => allAgents.whereType<LetterAgent>().toList();
  final SerializableLetterProblem problem;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.blueberryWar.index,
      'round': round.serialize(),
      'agents': allAgents.map((agent) => agent.serialize()).toList(),
      'problem': problem.serialize(),
    };
  }

  static SerializableBlueberryWarGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableBlueberryWarGameState(
      round: SerializableGameRoundManager.deserialize(
          data['round'] as Map<String, dynamic>),
      allAgents: (data['agents'] as List)
          .map((agentData) => Agent.deserialize(agentData))
          .toList(),
      problem: SerializableLetterProblem.deserialize(data['problem']),
    );
  }

  @override
  SerializableBlueberryWarGameState copyWith({
    SerializableGameRoundManager? round,
    bool? isWon,
    List<Agent>? allAgents,
    SerializableLetterProblem? problem,
  }) {
    return SerializableBlueberryWarGameState(
      round: round ?? this.round,
      allAgents: allAgents ?? this.allAgents,
      problem: problem ?? this.problem,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableBlueberryWarGameState &&
        other.round == round &&
        other.allAgents == allAgents &&
        other.problem == problem;
  }

  @override
  int get hashCode => round.hashCode ^ allAgents.hashCode ^ problem.hashCode;
}
