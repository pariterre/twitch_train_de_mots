import 'package:vector_math/vector_math.dart';

class WarehouseCleaningConfig {
  // Size of the grid
  static const int rowCount = 31;
  static const int columnCount = 15;

  // Starting position of the avatar
  static const startingRow = rowCount ~/ 2;
  static const startingCol = columnCount ~/ 2;

  ///
  /// Initial number of avatars in the game.
  static const int initialAvatarCount = 1;

  ///
  /// Size of a unit tile in the game. This is used to convert between the game world coordinates and the screen coordinates.
  static double get tileSize => 50.0;

  ///
  /// Radius of the avatar agent.
  /// This is used to calculate the collision detection and the teleportation.
  static Vector2 get avatarRadius => Vector2(tileSize / 5, tileSize / 5);

  ///
  /// Box radius
  static Vector2 get boxRadius => Vector2(tileSize / 2, tileSize / 2);

  ///
  /// The maximum velocity of the avatar agent.
  static double get avatarMaxVelocity => 750.0;

  ///
  /// Coefficient of friction for the avatar agent. This is used to calculate the deceleration of the avatar when it is moving.
  static double get avatarFrictionCoefficient => 2.0;

  ///
  /// Velocity threshold for teleportation which is used to determine if an agent
  /// is moving or not.
  static double get velocityThreshold => 200.0;
  static double get velocityThreshold2 => velocityThreshold * velocityThreshold;
}
