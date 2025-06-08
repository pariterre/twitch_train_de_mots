import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';

class SerializableBlueberryWarGameState implements SerializableMiniGameState {
  SerializableBlueberryWarGameState({
    required this.isTimerRunning,
    required this.timeRemaining,
  });

  @override
  MiniGames get type => MiniGames.blueberryWar;

  final bool isTimerRunning;
  final Duration timeRemaining;

  @override
  Map<String, dynamic> serialize() {
    return {
      'type': MiniGames.blueberryWar.index,
      'is_timer_running': isTimerRunning,
      'time_remaining': timeRemaining.inSeconds,
    };
  }

  static SerializableBlueberryWarGameState deserialize(
      Map<String, dynamic> data) {
    return SerializableBlueberryWarGameState(
      isTimerRunning: data['is_timer_running'] as bool,
      timeRemaining: Duration(seconds: data['time_remaining'] as int),
    );
  }

  @override
  SerializableBlueberryWarGameState copyWith({
    bool? isTimerRunning,
    Duration? timeRemaining,
  }) {
    return SerializableBlueberryWarGameState(
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      timeRemaining: timeRemaining ?? this.timeRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableBlueberryWarGameState &&
        other.isTimerRunning == isTimerRunning &&
        other.timeRemaining == timeRemaining;
  }

  @override
  int get hashCode => isTimerRunning.hashCode ^ timeRemaining.hashCode;
}
