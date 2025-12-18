import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/helpers.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';

enum LetterStatus {
  normal,
  hidden,
  revealed,
}

class SerializableConfiguration {
  bool showExtension;

  SerializableConfiguration({
    required this.showExtension,
  });

  SerializableConfiguration copyWith({
    bool? showExtension,
  }) {
    return SerializableConfiguration(
        showExtension: showExtension ?? this.showExtension);
  }

  Map<String, dynamic> serialize() {
    return {
      'show_extension': showExtension,
    };
  }

  static SerializableConfiguration deserialize(Map<String, dynamic> data) =>
      SerializableConfiguration(
        showExtension: data['show_extension'] as bool,
      );
}

class SerializableLetterProblem {
  final List<String> letters;
  final List<int> scrambleIndices;
  final List<LetterStatus> uselessLetterStatuses;
  final List<LetterStatus> hiddenLetterStatuses;

  SerializableLetterProblem({
    required this.letters,
    required this.scrambleIndices,
    required this.uselessLetterStatuses,
    required this.hiddenLetterStatuses,
  });

  SerializableLetterProblem copyWith({
    List<String>? letters,
    List<int>? scrambleIndices,
    List<LetterStatus>? uselessLetterStatuses,
    List<LetterStatus>? hiddenLetterStatuses,
    bool? shouldHideHiddenLetter,
  }) =>
      SerializableLetterProblem(
        letters: letters ?? this.letters,
        scrambleIndices: scrambleIndices ?? this.scrambleIndices,
        uselessLetterStatuses:
            uselessLetterStatuses ?? this.uselessLetterStatuses,
        hiddenLetterStatuses: hiddenLetterStatuses ?? this.hiddenLetterStatuses,
      );

  Map<String, dynamic> serialize() {
    return {
      'letters': letters,
      'scramble_indices': scrambleIndices,
      'useless_letter_statuses':
          uselessLetterStatuses.map((e) => e.index).toList(growable: false),
      'hidden_letter_statuses':
          hiddenLetterStatuses.map((e) => e.index).toList(growable: false),
    };
  }

  static SerializableLetterProblem deserialize(Map<String, dynamic> data) {
    return SerializableLetterProblem(
      letters: (data['letters'] as List).cast<String>(),
      scrambleIndices: (data['scramble_indices'] as List).cast<int>(),
      uselessLetterStatuses:
          (data['useless_letter_statuses'] as List).cast<int>().map((e) {
        return LetterStatus.values[e];
      }).toList(growable: false),
      hiddenLetterStatuses: (data['hidden_letter_statuses'] as List)
          .cast<int>()
          .map((e) => LetterStatus.values[e])
          .toList(growable: false),
    );
  }

  ///
  /// Is equal to another [SerializableLetterProblem]
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializableLetterProblem &&
        listEquality(letters, other.letters) &&
        listEquality(scrambleIndices, other.scrambleIndices) &&
        listEquality(uselessLetterStatuses, other.uselessLetterStatuses) &&
        listEquality(hiddenLetterStatuses, other.hiddenLetterStatuses);
  }

  @override
  int get hashCode =>
      letters.hashCode ^
      scrambleIndices.hashCode ^
      uselessLetterStatuses.hashCode ^
      hiddenLetterStatuses.hashCode;
}

class SerializableGameState {
  WordsTrainGameStatus status;
  int round;
  bool isRoundSuccess;
  Duration timeRemaining;

  Map<String, Duration> newCooldowns;

  int pardonRemaining;
  List<String> pardonners;

  int boostRemaining;
  int boostStillNeeded;
  List<String> boosters;

  bool canRequestTheBigHeist;
  bool isAttemptingTheBigHeist;

  bool canRequestEndOfRailwayMiniGame;
  bool isAttemptingEndOfRailwayMiniGame;

  SerializableLetterProblem? letterProblem;

  SerializableConfiguration configuration;

  SerializableMiniGameState? miniGameState;

  SerializableGameState({
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
    required this.canRequestTheBigHeist,
    required this.isAttemptingTheBigHeist,
    required this.canRequestEndOfRailwayMiniGame,
    required this.isAttemptingEndOfRailwayMiniGame,
    required this.configuration,
    required this.miniGameState,
  });

  SerializableGameState copyWith({
    WordsTrainGameStatus? status,
    int? round,
    bool? isRoundSuccess,
    Duration? timeRemaining,
    Map<String, Duration>? newCooldowns,
    SerializableLetterProblem? letterProblem,
    int? pardonRemaining,
    List<String>? pardonners,
    int? boostRemaining,
    int? boostStillNeeded,
    List<String>? boosters,
    bool? canRequestTheBigHeist,
    bool? isAttemptingTheBigHeist,
    bool? canRequestEndOfRailwayMiniGame,
    bool? isAttemptingEndOfRailwayMiniGame,
    SerializableConfiguration? configuration,
    SerializableMiniGameState? miniGameState,
  }) =>
      SerializableGameState(
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
        canRequestTheBigHeist:
            canRequestTheBigHeist ?? this.canRequestTheBigHeist,
        isAttemptingTheBigHeist:
            isAttemptingTheBigHeist ?? this.isAttemptingTheBigHeist,
        canRequestEndOfRailwayMiniGame: canRequestEndOfRailwayMiniGame ??
            this.canRequestEndOfRailwayMiniGame,
        isAttemptingEndOfRailwayMiniGame: isAttemptingEndOfRailwayMiniGame ??
            this.isAttemptingEndOfRailwayMiniGame,
        configuration: configuration ?? this.configuration,
        miniGameState: miniGameState ?? this.miniGameState,
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
      'can_request_the_big_heist': canRequestTheBigHeist,
      'is_attempting_the_big_heist': isAttemptingTheBigHeist,
      'can_request_end_mini_game': canRequestEndOfRailwayMiniGame,
      'is_attempting_end_mini_game': isAttemptingEndOfRailwayMiniGame,
      'configuration': configuration.serialize(),
      'mini_game_state': miniGameState?.serialize(),
    };
  }

  static SerializableGameState deserialize(Map<String, dynamic> data) {
    return SerializableGameState(
      status: WordsTrainGameStatus.values[data['game_status'] as int],
      round: data['round'] as int,
      isRoundSuccess: data['is_round_success'] as bool,
      timeRemaining: Duration(milliseconds: data['time_remaining'] as int),
      newCooldowns: (data['new_cooldowns'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, Duration(milliseconds: value as int))),
      letterProblem: data['letterProblem'] == null
          ? null
          : SerializableLetterProblem.deserialize(data['letterProblem']!),
      pardonRemaining: data['pardon_remaining'] as int,
      pardonners: (data['pardonners'] as List).cast<String>(),
      boostRemaining: data['boost_remaining'] as int,
      boostStillNeeded: data['boost_still_needed'] as int,
      boosters: (data['boosters'] as List).cast<String>(),
      canRequestTheBigHeist: data['can_request_the_big_heist'] as bool,
      isAttemptingTheBigHeist: data['is_attempting_the_big_heist'] as bool,
      canRequestEndOfRailwayMiniGame: data['can_request_end_mini_game'] as bool,
      isAttemptingEndOfRailwayMiniGame:
          data['is_attempting_end_mini_game'] as bool,
      configuration:
          SerializableConfiguration.deserialize(data['configuration']),
      miniGameState: data['mini_game_state'] == null
          ? null
          : SerializableMiniGameState.deserialize(
              data['mini_game_state'] as Map<String, dynamic>),
    );
  }
}
