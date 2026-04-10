import 'package:common/warehouse_cleaning/models/avatar_agent.dart';
import 'package:common/warehouse_cleaning/models/box_agent.dart';
import 'package:common/warehouse_cleaning/models/letter_agent.dart';
import 'package:vector_math/vector_math.dart';

enum AgentType {
  avatar,
  box,
  letter;
}

extension Vector2Extension on Vector2 {
  List<double> serialize() => [x, y];

  static Vector2 deserialize(dynamic data) =>
      Vector2((data[0] as num).toDouble(), (data[1] as num).toDouble());
}

abstract class Agent {
  final int id;
  Vector2 position;
  Vector2 _velocity;
  final double maxVelocity;
  final Vector2 radius;
  double coefficientOfFriction;

  Agent({
    required this.id,
    required this.position,
    required Vector2 velocity,
    required this.maxVelocity,
    required this.radius,
    required this.coefficientOfFriction,
  }) : _velocity = velocity;

  AgentType get agentType;

  Map<String, dynamic> serialize();

  static Agent deserialize(Map<String, dynamic> map) =>
      switch (AgentType.values[map['agent_type']]) {
        AgentType.avatar => AvatarAgent.deserialize(map),
        AgentType.box => BoxAgent.deserialize(map),
        AgentType.letter => LetterAgent.deserialize(map)
      };

  Vector2 get velocity => _velocity;
  set velocity(Vector2 value) {
    if (value.length2 > maxVelocity * maxVelocity) {
      _velocity = value.normalized() * maxVelocity;
    } else {
      _velocity = value;
    }
  }

  void update({
    required Duration dt,
    required List<Agent> colliders,
    required Function(LetterAgent letter) onLetterCollision,
  }) {
    // Update position
    position += velocity * (dt.inMilliseconds / 1000.0);

    // Add some friction to the velocity
    velocity *= (1 - coefficientOfFriction * dt.inMilliseconds / 1000.0);

    // Check for collisions with other agents
    bool hasCollided = false;
    for (final other in colliders) {
      if (other.id == id) continue;
      if (isCollidingWith(other)) {
        if (other is BoxAgent) {
          // Prevent multiple collisions in the same update
          if (hasCollided) continue;
          _performCollisionWith(other);
          hasCollided = true;
        } else if (other is LetterAgent) {
          if (other.isCollected) continue;
          onLetterCollision(other);
        }
      }
    }
  }

  void _performCollisionWith(Agent other) {
    // Bounce the agent in an elastic way, with other being a static object (like a wall)
    final overlapX =
        (radius.x + other.radius.x) - ((position.x - other.position.x).abs());
    final overlapY =
        (radius.y + other.radius.y) - ((position.y - other.position.y).abs());

    if (overlapX < overlapY) {
      velocity.x = -velocity.x * 0.1;

      if (position.x < other.position.x) {
        position.x -= overlapX;
      } else {
        position.x += overlapX;
      }
    }

    if (overlapY < overlapX) {
      velocity.y = -velocity.y * 0.1;

      if (position.y < other.position.y) {
        position.y -= overlapY;
      } else {
        position.y += overlapY;
      }
    }
  }

  double get leftBorder => position.x - radius.x;
  double get rightBorder => position.x + radius.x;
  double get topBorder => position.y - radius.y;
  double get bottomBorder => position.y + radius.y;

  ///
  /// Check if this agent is colliding with another agent
  bool isCollidingWith(Agent other) {
    return (leftBorder > other.leftBorder && leftBorder < other.rightBorder ||
            rightBorder < other.rightBorder &&
                rightBorder > other.leftBorder) &&
        (topBorder > other.topBorder && topBorder < other.bottomBorder ||
            bottomBorder < other.bottomBorder &&
                bottomBorder > other.topBorder);
  }
}
