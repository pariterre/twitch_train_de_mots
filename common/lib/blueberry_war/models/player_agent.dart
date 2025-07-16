import 'dart:math';

import 'package:common/blueberry_war/models/agent.dart';
import 'package:vector_math/vector_math.dart';

class PlayerAgent extends Agent {
  @override
  AgentShape get shape => AgentShape.circle;

  bool _isDestroyed;
  @override
  bool get isDestroyed => _isDestroyed;
  void destroy() {
    _isDestroyed = true;
    onDestroyed.notifyListeners((callback) => callback());
  }

  final double velocityThreshold;

  PlayerAgent({
    required super.id,
    required super.position,
    required super.velocity,
    required super.radius,
    required this.velocityThreshold,
    required super.mass,
    required super.coefficientOfFriction,
    bool isDestroyed = false,
  }) : _isDestroyed = isDestroyed;

  @override
  AgentType get agentType => AgentType.player;

  @override
  Map<String, dynamic> serialize() => {
        'id': id,
        'agent_type': agentType.index,
        'position': position.serialize(),
        'velocity': velocity.serialize(),
        'velocity_threshold': velocityThreshold,
        'radius': radius.serialize(),
        'mass': mass,
        'coefficient_of_friction': coefficientOfFriction,
        'shape': shape.index,
        'is_destroyed': isDestroyed,
      };

  static PlayerAgent deserialize(Map<String, dynamic> map) {
    return PlayerAgent(
      id: map['id'] as int,
      position: Vector2Extension.deserialize(map['position']),
      velocity: Vector2Extension.deserialize(map['velocity']),
      velocityThreshold: (map['velocity_threshold'] as num).toDouble(),
      radius: Vector2Extension.deserialize(map['radius']),
      mass: (map['mass'] as num).toDouble(),
      coefficientOfFriction: (map['coefficient_of_friction'] as num).toDouble(),
      isDestroyed: map['is_destroyed'] as bool? ?? false,
    );
  }

  bool get canBeSlingShot {
    // A player can be slingshot if it is not destroyed and has a velocity
    return !isDestroyed &&
        velocity.length2 > (velocityThreshold * velocityThreshold);
  }

  static Vector2 generateRandomStartingPosition({
    required Vector2 playerFieldSize,
    required Vector2 playerRadius,
  }) {
    final random = Random();
    return Vector2(
      playerFieldSize.x / 2 +
          (random.nextDouble() * playerFieldSize.x / 2) -
          playerRadius.x,
      playerFieldSize.y / 8 +
          (random.nextDouble() * playerFieldSize.y * 6 / 8.0),
    );
  }
}
