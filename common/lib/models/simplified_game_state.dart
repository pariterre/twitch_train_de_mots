import 'package:common/models/game_status.dart';

class SimplifiedLetterProblem {
  final List<String> letters;
  final List<int> scrambleIndices;
  final int revealedUselessLetterIndex;
  final int hiddenLetterIndex;
  final bool shouldHideHiddenLetter;

  SimplifiedLetterProblem({
    required this.letters,
    required this.scrambleIndices,
    required this.revealedUselessLetterIndex,
    required this.hiddenLetterIndex,
    required this.shouldHideHiddenLetter,
  });

  SimplifiedLetterProblem copyWith({
    List<String>? letters,
    List<int>? scrambleIndices,
    int? revealedUselessLetterIndex,
    int? hiddenLetterIndex,
    bool? shouldHideHiddenLetter,
  }) =>
      SimplifiedLetterProblem(
        letters: letters ??= this.letters,
        scrambleIndices: scrambleIndices ??= this.scrambleIndices,
        revealedUselessLetterIndex: revealedUselessLetterIndex ??=
            this.revealedUselessLetterIndex,
        hiddenLetterIndex: hiddenLetterIndex ??= this.hiddenLetterIndex,
        shouldHideHiddenLetter: shouldHideHiddenLetter ??=
            this.shouldHideHiddenLetter,
      );

  Map<String, dynamic> serialize() {
    return {
      'letters': letters,
      'scramble_indices': scrambleIndices,
      'revealed_useless_letter_index': revealedUselessLetterIndex,
      'hidden_letter_index': hiddenLetterIndex,
      'should_hide_hidden_letter': shouldHideHiddenLetter,
    };
  }

  static SimplifiedLetterProblem deserialize(Map<String, dynamic> data) {
    return SimplifiedLetterProblem(
      letters: (data['letters'] as List).cast<String>(),
      scrambleIndices: (data['scramble_indices'] as List).cast<int>(),
      revealedUselessLetterIndex: data['revealed_useless_letter_index'] as int,
      hiddenLetterIndex: data['hidden_letter_index'] as int,
      shouldHideHiddenLetter: data['should_hide_hidden_letter'] as bool,
    );
  }

  ///
  /// Is equal to another [SimplifiedLetterProblem]
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SimplifiedLetterProblem &&
        other.letters == letters &&
        other.scrambleIndices == scrambleIndices &&
        other.revealedUselessLetterIndex == revealedUselessLetterIndex &&
        other.hiddenLetterIndex == hiddenLetterIndex &&
        other.shouldHideHiddenLetter == shouldHideHiddenLetter;
  }
}

class SimplifiedGameState {
  GameStatus status;
  int round;

  int pardonRemaining;
  List<String> pardonners;

  int boostRemaining;
  int boostStillNeeded;
  List<String> boosters;

  bool canAttemptTheBigHeist;
  bool isAttemptingTheBigHeist;

  SimplifiedLetterProblem? letterProblem;

  SimplifiedGameState({
    required this.status,
    required this.round,
    required this.letterProblem,
    required this.pardonRemaining,
    required this.pardonners,
    required this.boostRemaining,
    required this.boostStillNeeded,
    required this.boosters,
    required this.canAttemptTheBigHeist,
    required this.isAttemptingTheBigHeist,
  });

  SimplifiedGameState copyWith({
    GameStatus? status,
    int? round,
    SimplifiedLetterProblem? letterProblem,
    int? pardonRemaining,
    List<String>? pardonners,
    int? boostRemaining,
    int? boostStillNeeded,
    List<String>? boosters,
    bool? canAttemptTheBigHeist,
    bool? isAttemptingTheBigHeist,
  }) =>
      SimplifiedGameState(
        status: status ??= this.status,
        round: round ??= this.round,
        letterProblem: letterProblem ??= this.letterProblem,
        pardonRemaining: pardonRemaining ??= this.pardonRemaining,
        pardonners: pardonners ??= this.pardonners,
        boostRemaining: boostRemaining ??= this.boostRemaining,
        boostStillNeeded: boostStillNeeded ??= this.boostStillNeeded,
        boosters: boosters ??= this.boosters,
        canAttemptTheBigHeist: canAttemptTheBigHeist ??=
            this.canAttemptTheBigHeist,
        isAttemptingTheBigHeist: isAttemptingTheBigHeist ??=
            this.isAttemptingTheBigHeist,
      );

  Map<String, dynamic> serialize() {
    return {
      'game_status': status.index,
      'round': round,
      'letterProblem': letterProblem?.serialize(),
      'pardon_remaining': pardonRemaining,
      'pardonners': pardonners,
      'boost_remaining': boostRemaining,
      'boost_still_needed': boostStillNeeded,
      'boosters': boosters,
      'can_attempt_the_big_heist': canAttemptTheBigHeist,
      'is_attempting_the_big_heist': isAttemptingTheBigHeist,
    };
  }

  static SimplifiedGameState deserialize(Map<String, dynamic> data) {
    return SimplifiedGameState(
      status: GameStatus.values[data['game_status'] as int],
      round: data['round'] as int,
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
    );
  }
}
