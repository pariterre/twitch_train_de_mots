import 'package:common/warehouse_cleaning/models/agent.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_game_manager_helpers.dart';

class AvatarAgent extends Agent {
  int tileIndex;

  AvatarAgent({
    required super.id,
    required this.tileIndex,
    required super.position,
    required super.velocity,
    required super.radius,
    required super.maxVelocity,
    required super.coefficientOfFriction,
  });

  @override
  AgentType get agentType => AgentType.avatar;

  @override
  Map<String, dynamic> serialize() => {
        'id': id,
        'agent_type': agentType.index,
        'tile_index': tileIndex,
        'position': position.serialize(),
        'velocity': velocity.serialize(),
        'max_velocity': maxVelocity,
        'radius': radius.serialize(),
        'coefficient_of_friction': coefficientOfFriction,
      };

  static AvatarAgent deserialize(Map<String, dynamic> map) {
    return AvatarAgent(
      id: map['id'] as int,
      tileIndex: map['tile_index'] as int,
      position: Vector2Extension.deserialize(map['position']),
      velocity: Vector2Extension.deserialize(map['velocity']),
      maxVelocity: (map['max_velocity'] as num).toDouble(),
      radius: Vector2Extension.deserialize(map['radius']),
      coefficientOfFriction: (map['coefficient_of_friction'] as num).toDouble(),
    );
  }

  bool get canBeSlingShot {
    // An avatar can be slingshot if it is not destroyed and has a velocity
    return velocity.length2 < WarehouseCleaningConfig.velocityThreshold2;
  }
}
