import 'package:common/warehouse_cleaning/models/agent.dart';
import 'package:vector_math/vector_math.dart';

class LetterAgent extends Agent {
  final String value;
  bool isCollected = false;

  @override
  Vector2 get velocity => Vector2.zero();

  LetterAgent({
    required super.id,
    required this.value,
    required super.position,
    required super.radius,
  }) : super(
          velocity: Vector2.zero(),
          maxVelocity: 0.0,
          coefficientOfFriction: 0.0,
        );

  @override
  AgentType get agentType => AgentType.letter;

  @override
  Map<String, dynamic> serialize() => {
        'id': id,
        'value': value,
        'agent_type': agentType.index,
        'position': position.serialize(),
        'radius': radius.serialize(),
      };

  static LetterAgent deserialize(Map<String, dynamic> map) {
    return LetterAgent(
      id: map['id'] as int,
      value: map['value'] as String,
      position: Vector2Extension.deserialize(map['position']),
      radius: Vector2Extension.deserialize(map['radius']),
    );
  }
}
