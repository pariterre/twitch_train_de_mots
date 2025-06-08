import 'package:train_de_mots/blueberry_war/to_remove/generic_listener.dart';
import 'package:vector_math/vector_math.dart';

enum AgentShape { circle, rectangle }

abstract class Agent {
  final int id;
  Vector2 position;
  Vector2 velocity;
  final Vector2 radius;
  final double mass;
  double coefficientOfFriction;
  AgentShape get shape;

  final onTeleport = GenericListener<Function(Vector2 from, Vector2 to)>();
  final onDestroyed = GenericListener<Function>();
  bool get isDestroyed;

  Agent({
    required this.id,
    required this.position,
    required this.velocity,
    required this.radius,
    required this.mass,
    required this.coefficientOfFriction,
  });

  void update({
    required Duration dt,
    required Vector2 horizontalBounds,
    required Vector2 verticalBounds,
  }) {
    if (isDestroyed) return;

    // Update position
    position += velocity * (dt.inMilliseconds / 1000.0);

    // Add some friction to the velocity
    velocity *= (1 - coefficientOfFriction * dt.inMilliseconds / 1000.0);

    // Check bounds and bounce if necessary
    if (isOutOfHorizontalBounds(horizontalBounds)) {
      position.x = leftBorder < horizontalBounds.x
          ? horizontalBounds.x + radius.x
          : horizontalBounds.y - radius.x;
      velocity.x = -velocity.x;
    }
    if (isOutOfVerticlaBounds(verticalBounds)) {
      position.y = topBorder < verticalBounds.x
          ? verticalBounds.x + radius.y
          : verticalBounds.y - radius.y;
      velocity.y = -velocity.y;
    }
  }

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
    velocity -= impulse * other.mass;
    other.velocity += impulse * mass;
  }

  void teleport({required Vector2 to}) {
    position = to;
    velocity = Vector2.zero();
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
  /// Check if this agent is out of the bounds
  bool isOutOfBounds(Vector2 horizontalBounds, Vector2 verticalBounds) =>
      isOutOfHorizontalBounds(horizontalBounds) ||
      isOutOfVerticlaBounds(verticalBounds);

  ///
  /// Check if this agent is out of the bounds on the X axis
  bool isOutOfHorizontalBounds(Vector2 bounds) =>
      leftBorder < bounds.x || rightBorder > bounds.y;

  ///
  /// Check if this agent is out of the bounds on the Y axis
  bool isOutOfVerticlaBounds(Vector2 bounds) =>
      topBorder < bounds.x || bottomBorder > bounds.y;
}
