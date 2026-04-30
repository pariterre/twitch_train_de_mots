import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/helpers.dart';
import 'package:common/generic/models/round_success.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/generic/models/serializable_player.dart';
import 'package:common/generic/models/success_level.dart';

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

  SerializableLetterProblem.empty()
      : letters = [],
        scrambleIndices = [],
        uselessLetterStatuses = [],
        hiddenLetterStatuses = [];

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
  final Map<String, SerializablePlayer> players;

  final bool hasPlayedAtLeastOnce;
  final WordsTrainGameStatus gameStatus;
  final bool isRoundAMiniGame;

  final int roundCount;
  final SerializableControllableTimer roundTimer;
  final SerializableLetterProblem letterProblem;
  final List<String> pardonners;
  final int pardonRemaining;
  final int boostRemaining;
  final int boostStillNeeded;
  final List<String> boosters;
  final bool canChangeLane;

  final SuccessLevel successLevel;
  final List<RoundSuccess> roundSuccesses;
  final bool canRequestFireworks;
  final bool canRequestTheBigHeist;
  final bool isAttemptingTheBigHeist;
  final bool canRequestFixTracksMiniGame;
  final bool isAttemptingFixTracksMiniGame;

  SerializableConfiguration configuration;

  SerializableMiniGameState? miniGameState;

  SerializableGameState({
    required this.hasPlayedAtLeastOnce,
    required this.roundCount,
    required this.gameStatus,
    required this.isRoundAMiniGame,
    required this.roundTimer,
    required this.successLevel,
    required this.roundSuccesses,
    required this.players,
    required this.letterProblem,
    required this.pardonRemaining,
    required this.pardonners,
    required this.boostRemaining,
    required this.boostStillNeeded,
    required this.boosters,
    required this.canChangeLane,
    required this.canRequestFireworks,
    required this.canRequestTheBigHeist,
    required this.isAttemptingTheBigHeist,
    required this.canRequestFixTracksMiniGame,
    required this.isAttemptingFixTracksMiniGame,
    required this.configuration,
    required this.miniGameState,
  });

  SerializableGameState copyWith({
    bool? hasPlayedAtLeastOnce,
    int? roundCount,
    WordsTrainGameStatus? gameStatus,
    bool? isRoundAMiniGame,
    SuccessLevel? successLevel,
    List<RoundSuccess>? roundSuccesses,
    SerializableControllableTimer? roundTimer,
    Map<String, SerializablePlayer>? players,
    SerializableLetterProblem? letterProblem,
    int? pardonRemaining,
    List<String>? pardonners,
    int? boostRemaining,
    int? boostStillNeeded,
    List<String>? boosters,
    bool? canChangeLane,
    bool? canRequestFireworks,
    bool? canRequestTheBigHeist,
    bool? isAttemptingTheBigHeist,
    bool? canRequestFixTracksMiniGame,
    bool? isAttemptingFixTracksMiniGame,
    SerializableConfiguration? configuration,
    SerializableMiniGameState? miniGameState,
  }) =>
      SerializableGameState(
        hasPlayedAtLeastOnce: hasPlayedAtLeastOnce ?? this.hasPlayedAtLeastOnce,
        roundCount: roundCount ?? this.roundCount,
        gameStatus: gameStatus ?? this.gameStatus,
        isRoundAMiniGame: isRoundAMiniGame ?? this.isRoundAMiniGame,
        successLevel: successLevel ?? this.successLevel,
        roundSuccesses: roundSuccesses ?? this.roundSuccesses,
        roundTimer: roundTimer ?? this.roundTimer,
        players: players ?? this.players,
        letterProblem: letterProblem ?? this.letterProblem,
        pardonRemaining: pardonRemaining ?? this.pardonRemaining,
        pardonners: pardonners ?? this.pardonners,
        boostRemaining: boostRemaining ?? this.boostRemaining,
        boostStillNeeded: boostStillNeeded ?? this.boostStillNeeded,
        boosters: boosters ?? this.boosters,
        canChangeLane: canChangeLane ?? this.canChangeLane,
        canRequestFireworks: canRequestFireworks ?? this.canRequestFireworks,
        canRequestTheBigHeist:
            canRequestTheBigHeist ?? this.canRequestTheBigHeist,
        isAttemptingTheBigHeist:
            isAttemptingTheBigHeist ?? this.isAttemptingTheBigHeist,
        canRequestFixTracksMiniGame:
            canRequestFixTracksMiniGame ?? this.canRequestFixTracksMiniGame,
        isAttemptingFixTracksMiniGame:
            isAttemptingFixTracksMiniGame ?? this.isAttemptingFixTracksMiniGame,
        configuration: configuration ?? this.configuration,
        miniGameState: miniGameState ?? this.miniGameState,
      );

  int checksum() {
    return Object.hash(
      hasPlayedAtLeastOnce,
      roundCount,
      gameStatus,
      isRoundAMiniGame,
      successLevel,
      roundSuccesses,
      roundTimer,
      players.entries.map((e) => Object.hash(e.key, e.value)).toList(),
      letterProblem,
      pardonRemaining,
      pardonners,
      boostRemaining,
      boostStillNeeded,
      boosters,
      canChangeLane,
      canRequestFireworks,
      canRequestTheBigHeist,
      isAttemptingTheBigHeist,
      canRequestFixTracksMiniGame,
      isAttemptingFixTracksMiniGame,
    );
  }

  Map<String, dynamic> serialize() {
    return {
      'has_played_at_least_once': hasPlayedAtLeastOnce,
      'players': players.map((key, value) => MapEntry(key, value.serialize())),
      'round': roundCount,
      'game_status': gameStatus.index,
      'is_round_a_mini_game': isRoundAMiniGame,
      'success_level': successLevel.index,
      'round_successes':
          roundSuccesses.map((e) => e.index).toList(growable: false),
      'round_timer': roundTimer.serialize(),
      'letter_problem': letterProblem.serialize(),
      'pardon_remaining': pardonRemaining,
      'pardonners': pardonners,
      'boost_remaining': boostRemaining,
      'boost_still_needed': boostStillNeeded,
      'boosters': boosters,
      'can_change_lane': canChangeLane,
      'can_request_fireworks': canRequestFireworks,
      'can_request_the_big_heist': canRequestTheBigHeist,
      'is_attempting_the_big_heist': isAttemptingTheBigHeist,
      'can_request_end_mini_game': canRequestFixTracksMiniGame,
      'is_attempting_end_mini_game': isAttemptingFixTracksMiniGame,
      'configuration': configuration.serialize(),
      'mini_game_state': miniGameState?.serialize(),
    };
  }

  static SerializableGameState deserialize(Map<String, dynamic> data) {
    return SerializableGameState(
      hasPlayedAtLeastOnce: data['has_played_at_least_once'] as bool,
      players: (data['players'] as Map<String, dynamic>).map((key, value) =>
          MapEntry(key,
              SerializablePlayer.deserialize(value as Map<String, dynamic>))),
      roundCount: data['round'] as int,
      gameStatus: WordsTrainGameStatus.values[data['game_status'] as int],
      isRoundAMiniGame: data['is_round_a_mini_game'] as bool? ?? false,
      successLevel: SuccessLevel.values[data['success_level'] as int],
      roundSuccesses: (data['round_successes'] as List)
          .cast<int>()
          .map((e) => RoundSuccess.values[e])
          .toList(growable: false),
      roundTimer: SerializableControllableTimer.deserialize(
          data['round_timer'] as Map<String, dynamic>),
      letterProblem: SerializableLetterProblem.deserialize(
          data['letter_problem'] as Map<String, dynamic>),
      pardonRemaining: data['pardon_remaining'] as int,
      pardonners: (data['pardonners'] as List).cast<String>(),
      boostRemaining: data['boost_remaining'] as int,
      boostStillNeeded: data['boost_still_needed'] as int,
      boosters: (data['boosters'] as List).cast<String>(),
      canChangeLane: data['can_change_lane'] as bool? ?? false,
      canRequestFireworks: data['can_request_fireworks'] as bool? ?? false,
      canRequestTheBigHeist:
          data['can_request_the_big_heist'] as bool? ?? false,
      isAttemptingTheBigHeist: data['is_attempting_the_big_heist'] as bool,
      canRequestFixTracksMiniGame: data['can_request_end_mini_game'] as bool,
      isAttemptingFixTracksMiniGame:
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
