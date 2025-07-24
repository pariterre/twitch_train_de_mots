import 'dart:math';

import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:vector_math/vector_math.dart';

class BlueberryAgent extends Agent {
  @override
  AgentShape get shape => AgentShape.circle;

  bool _isDestroyed;
  @override
  bool get isDestroyed => _isDestroyed;
  void destroy() {
    _isDestroyed = true;
    onDestroyed.notifyListeners((callback) => callback());
  }

  BlueberryAgent({
    required super.id,
    required super.position,
    required super.velocity,
    required super.radius,
    required super.maxVelocity,
    required super.mass,
    required super.coefficientOfFriction,
    bool isDestroyed = false,
  }) : _isDestroyed = isDestroyed;

  @override
  AgentType get agentType => AgentType.blueberry;

  @override
  Map<String, dynamic> serialize() => {
        'id': id,
        'agent_type': agentType.index,
        'position': position.serialize(),
        'velocity': velocity.serialize(),
        'max_velocity': maxVelocity,
        'radius': radius.serialize(),
        'mass': mass,
        'coefficient_of_friction': coefficientOfFriction,
        'shape': shape.index,
        'is_destroyed': isDestroyed,
      };

  static BlueberryAgent deserialize(Map<String, dynamic> map) {
    return BlueberryAgent(
      id: map['id'] as int,
      position: Vector2Extension.deserialize(map['position']),
      velocity: Vector2Extension.deserialize(map['velocity']),
      maxVelocity: (map['max_velocity'] as num).toDouble(),
      radius: Vector2Extension.deserialize(map['radius']),
      mass: (map['mass'] as num).toDouble(),
      coefficientOfFriction: (map['coefficient_of_friction'] as num).toDouble(),
      isDestroyed: map['is_destroyed'] as bool? ?? false,
    );
  }

  bool get canBeSlingShot {
    // A blueberry can be slingshot if it is not destroyed and has a velocity
    return !isDestroyed &&
        velocity.length2 < BlueberryWarConfig.velocityThreshold2;
  }

  static Vector2 generateRandomStartingPosition({
    required Vector2 blueberryFieldSize,
    required Vector2 blueberryRadius,
  }) {
    final random = Random();
    return Vector2(
      blueberryFieldSize.x / 2 +
          (random.nextDouble() * blueberryFieldSize.x / 2) -
          5 * blueberryRadius.x,
      blueberryFieldSize.y / 8 +
          (random.nextDouble() * blueberryFieldSize.y * 6 / 8.0),
    );
  }
}
