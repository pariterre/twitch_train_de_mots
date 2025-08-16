import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:logging/logging.dart';
import 'package:vector_math/vector_math.dart';

final _logger = Logger('BlueberryWarGameManagerHelpers');

class BlueberryWarConfig {
  ///
  /// Default field size for the game.
  /// This is the total size of the game field.
  static final Vector2 fieldSize = Vector2(1920, 1080);

  ///
  /// Field ratio is the part of the field reserved for blueberries
  static Vector2 get _blueberryFieldSizeRatio => Vector2(1 / 5, 1);

  ///
  /// This is the area where blueberries starts.
  static Vector2 get blueberryFieldSize => Vector2(
      fieldSize.x * _blueberryFieldSizeRatio.x,
      fieldSize.y * _blueberryFieldSizeRatio.y);

  ///
  /// Initial number of blueberries in the game.
  static const int initialBlueberryCount = 8;

  ///
  /// Radius of the blueberry agent.
  /// This is used to calculate the collision detection and the teleportation.
  static Vector2 get blueberryRadius => Vector2(30.0, 30.0);

  ///
  /// The maximum velocity of the blueberry agent.
  static double get blueberryMaxVelocity => 3000.0;

  ///
  /// The maximum velocity of the letter agent.
  static double get letterMaxVelocity => 6000.0;

  ///
  /// Velocity threshold for teleportation which is used to determine if an agent
  /// is moving or not.
  static double get velocityThreshold => 20.0;
  static double get velocityThreshold2 => velocityThreshold * velocityThreshold;
}

class BlueberryWarGameManagerHelpers {
  ///
  /// Update all the agents in the list. This method should be called by the
  /// game loop.
  static void updateAllAgents({
    required Duration dt,
    required List<Agent> allAgents,
    required SerializableLetterProblem problem,
    Function(BlueberryAgent)? onBlueberryDestroyed,
    Function(LetterAgent)? onLetterHitByBlueberry,
    Function(LetterAgent first, LetterAgent second)? onLetterHitByLetter,
  }) {
    for (int i = 0; i < allAgents.length; i++) {
      // Move all agents
      final agent = allAgents[i];
      agent.update(dt: dt);

      // Check for collisions with other agents.
      // Do not redo collisions with agents that have already been checked.
      for (final other in allAgents.sublist(i + 1)) {
        // Do not collide Blueberry with Blueberry
        if (agent is BlueberryAgent && other is BlueberryAgent) continue;

        if (agent.isCollidingWith(other)) {
          agent.performCollisionWith(other);
          if (agent is LetterAgent && other is BlueberryAgent) {
            _performHitOfBlueberryOnLetter(
                blueberry: other,
                letter: agent,
                problem: problem,
                onBlueberryDestroyed: onBlueberryDestroyed,
                onLetterHitByBlueberry: onLetterHitByBlueberry);
          } else if (agent is BlueberryAgent && other is LetterAgent) {
            _performHitOfBlueberryOnLetter(
                blueberry: agent,
                letter: other,
                problem: problem,
                onBlueberryDestroyed: onBlueberryDestroyed,
                onLetterHitByBlueberry: onLetterHitByBlueberry);
          } else if (agent is LetterAgent && other is LetterAgent) {
            if (onLetterHitByLetter != null) onLetterHitByLetter(agent, other);
          } else if (agent is BlueberryAgent && other is BlueberryAgent) {
            // Two blueberries colliding, do nothing
          } else {
            _logger.warning(
              'Collision between ${agent.runtimeType} and ${other.runtimeType} not handled',
            );
          }
        }
      }
    }
  }

  ///
  /// Check for teleportations
  static void checkForBlueberriesTeleportation({
    required List<Agent> allAgents,
    Function(BlueberryAgent)? onBlueberryTeleported,
  }) {
    for (final agent in allAgents) {
      final isBlueberry = agent is BlueberryAgent;
      if (!isBlueberry) continue;

      // Teleport back to starting if the blueberry is out of starting block and does not move anymore
      if (agent.position.x > BlueberryWarConfig.blueberryFieldSize.x &&
          agent.velocity.length2 < BlueberryWarConfig.velocityThreshold2) {
        agent.teleport(
            to: BlueberryAgent.generateRandomStartingPosition(
          blueberryFieldSize: BlueberryWarConfig.blueberryFieldSize,
          blueberryRadius: BlueberryWarConfig.blueberryRadius,
        ));
        if (onBlueberryTeleported != null) onBlueberryTeleported(agent);
      }
    }
  }

  static void _performHitOfBlueberryOnLetter({
    required BlueberryAgent blueberry,
    required LetterAgent letter,
    required SerializableLetterProblem problem,
    required Function(BlueberryAgent)? onBlueberryDestroyed,
    required Function(LetterAgent)? onLetterHitByBlueberry,
  }) {
    if (letter.isBoss) {
      // Destroy the blueberry
      blueberry.destroy();
      if (onBlueberryDestroyed != null) onBlueberryDestroyed(blueberry);
    } else {
      letter.hit();
      if (letter.isDestroyed) {
        problem.hiddenLetterStatuses[letter.problemIndex] = LetterStatus.normal;
        problem.uselessLetterStatuses[letter.problemIndex] =
            LetterStatus.normal;
      }
      if (onLetterHitByBlueberry != null) onLetterHitByBlueberry(letter);
    }
  }
}
