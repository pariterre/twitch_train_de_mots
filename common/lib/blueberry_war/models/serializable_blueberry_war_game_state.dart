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

  @override
  final SerializableControllableTimer roundTimer;
  final Map<String, Agent> allAgents;
  List<BlueberryAgent> get blueberries =>
      allAgents.values.whereType<BlueberryAgent>().toList();
  List<LetterAgent> get letters =>
      allAgents.values.whereType<LetterAgent>().toList();
  final SerializableLetterProblem problem;
  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.blueberryWar.index,
      'round_timer': roundTimer.serialize(),
      'agents': allAgents.map((key, agent) => MapEntry(key, agent.serialize())),
      'problem': problem.serialize(obscureHiddenLetter: true),
    };
  }

  static SerializableBlueberryWarGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableBlueberryWarGameState(
      roundTimer: SerializableControllableTimer.deserialize(
          data['round_timer'] as Map<String, dynamic>),
      allAgents: (data['agents'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, Agent.deserialize(value))),
      problem: SerializableLetterProblem.deserialize(data['problem']),
    );
  }

  @override
  SerializableBlueberryWarGameState copyWith({
    SerializableControllableTimer? roundTimer,
    bool? isWon,
    Map<String, Agent>? allAgents,
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
