import 'dart:math';

import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:vector_math/vector_math.dart';

class BlueberryAgent extends Agent {
  @override
  AgentShape get shape => AgentShape.circle;

  bool _isInField;
  bool get isInField => _isInField;
  bool get isNotInField => !_isInField;
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
    required bool isInField,
    required super.radius,
    required super.maxVelocity,
    required super.mass,
    required super.coefficientOfFriction,
    bool isDestroyed = false,
  })  : _isInField = isInField,
        _isDestroyed = isDestroyed;

  @override
  AgentType get agentType => AgentType.blueberry;

  @override
  Map<String, dynamic> serialize() => {
        'id': id,
        'agent_type': agentType.index,
        'position': position.serialize(),
        'velocity': velocity.serialize(),
        'is_in_field': isInField,
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
      isInField: map['is_in_field'] as bool? ?? false,
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
        velocity.length2 < BlueberryWarConfig.velocityThreshold2 &&
        isNotInField;
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

  @override
  void update({required Duration dt}) {
    final out = super.update(dt: dt);

    // Flag the blueberry as in the field
    if (position.x > BlueberryWarConfig.blueberryFieldSize.x) _isInField = true;

    return out;
  }

  @override
  void teleport({required Vector2 to}) {
    super.teleport(to: to);
    _isInField = false;
  }

  @override
  Vector2 get horizontalBounds => isInField
      ? super.horizontalBounds
      : Vector2(0, BlueberryWarConfig.fieldSize.x);
}
