import 'package:common/warehouse_cleaning/models/agent.dart';
import 'package:vector_math/vector_math.dart';

class BoxAgent extends Agent {
  BoxAgent({
    required super.id,
    required super.position,
    required super.radius,
  }) : super(
            velocity: Vector2.zero(),
            maxVelocity: 0.0,
            coefficientOfFriction: 0.0);

  @override
  AgentType get agentType => AgentType.box;

  @override
  Vector2 get velocity => Vector2.zero();

  @override
  Map<String, dynamic> serialize() => {
        'id': id,
        'agent_type': agentType.index,
        'position': position.serialize(),
        'radius': radius.serialize(),
      };

  static BoxAgent deserialize(Map<String, dynamic> map) {
    return BoxAgent(
      id: map['id'] as int,
      position: Vector2Extension.deserialize(map['position']),
      radius: Vector2Extension.deserialize(map['radius']),
    );
  }
}
