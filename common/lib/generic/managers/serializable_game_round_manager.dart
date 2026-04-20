enum GameRoundStatus {
  initialized,
  inProgress,
  paused,
  ended,
}

class SerializableGameRoundManager {
  final DateTime? roundEndsAt;
  final DateTime? pauseStartedAt;

  SerializableGameRoundManager({
    required this.roundEndsAt,
    required this.pauseStartedAt,
  });

  Map<String, dynamic> serialize() {
    return {
      'ends_at': roundEndsAt?.toIso8601String(),
      'is_paused': pauseStartedAt != null,
    };
  }

  SerializableGameRoundManager copyWith({
    DateTime? roundEndsAt,
    DateTime? pauseStartedAt,
  }) {
    return SerializableGameRoundManager(
      roundEndsAt: roundEndsAt ?? this.roundEndsAt,
      pauseStartedAt: pauseStartedAt ?? this.pauseStartedAt,
    );
  }

  static SerializableGameRoundManager deserialize(Map<String, dynamic> data) {
    return SerializableGameRoundManager(
      roundEndsAt: data['ends_at'] != null
          ? DateTime.parse(data['ends_at'] as String)
          : null,
      pauseStartedAt: data['is_paused'] == true ? DateTime.now() : null,
    );
  }

  Duration? get timeRemaining => roundEndsAt?.difference(DateTime.now());

  GameRoundStatus get status {
    final isStarted = roundEndsAt != null;
    final isPaused = pauseStartedAt != null;
    final isOver = (timeRemaining?.isNegative ?? true) && !isPaused;

    if (isOver) {
      return GameRoundStatus.ended;
    } else if (isPaused) {
      return GameRoundStatus.paused;
    } else if (isStarted) {
      return GameRoundStatus.inProgress;
    } else {
      return GameRoundStatus.initialized;
    }
  }
}
