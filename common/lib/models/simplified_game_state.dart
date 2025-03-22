import 'package:common/models/game_status.dart';
import 'package:common/models/helpers.dart';

enum HiddenLetterStatus {
  normal,
  hidden,
  revealed,
}

class SimplifiedConfiguration {
  bool showExtension;

  SimplifiedConfiguration({
    required this.showExtension,
  });

  SimplifiedConfiguration copyWith({
    bool? showExtension,
  }) {
    return SimplifiedConfiguration(
        showExtension: showExtension ?? this.showExtension);
  }

  Map<String, dynamic> serialize() {
    return {
      'show_extension': showExtension,
    };
  }

  static SimplifiedConfiguration deserialize(Map<String, dynamic> data) =>
      SimplifiedConfiguration(
        showExtension: data['show_extension'] as bool,
      );
}

class SimplifiedLetterProblem {
  final List<String> letters;
  final List<int> scrambleIndices;
  final List<int> revealedUselessLetterIndices;
  final List<HiddenLetterStatus> hiddenLetterStatuses;

  SimplifiedLetterProblem({
    required this.letters,
    required this.scrambleIndices,
    required this.revealedUselessLetterIndices,
    required this.hiddenLetterStatuses,
  });

  SimplifiedLetterProblem copyWith({
    List<String>? letters,
    List<int>? scrambleIndices,
    List<int>? revealedUselessLetterIndices,
    List<HiddenLetterStatus>? hiddenLetterStatuses,
    bool? shouldHideHiddenLetter,
  }) =>
      SimplifiedLetterProblem(
        letters: letters ?? this.letters,
        scrambleIndices: scrambleIndices ?? this.scrambleIndices,
        revealedUselessLetterIndices:
            revealedUselessLetterIndices ?? this.revealedUselessLetterIndices,
        hiddenLetterStatuses: hiddenLetterStatuses ?? this.hiddenLetterStatuses,
      );

  Map<String, dynamic> serialize() {
    return {
      'letters': letters,
      'scramble_indices': scrambleIndices,
      'revealed_useless_letter_indices': revealedUselessLetterIndices,
      'hidden_letter_statuses':
          hiddenLetterStatuses.map((e) => e.index).toList(growable: false),
    };
  }

  static SimplifiedLetterProblem deserialize(Map<String, dynamic> data) {
    return SimplifiedLetterProblem(
      letters: (data['letters'] as List).cast<String>(),
      scrambleIndices: (data['scramble_indices'] as List).cast<int>(),
      revealedUselessLetterIndices:
          (data['revealed_useless_letter_indices'] as List).cast<int>(),
      hiddenLetterStatuses: (data['hidden_letter_statuses'] as List)
          .cast<int>()
          .map((e) => HiddenLetterStatus.values[e])
          .toList(growable: false),
    );
  }

  ///
  /// Is equal to another [SimplifiedLetterProblem]
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SimplifiedLetterProblem &&
        listEquality(letters, other.letters) &&
        listEquality(scrambleIndices, other.scrambleIndices) &&
        listEquality(
            revealedUselessLetterIndices, other.revealedUselessLetterIndices) &&
        listEquality(hiddenLetterStatuses, other.hiddenLetterStatuses);
  }

  @override
  int get hashCode =>
      letters.hashCode ^
      scrambleIndices.hashCode ^
      revealedUselessLetterIndices.hashCode ^
      hiddenLetterStatuses.hashCode;
}

class SimplifiedGameState {
  GameStatus status;
  int round;
  bool isRoundSuccess;
  Duration timeRemaining;

  Map<String, Duration> newCooldowns;

  int pardonRemaining;
  List<String> pardonners;

  int boostRemaining;
  int boostStillNeeded;
  List<String> boosters;

  bool canAttemptTheBigHeist;
  bool isAttemptingTheBigHeist;

  SimplifiedLetterProblem? letterProblem;

  SimplifiedConfiguration configuration;

  SimplifiedGameState({
    required this.status,
    required this.round,
    required this.isRoundSuccess,
    required this.timeRemaining,
    required this.newCooldowns,
    required this.letterProblem,
    required this.pardonRemaining,
    required this.pardonners,
    required this.boostRemaining,
    required this.boostStillNeeded,
    required this.boosters,
    required this.canAttemptTheBigHeist,
    required this.isAttemptingTheBigHeist,
    required this.configuration,
  });

  SimplifiedGameState copyWith({
    GameStatus? status,
    int? round,
    bool? isRoundSuccess,
    Duration? timeRemaining,
    Map<String, Duration>? newCooldowns,
    SimplifiedLetterProblem? letterProblem,
    int? pardonRemaining,
    List<String>? pardonners,
    int? boostRemaining,
    int? boostStillNeeded,
    List<String>? boosters,
    bool? canAttemptTheBigHeist,
    bool? isAttemptingTheBigHeist,
    SimplifiedConfiguration? configuration,
  }) =>
      SimplifiedGameState(
        status: status ?? this.status,
        round: round ?? this.round,
        isRoundSuccess: isRoundSuccess ?? this.isRoundSuccess,
        timeRemaining: timeRemaining ?? this.timeRemaining,
        newCooldowns: newCooldowns ?? this.newCooldowns,
        letterProblem: letterProblem ?? this.letterProblem,
        pardonRemaining: pardonRemaining ?? this.pardonRemaining,
        pardonners: pardonners ?? this.pardonners,
        boostRemaining: boostRemaining ?? this.boostRemaining,
        boostStillNeeded: boostStillNeeded ?? this.boostStillNeeded,
        boosters: boosters ?? this.boosters,
        canAttemptTheBigHeist:
            canAttemptTheBigHeist ?? this.canAttemptTheBigHeist,
        isAttemptingTheBigHeist:
            isAttemptingTheBigHeist ?? this.isAttemptingTheBigHeist,
        configuration: configuration ?? this.configuration,
      );

  Map<String, dynamic> serialize() {
    return {
      'game_status': status.index,
      'round': round,
      'is_round_success': isRoundSuccess,
      'time_remaining': timeRemaining.inMilliseconds,
      'new_cooldowns':
          newCooldowns.map((key, value) => MapEntry(key, value.inMilliseconds)),
      'letterProblem': letterProblem?.serialize(),
      'pardon_remaining': pardonRemaining,
      'pardonners': pardonners,
      'boost_remaining': boostRemaining,
      'boost_still_needed': boostStillNeeded,
      'boosters': boosters,
      'can_attempt_the_big_heist': canAttemptTheBigHeist,
      'is_attempting_the_big_heist': isAttemptingTheBigHeist,
      'configuration': configuration.serialize(),
    };
  }

  static SimplifiedGameState deserialize(Map<String, dynamic> data) {
    return SimplifiedGameState(
      status: GameStatus.values[data['game_status'] as int],
      round: data['round'] as int,
      isRoundSuccess: data['is_round_success'] as bool,
      timeRemaining: Duration(milliseconds: data['time_remaining'] as int),
      newCooldowns: (data['new_cooldowns'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, Duration(milliseconds: value as int))),
      letterProblem: data['letterProblem'] == null
          ? null
          : SimplifiedLetterProblem.deserialize(data['letterProblem']!),
      pardonRemaining: data['pardon_remaining'] as int,
      pardonners: (data['pardonners'] as List).cast<String>(),
      boostRemaining: data['boost_remaining'] as int,
      boostStillNeeded: data['boost_still_needed'] as int,
      boosters: (data['boosters'] as List).cast<String>(),
      canAttemptTheBigHeist: data['can_attempt_the_big_heist'] as bool,
      isAttemptingTheBigHeist: data['is_attempting_the_big_heist'] as bool,
      configuration: SimplifiedConfiguration.deserialize(data['configuration']),
    );
  }
}
