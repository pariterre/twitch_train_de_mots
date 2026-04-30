import 'package:common/generic/managers/serializable_controllable_timer.dart';

class SerializablePlayer {
  final String name;
  final int score;
  final int starsCollected;
  final int roundStealCount;
  final int gameStealCount;
  final SerializableControllableTimer cooldownTimer;

  SerializablePlayer({
    required this.name,
    required this.score,
    required this.starsCollected,
    required this.roundStealCount,
    required this.gameStealCount,
    required this.cooldownTimer,
  });

  Map<String, dynamic> serialize() {
    return {
      'name': name,
      'score': score,
      'stars_collected': starsCollected,
      'round_steal_count': roundStealCount,
      'game_steal_count': gameStealCount,
      'cooldown_timer': cooldownTimer.serialize(),
    };
  }

  static SerializablePlayer deserialize(Map<String, dynamic> data) {
    return SerializablePlayer(
      name: data['name'],
      score: data['score'],
      starsCollected: data['stars_collected'],
      roundStealCount: data['round_steal_count'],
      gameStealCount: data['game_steal_count'],
      cooldownTimer:
          SerializableControllableTimer.deserialize(data['cooldown_timer']),
    );
  }
}
