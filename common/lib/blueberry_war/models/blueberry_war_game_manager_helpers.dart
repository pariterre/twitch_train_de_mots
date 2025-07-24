import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/blueberry_war/models/player_agent.dart';
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
  /// Default field size for the game.
  /// This is the size of the field where the players can play.
  static final Vector2 fieldSize = Vector2(1920, 1080);

  ///
  /// Field ratio is the part of the field reserved for players
  static Vector2 get playerFieldSizeRatio => Vector2(1 / 5, 1);

  ///
  /// Calculate the player field size based on the total field size.
  /// This is the area where players can play.
  static Vector2 get playerFieldSize => Vector2(
      fieldSize.x * playerFieldSizeRatio.x,
      fieldSize.y * playerFieldSizeRatio.y);

  ///
  /// Velocity threshold for teleportation which is used to determine if a player
  /// is moving or not.
  static double get velocityThreshold => 20.0;
  static double get velocityThreshold2 => velocityThreshold * velocityThreshold;

  ///
  /// Update all the agents in the list. This method should be called by the
  /// game loop.
  static void updateAllAgents({
    required Duration dt,
    required List<Agent> allAgents,
    required SerializableLetterProblem problem,
    Function(PlayerAgent)? onBlueberryDestroyed,
    Function(LetterAgent)? onLetterHitByPlayer,
    Function(LetterAgent first, LetterAgent second)? onLetterHitByLetter,
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
            if (onLetterHitByLetter != null) onLetterHitByLetter(agent, other);
          } else if (agent is PlayerAgent && other is PlayerAgent) {
            // Two players colliding, do nothing
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
  static void checkForPlayersTeleportation({
    required List<Agent> allAgents,
    Function(PlayerAgent)? onPlayerTeleported,
  }) {
    for (final agent in allAgents) {
      final isPlayer = agent is PlayerAgent;
      if (!isPlayer) continue;

      // Teleport back to starting if the player is out of starting block and does not move anymore
      if (agent.position.x > fieldSize.x / 5 &&
          agent.velocity.length2 < (velocityThreshold * velocityThreshold)) {
        agent.teleport(
            to: PlayerAgent.generateRandomStartingPosition(
          playerFieldSize: BlueberryWarGameManagerHelpers.playerFieldSize,
          playerRadius: BlueberryWarGameManagerHelpers.playerRadius,
        ));
        if (onPlayerTeleported != null) onPlayerTeleported(agent);
      }
    }
  }

  static void _performHitOfPlayerOnLetter({
    required PlayerAgent player,
    required LetterAgent letter,
    required SerializableLetterProblem problem,
    required Function(PlayerAgent)? onBlueberryDestroyed,
    required Function(LetterAgent)? onLetterHitByPlayer,
  }) {
    if (letter.isBoss) {
      // Destroy the player
      player.destroy();
      if (onBlueberryDestroyed != null) onBlueberryDestroyed(player);
    } else {
      letter.hit();
      if (letter.isDestroyed) {
        problem.hiddenLetterStatuses[letter.problemIndex] = LetterStatus.normal;
        problem.uselessLetterStatuses[letter.problemIndex] =
            LetterStatus.normal;
      }
      if (onLetterHitByPlayer != null) onLetterHitByPlayer(letter);
    }
  }
}
