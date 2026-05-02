enum ControllableTimerStatus {
  notInitialized,
  initialized,
  inProgress,
  paused,
  ended,
}

class SerializableControllableTimer {
  final bool isInitialized;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final DateTime? pausedAt;

  SerializableControllableTimer({
    required this.isInitialized,
    required this.startedAt,
    required this.endsAt,
    required this.pausedAt,
  });

  SerializableControllableTimer.empty()
      : isInitialized = false,
        startedAt = null,
        endsAt = null,
        pausedAt = null;

  Map<String, dynamic> serialize() {
    return {
      'started_at': startedAt?.millisecondsSinceEpoch ?? -1,
      'ends_at': endsAt?.millisecondsSinceEpoch ?? -1,
      'is_paused': pausedAt != null,
    };
  }

  SerializableControllableTimer copyWith({
    bool? isInitialized,
    DateTime? startedAt,
    DateTime? endsAt,
    DateTime? pausedAt,
  }) {
    return SerializableControllableTimer(
      isInitialized: isInitialized ?? this.isInitialized,
      startedAt: startedAt ?? this.startedAt,
      endsAt: endsAt ?? this.endsAt,
      pausedAt: pausedAt ?? this.pausedAt,
    );
  }

  static SerializableControllableTimer deserialize(Map<String, dynamic> data) =>
      SerializableControllableTimer(
        isInitialized: false,
        startedAt: data['started_at'] as int >= 0
            ? DateTime.fromMillisecondsSinceEpoch(data['started_at'] as int)
            : null,
        endsAt: data['ends_at'] as int >= 0
            ? DateTime.fromMillisecondsSinceEpoch(data['ends_at'] as int)
            : null,
        pausedAt: data['is_paused'] == true ? DateTime.now() : null,
      );

  Duration? get timeRemaining => endsAt?.difference(DateTime.now());

  ControllableTimerStatus get status {
    final isStarted = endsAt != null;
    final isPaused = pausedAt != null;
    final isOver = (timeRemaining != null && timeRemaining!.isNegative);

    if (!isInitialized) {
      return ControllableTimerStatus.notInitialized;
    } else if (isOver) {
      return ControllableTimerStatus.ended;
    } else if (isPaused) {
      return ControllableTimerStatus.paused;
    } else if (isStarted) {
      return ControllableTimerStatus.inProgress;
    } else {
      return ControllableTimerStatus.initialized;
    }
  }
}
