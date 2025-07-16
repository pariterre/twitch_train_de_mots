import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/blueberry_war/models/player_agent.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:logging/logging.dart';
import 'package:vector_math/vector_math.dart';

final _logger = Logger('Agent');

class BlueberryWarGameManagerHelpers {
  ///
  /// Radius of the player agent.
  /// This is used to calculate the collision detection and the teleportation.
  static Vector2 get playerRadius => Vector2(30.0, 30.0);

  ///
  /// Field ratio is the part of the field reserved for players
  static Vector2 get playerFieldSizeRatio => Vector2(1 / 5, 1);

  ///
  /// Calculate the player field size based on the total field size.
  /// This is the area where players can play.
  static Vector2 playerFieldSize(Vector2 fieldSize) => Vector2(
        fieldSize.x * playerFieldSizeRatio.x,
        fieldSize.y * playerFieldSizeRatio.y,
      );

  ///
  /// Velocity threshold for teleportation which is used to determine if a player
  /// is moving or not.
  static double get velocityThreshold => 20.0;
  static double get velocityThresholdSquared =>
      velocityThreshold * velocityThreshold;

  ///
  /// Update all the agents in the list. This method should be called by the
  /// game loop.
  static void updateAllAgents({
    required Duration dt,
    required List<Agent> allAgents,
    required Vector2 fieldSize,
    required SerializableLetterProblem problem,
    GenericListener<Function(int id)>? onBlueberryDestroyed,
    GenericListener<Function(int problemIndex, bool isDestroyed)>?
        onLetterHitByPlayer,
    GenericListener<
            Function(int firstIndex, int secondIndex, bool firstIsBoss,
                bool secondIsBoss)>?
        onLetterHitByLetter,
  }) {
    for (int i = 0; i < allAgents.length; i++) {
      // Move all agents
      final agent = allAgents[i];

      final isPlayer = agent is PlayerAgent;
      agent.update(
        dt: dt,
        horizontalBounds: isPlayer
            ? Vector2(0, fieldSize.x)
            : Vector2(fieldSize.x / 5, fieldSize.x),
        verticalBounds:
            isPlayer ? Vector2(0, fieldSize.y) : Vector2(0, fieldSize.y),
      );

      // Check for collisions with other agents.
      // Do not redo collisions with agents that have already been checked.
      for (final other in allAgents.sublist(i + 1)) {
        if (agent.isCollidingWith(other)) {
          agent.performCollisionWith(other);
          if (agent is LetterAgent && other is PlayerAgent) {
            _performHitOfPlayerOnLetter(
                player: other,
                letter: agent,
                problem: problem,
                onBlueberryDestroyed: onBlueberryDestroyed,
                onLetterHitByPlayer: onLetterHitByPlayer);
          } else if (agent is PlayerAgent && other is LetterAgent) {
            _performHitOfPlayerOnLetter(
                player: agent,
                letter: other,
                problem: problem,
                onBlueberryDestroyed: onBlueberryDestroyed,
                onLetterHitByPlayer: onLetterHitByPlayer);
          } else if (agent is LetterAgent && other is LetterAgent) {
            onLetterHitByLetter?.notifyListeners(
              (callback) => callback(
                agent.problemIndex,
                other.problemIndex,
                agent.isBoss,
                other.isBoss,
              ),
            );
          } else if (agent is PlayerAgent && other is PlayerAgent) {
            // Two players colliding, do nothing
          } else {
            _logger.warning(
              'Collision between ${agent.runtimeType} and ${other.runtimeType} not handled',
            );
          }
        }
      }

      // Check for teleportation
      if (isPlayer) {
        // Teleport back to starting if the player is out of starting block and does not move anymore
        if (agent.position.x > fieldSize.x / 5 &&
            agent.velocity.length2 < (velocityThreshold * velocityThreshold)) {
          agent.teleport(
              to: PlayerAgent.generateRandomStartingPosition(
            playerFieldSize:
                BlueberryWarGameManagerHelpers.playerFieldSize(fieldSize),
            playerRadius: BlueberryWarGameManagerHelpers.playerRadius,
          ));
        }
      }
    }
  }

  static void _performHitOfPlayerOnLetter({
    required PlayerAgent player,
    required LetterAgent letter,
    required SerializableLetterProblem problem,
    required GenericListener<Function(int id)>? onBlueberryDestroyed,
    required GenericListener<Function(int problemIndex, bool isDestroyed)>?
        onLetterHitByPlayer,
  }) {
    if (letter.isBoss) {
      // Destroy the player
      player.destroy();
      onBlueberryDestroyed?.notifyListeners((callback) => callback(player.id));
    } else {
      letter.hit();
      if (letter.isDestroyed) {
        problem.hiddenLetterStatuses[letter.problemIndex] = LetterStatus.normal;
        problem.uselessLetterStatuses[letter.problemIndex] =
            LetterStatus.normal;
      }
      onLetterHitByPlayer?.notifyListeners(
        (callback) => callback(letter.problemIndex, letter.isDestroyed),
      );
    }
  }
}
