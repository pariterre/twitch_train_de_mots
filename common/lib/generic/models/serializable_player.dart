class SerializablePlayer {
  final String name;
  final int score;
  final int starsCollected;
  final int roundStealCount;
  final int gameStealCount;
  final DateTime cooldownStartedAt;
  final DateTime cooldownEndAt;

  SerializablePlayer({
    required this.name,
    required this.score,
    required this.starsCollected,
    required this.roundStealCount,
    required this.gameStealCount,
    required this.cooldownStartedAt,
    required this.cooldownEndAt,
  });

  Map<String, dynamic> serialize() {
    return {
      'name': name,
      'score': score,
      'stars_collected': starsCollected,
      'round_steal_count': roundStealCount,
      'game_steal_count': gameStealCount,
      'cooldown_started_at': cooldownStartedAt.microsecondsSinceEpoch,
      'cooldown_end_at': cooldownEndAt.microsecondsSinceEpoch,
    };
  }

  static SerializablePlayer deserialize(Map<String, dynamic> data) {
    return SerializablePlayer(
      name: data['name'],
      score: data['score'],
      starsCollected: data['stars_collected'],
      roundStealCount: data['round_steal_count'],
      gameStealCount: data['game_steal_count'],
      cooldownStartedAt:
          DateTime.fromMicrosecondsSinceEpoch(data['cooldown_started_at']),
      cooldownEndAt:
          DateTime.fromMicrosecondsSinceEpoch(data['cooldown_end_at']),
    );
  }
}
