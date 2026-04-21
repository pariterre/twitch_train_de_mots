enum ControllableTimerStatus {
  notInitialized,
  initialized,
  inProgress,
  paused,
  ended,
}

class SerializableControllableTimer {
  final bool isInitialized;
  final DateTime? endsAt;
  final DateTime? pausedAt;

  SerializableControllableTimer({
    required this.isInitialized,
    required this.endsAt,
    required this.pausedAt,
  });

  Map<String, dynamic> serialize() {
    return {
      'is_initialized': isInitialized,
      'ends_at': endsAt?.toIso8601String(),
      'is_paused': pausedAt != null,
    };
  }

  SerializableControllableTimer copyWith({
    bool? isInitialized,
    DateTime? endsAt,
    DateTime? pausedAt,
  }) {
    return SerializableControllableTimer(
      isInitialized: isInitialized ?? this.isInitialized,
      endsAt: endsAt ?? this.endsAt,
      pausedAt: pausedAt ?? this.pausedAt,
    );
  }

  static SerializableControllableTimer deserialize(Map<String, dynamic> data) {
    return SerializableControllableTimer(
      isInitialized: data['is_initialized'] as bool,
      endsAt: data['ends_at'] != null
          ? DateTime.parse(data['ends_at'] as String)
          : null,
      pausedAt: data['is_paused'] == true ? DateTime.now() : null,
    );
  }

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
