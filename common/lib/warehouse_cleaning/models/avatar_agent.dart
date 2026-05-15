import 'package:common/warehouse_cleaning/models/agent.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_game_manager_helpers.dart';
import 'package:vector_math/vector_math.dart';

class AvatarAgent extends Agent {
  int tileIndex;
  bool wasSlingShot;

  AvatarAgent({
    required super.id,
    required this.tileIndex,
    required super.position,
    required super.velocity,
    required super.radius,
    required super.maxVelocity,
    required super.coefficientOfFriction,
    required this.wasSlingShot,
  });

  AvatarAgent copyWith({
    int? id,
    int? tileIndex,
    Vector2? position,
    Vector2? velocity,
    Vector2? radius,
    double? maxVelocity,
    double? coefficientOfFriction,
    bool? wasSlingShot,
  }) {
    return AvatarAgent(
      id: id ?? this.id,
      tileIndex: tileIndex ?? this.tileIndex,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      radius: radius ?? this.radius,
      maxVelocity: maxVelocity ?? this.maxVelocity,
      coefficientOfFriction:
          coefficientOfFriction ?? this.coefficientOfFriction,
      wasSlingShot: wasSlingShot ?? this.wasSlingShot,
    );
  }

  @override
  AgentType get agentType => AgentType.avatar;

  @override
  Map<String, dynamic> serialize() => {
        'id': id,
        'agent_type': agentType.index,
        'tile_index': tileIndex,
        'position': networkPosition.serialize(),
        'velocity': networkVelocity.serialize(),
        'max_velocity': maxVelocity,
        'radius': radius.serialize(),
        'coefficient_of_friction': coefficientOfFriction,
        'was_sling_shot': wasSlingShot,
      };

  @override
  void flushDirtyItems() {
    wasSlingShot = false;
  }

  static AvatarAgent deserialize(Map<String, dynamic> map) {
    return AvatarAgent(
      id: map['id'] as int,
      tileIndex: map['tile_index'] as int,
      position: Vector2Extension.deserialize(map['position']),
      velocity: Vector2Extension.deserialize(map['velocity']),
      maxVelocity: (map['max_velocity'] as num).toDouble(),
      radius: Vector2Extension.deserialize(map['radius']),
      coefficientOfFriction: (map['coefficient_of_friction'] as num).toDouble(),
      wasSlingShot: map['was_sling_shot'] as bool,
    );
  }

  bool get canBeSlingShot {
    // An avatar can be slingshot if it is not destroyed and has a velocity
    return velocity.length2 < WarehouseCleaningConfig.velocityThreshold2;
  }
}
