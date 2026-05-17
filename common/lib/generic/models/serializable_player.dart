import 'package:common/generic/managers/serializable_controllable_timer.dart';

class SerializablePlayer {
  final String login;
  final String displayName;
  final int score;
  final int starsCollected;
  final int roundStealCount;
  final int gameStealCount;
  final SerializableControllableTimer cooldownTimer;

  SerializablePlayer({
    required this.login,
    required this.displayName,
    required this.score,
    required this.starsCollected,
    required this.roundStealCount,
    required this.gameStealCount,
    required this.cooldownTimer,
  });

  Map<String, dynamic> serialize() {
    return {
      'login': login,
      'display_name': displayName,
      'score': score,
      'stars_collected': starsCollected,
      'round_steal_count': roundStealCount,
      'game_steal_count': gameStealCount,
      'cooldown_timer': cooldownTimer.serialize(),
    };
  }

  static SerializablePlayer deserialize(Map<String, dynamic> data) {
    return SerializablePlayer(
      login: data['login'],
      displayName: data['display_name'],
      score: data['score'],
      starsCollected: data['stars_collected'],
      roundStealCount: data['round_steal_count'],
      gameStealCount: data['game_steal_count'],
      cooldownTimer:
          SerializableControllableTimer.deserialize(data['cooldown_timer']),
    );
  }

  @override
  int get hashCode {
    return Object.hash(login, displayName, score, starsCollected,
        roundStealCount, gameStealCount, cooldownTimer);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializablePlayer &&
        other.login == login &&
        other.displayName == displayName &&
        other.score == score &&
        other.starsCollected == starsCollected &&
        other.roundStealCount == roundStealCount &&
        other.gameStealCount == gameStealCount &&
        other.cooldownTimer == cooldownTimer;
  }
}
