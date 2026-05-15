import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/network_item.dart';
import 'package:vector_math/vector_math.dart';

enum AgentShape { circle, rectangle }

enum AgentType { letter, blueberry }

extension Vector2Extension on Vector2 {
  List<double> serialize() => [x, y];

  static Vector2 deserialize(dynamic data) =>
      Vector2((data[0] as num).toDouble(), (data[1] as num).toDouble());
}

abstract class Agent with NetworkSynchronizable {
  final int id;
  final NetworkItem<double> _positionX;
  final NetworkItem<double> _positionY;
  final NetworkItem<double> _velocityX;
  final NetworkItem<double> _velocityY;
  final double maxVelocity;
  bool wasTeleported;
  final Vector2 radius;
  final double mass;
  double coefficientOfFriction;
  AgentShape get shape;

  final onTeleport = GenericListener<Function(Vector2 from, Vector2 to)>();
  final onDestroyed = GenericListener<Function>();
  bool get isDestroyed;

  Agent({
    required this.id,
    required Vector2 position,
    required Vector2 velocity,
    required this.maxVelocity,
    required this.wasTeleported,
    required this.radius,
    required this.mass,
    required this.coefficientOfFriction,
  })  : _positionX = NetworkItem(position.x),
        _positionY = NetworkItem(position.y),
        _velocityX = NetworkItem(velocity.x),
        _velocityY = NetworkItem(velocity.y);

  AgentType get agentType;

  static Agent deserialize(Map<String, dynamic> map) =>
      switch (AgentType.values[map['agent_type']]) {
        AgentType.letter => LetterAgent.deserialize(map),
        AgentType.blueberry => BlueberryAgent.deserialize(map),
      };

  @override
  void flushDirtyItems() {
    wasTeleported = false;
  }

  Vector2 get position => Vector2(_positionX.item, _positionY.item);
  Vector2 get networkPosition =>
      Vector2(_positionX.networkItem, _positionY.networkItem);
  set _localPosition(Vector2 value) {
    _positionX.localItem = value.x;
    _positionY.localItem = value.y;
  }

  set position(Vector2 value) {
    _positionX.item = value.x;
    _positionY.item = value.y;
  }

  Vector2 get velocity => Vector2(_velocityX.item, _velocityY.item);
  Vector2 get networkVelocity =>
      Vector2(_velocityX.networkItem, _velocityY.networkItem);
  set _localVelocity(Vector2 value) {
    if (value.length2 > maxVelocity * maxVelocity) {
      final normalized = value.normalized();
      _velocityX.localItem = normalized.x * maxVelocity;
      _velocityY.localItem = normalized.y * maxVelocity;
    } else {
      _velocityX.localItem = value.x;
      _velocityY.localItem = value.y;
    }
  }

  set velocity(Vector2 value) {
    if (value.length2 > maxVelocity * maxVelocity) {
      final normalized = value.normalized();
      _velocityX.item = normalized.x * maxVelocity;
      _velocityY.item = normalized.y * maxVelocity;
    } else {
      _velocityX.item = value.x;
      _velocityY.item = value.y;
    }
  }

  void update({required Duration dt}) {
    if (isDestroyed) return;

    // Update position
    _localPosition = position + velocity * (dt.inMilliseconds / 1000.0);

    // Add some friction to the velocity
    _localVelocity =
        velocity * (1 - coefficientOfFriction * dt.inMilliseconds / 1000.0);

    // Check bounds and bounce if necessary
    if (isOutOfHorizontalBounds(horizontalBounds)) {
      _positionX.localItem = leftBorder < horizontalBounds.x
          ? horizontalBounds.x + radius.x
          : horizontalBounds.y - radius.x;
      _velocityX.localItem = -velocity.x;
    }
    if (isOutOfVerticalBounds(verticalBounds)) {
      _positionY.localItem = topBorder < verticalBounds.x
          ? verticalBounds.x + radius.y
          : verticalBounds.y - radius.y;
      _velocityY.localItem = -velocity.y;
    }
  }

  Vector2 get horizontalBounds => Vector2(
      BlueberryWarConfig.blueberryFieldSize.x, BlueberryWarConfig.fieldSize.x);
  Vector2 get verticalBounds => Vector2(0, BlueberryWarConfig.fieldSize.y);

  void performCollisionWith(Agent other) {
    if (isDestroyed || other.isDestroyed) return;

    // Make sure they don't overlap
    final delta = position - other.position;
    final normal = delta.normalized();

    // Relative velocity
    final relativeVelocity = velocity - other.velocity;
    // Velocity along the normal
    final velAlongNormal = relativeVelocity.dot(normal);
    if (velAlongNormal > 0) return; // They're moving apart

    // Calculate impulse scalar
    final impulseMag = (2 * velAlongNormal) / (mass + other.mass);

    // Apply impulse
    final impulse = normal * impulseMag;
    _localVelocity = velocity - impulse * other.mass;
    other._localVelocity = other.velocity + impulse * mass;
  }

  void teleport({required Vector2 to}) {
    position = to;
    velocity = Vector2.zero();
    wasTeleported = true;
    onTeleport.notifyListeners((callback) => callback(position, to));
  }

  double get leftBorder => position.x - radius.x;
  double get rightBorder => position.x + radius.x;
  double get topBorder => position.y - radius.y;
  double get bottomBorder => position.y + radius.y;

  ///
  /// Check if this agent is colliding with another agent
  bool isCollidingWith(Agent other) {
    if (isDestroyed || other.isDestroyed) return false;

    if (shape == AgentShape.circle && other.shape == AgentShape.circle) {
      final distance = (position - other.position).length;
      return distance < (radius.x + other.radius.x);
    } else if (shape == AgentShape.rectangle &&
        other.shape == AgentShape.rectangle) {
      return (leftBorder > other.leftBorder && leftBorder < other.rightBorder ||
              rightBorder < other.rightBorder &&
                  rightBorder > other.leftBorder) &&
          (topBorder > other.topBorder && topBorder < other.bottomBorder ||
              bottomBorder < other.bottomBorder &&
                  bottomBorder > other.topBorder);
    } else if (shape == AgentShape.circle &&
        other.shape == AgentShape.rectangle) {
      // Circle vs Rectangle collision
      final closestX = position.x.clamp(other.leftBorder, other.rightBorder);
      final closestY = position.y.clamp(other.topBorder, other.bottomBorder);
      final distance = Vector2(closestX, closestY) - position;
      return distance.length < radius.x;
    } else if (shape == AgentShape.rectangle &&
        other.shape == AgentShape.circle) {
      return other.isCollidingWith(this); // Reverse the check
    } else {
      return false; // Unsupported shape combination
    }
  }

  ///
  /// Check if this agent is out of the bounds on the X axis
  bool isOutOfHorizontalBounds(Vector2 bounds) =>
      leftBorder < bounds.x || rightBorder > bounds.y;

  ///
  /// Check if this agent is out of the bounds on the Y axis
  bool isOutOfVerticalBounds(Vector2 bounds) =>
      topBorder < bounds.x || bottomBorder > bounds.y;
}
