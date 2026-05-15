import 'package:common/generic/models/network_item.dart';
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

abstract class Agent with NetworkSynchronizable {
  final int id;
  final NetworkItem<double> _positionX;
  final NetworkItem<double> _positionY;
  final NetworkItem<double> _velocityX;
  final NetworkItem<double> _velocityY;
  final double maxVelocity;
  final Vector2 radius;
  final double coefficientOfFriction;

  Agent({
    required this.id,
    required Vector2 position,
    required Vector2 velocity,
    required this.maxVelocity,
    required this.radius,
    required this.coefficientOfFriction,
  })  : _positionX = NetworkItem(position.x),
        _positionY = NetworkItem(position.y),
        _velocityX = NetworkItem(velocity.x),
        _velocityY = NetworkItem(velocity.y);

  AgentType get agentType;

  static Agent deserialize(Map<String, dynamic> map) =>
      switch (AgentType.values[map['agent_type']]) {
        AgentType.avatar => AvatarAgent.deserialize(map),
        AgentType.box => BoxAgent.deserialize(map),
        AgentType.letter => LetterAgent.deserialize(map)
      };

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
    position = position;
    if (value.length2 > maxVelocity * maxVelocity) {
      final normalized = value.normalized();
      _velocityX.item = normalized.x * maxVelocity;
      _velocityY.item = normalized.y * maxVelocity;
    } else {
      _velocityX.item = value.x;
      _velocityY.item = value.y;
    }
  }

  void update({
    required Duration dt,
    required List<Agent> colliders,
    required Function(LetterAgent letter) onLetterCollision,
  }) {
    // Update position
    _localPosition = position + velocity * (dt.inMilliseconds / 1000.0);

    // Add some friction to the velocity
    _localVelocity =
        velocity * (1 - coefficientOfFriction * dt.inMilliseconds / 1000.0);

    // Check for collisions with other agents
    bool hasCollided = false;
    for (final other in colliders) {
      if (other.id == id) continue;

      if (isInside(other)) {
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

    if (overlapX <= overlapY) {
      _velocityX.localItem = -velocity.x * 0.1;

      if (position.x < other.position.x) {
        _positionX.localItem = position.x - overlapX;
      } else {
        _positionX.localItem = position.x + overlapX;
      }
    }

    if (overlapY <= overlapX) {
      _velocityY.localItem = -velocity.y * 0.1;

      if (position.y < other.position.y) {
        _positionY.localItem = position.y - overlapY;
      } else {
        _positionY.localItem = position.y + overlapY;
      }
    }
  }

  double get leftBorder => position.x - radius.x;
  double get rightBorder => position.x + radius.x;
  double get topBorder => position.y - radius.y;
  double get bottomBorder => position.y + radius.y;

  ///
  /// Check if this agent is inside another agent
  bool isInside(Agent other) {
    return rightBorder > other.leftBorder &&
        leftBorder < other.rightBorder &&
        topBorder < other.bottomBorder &&
        bottomBorder > other.topBorder;
  }
}
