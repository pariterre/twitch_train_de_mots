import 'package:common/models/game_status.dart';

class SimplifiedGameState {
  GameStatus status;
  int round;

  int pardonRemaining;
  List<String> pardonners;

  int boostRemaining;
  int boostStillNeeded;

  SimplifiedGameState({
    required this.status,
    required this.round,
    required this.pardonRemaining,
    required this.pardonners,
    required this.boostRemaining,
    required this.boostStillNeeded,
  });

  SimplifiedGameState copyWith({
    GameStatus? status,
    int? round,
    int? pardonRemaining,
    List<String>? pardonners,
    int? boostRemaining,
    int? boostStillNeeded,
  }) =>
      SimplifiedGameState(
        status: status ??= this.status,
        round: round ??= this.round,
        pardonRemaining: pardonRemaining ??= this.pardonRemaining,
        pardonners: pardonners ??= this.pardonners,
        boostRemaining: boostRemaining ??= this.boostRemaining,
        boostStillNeeded: boostStillNeeded ??= this.boostStillNeeded,
      );

  Map<String, dynamic> serialize() {
    return {
      'game_status': status.index,
      'round': round,
      'pardon_remaining': pardonRemaining,
      'pardonners': pardonners,
      'boost_remaining': boostRemaining,
      'boost_still_needed': boostStillNeeded,
    };
  }

  static SimplifiedGameState deserialize(Map<String, dynamic> data) {
    return SimplifiedGameState(
      status: GameStatus.values[data['game_status'] as int],
      round: data['round'] as int,
      pardonRemaining: data['pardon_remaining'] as int,
      pardonners: (data['pardonners'] as List).cast<String>(),
      boostRemaining: data['boost_remaining'] as int,
      boostStillNeeded: data['boost_still_needed'] as int,
    );
  }
}
