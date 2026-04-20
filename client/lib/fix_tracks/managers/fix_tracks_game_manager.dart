import 'dart:async';

import 'package:collection/collection.dart';
import 'package:common/fix_tracks/models/fix_tracks_grid.dart';
import 'package:common/fix_tracks/models/serializable_fix_tracks_game_state.dart';
import 'package:common/generic/managers/dictionary_manager.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/valuable_letter.dart';
import 'package:diacritic/diacritic.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/game_round_manager.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/managers/mini_games_manager.dart';

final _logger = Logger('FixTracksGameManager');

final _dictionary = DictionaryManager.wordsWithAtLeast(
    FixTracksGameManager._minimumSegmentLength);

///
/// Easy accessors translating index into row/col pair or row/col pair into
/// index

enum EndGameStatus {
  won,
  lostOnTime,
  lostOnDeadEnd,
}

enum FixTracksSolutionStatus {
  isValid,
  isNotTheRightLength,
  hasMisplacedLetters,
  isAlreadyUsed,
  wordIsTooShort,
  isNotInDictionary,
  noMoreSegmentsToFix,
  unknown,
}

class FixTracksGameManager extends MiniGameManager {
  FixTracksGameManager() {
    _asyncInitializations();
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');

    while (true) {
      try {
        final tm = Managers.instance.twitch;
        tm.addChatListener(trySolution);
        break;
      } on ManagerNotInitializedException {
        // Wait and repeat
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    _logger.config('Ready');
  }

  ///
  /// Players points earned during the game
  final Map<String, int> _playersPoints = {};
  @override
  Map<String, int> get playersPoints => Map.from(_playersPoints);

  // Listeners
  @override
  final onGameUpdated = GenericListener<Function()>();
  final onTrySolution = GenericListener<
      Function({
        required String playerName,
        required String word,
        required FixTracksSolutionStatus solutionStatus,
        required int pointsAwarded,
      })>();

  // Size and content of the grid
  static const int _rowCount = 20;
  static const int _columnCount = 10;
  static const int _minimumSegmentLength = 4;
  static const int _maximumSegmentLength = 8;
  static const int _expectedSegmentCount = 9;
  static const int _expectedSegmentsWithLetterCount = 5;

  FixTracksGrid? _grid;
  FixTracksGrid get grid => _grid!;

  ///
  /// If the game is over
  EndGameStatus? _endGameStatus;
  EndGameStatus? get endGameStatus => _endGameStatus;
  @override
  bool get hasWon => endGameStatus == EndGameStatus.won;

  @override
  String? get instructions =>
      'Le train s\'est arrêté devant des rails brisés, mais nous avons une dernière chance de le remettre en marche!\n'
      '\n'
      'Réparons les rails en remplissant les segments avec des mots valides. '
      'Mais attention, si aucun mot valide n\'existe pour un segment, ou si nous '
      'n\'arrivons pas à atteindre la fin du rail dans le temps imparti, le train restera bloqué!\n';

  @override
  Future<void> initializeRound() async {
    while (true) {
      _grid = FixTracksGrid.random(
        rowCount: _rowCount,
        columnCount: _columnCount,
        minimumSegmentLength: _minimumSegmentLength,
        maximumSegmentLength: _maximumSegmentLength,
        segmentCount: _expectedSegmentCount,
        segmentsWithLetterCount: _expectedSegmentsWithLetterCount,
      );
      // Check that all segments have at least one valid word in the dictionary
      for (final segment in _grid!.segments) {
        if (!segmentHasValidWords(segment)) {
          continue;
        }
      }
      break;
    }
    _playersPoints.clear();
    await super.initializeRound();
  }

  @override
  SerializableFixTracksGameState serializeMiniGame() {
    return SerializableFixTracksGameState(
      round: toSerializableRound(),
      grid: _grid!,
    );
  }

  @override
  Future<void> startRound({Duration? duration}) async {
    if (duration != null) {
      throw ArgumentError(
          'Duration should not be provided, it is determined by the game manager based on the previous round time remaining');
    }

    await super.startRound(duration: duration);
  }

  void trySolution(String playerName, String message) {
    if (roundStatus != GameRoundStatus.inProgress) return;

    // Transform the message so it is only the first word all in uppercase
    final words = message.split(' ');
    if (words.isEmpty || words.length > 1 || words.first[0] == '!') return;

    final word = removeDiacritics(words.first.toUpperCase());
    // Refuse any word that contains non-letter characters
    if (!RegExp(r'^[A-Z]+$').hasMatch(word)) return;

    final wordValue = 3 *
        word
            .split('')
            .map((e) => ValuableLetter.getValueOfLetter(e))
            .reduce((a, b) => a + b);

    final solutionStatus = tryFixSegment(word);
    if (solutionStatus == FixTracksSolutionStatus.isValid) {
      _playersPoints[playerName] = wordValue;
      onGameUpdated.notifyListeners((callback) => callback());
    }

    onTrySolution.notifyListeners((callback) => callback(
        playerName: playerName,
        word: word,
        solutionStatus: solutionStatus,
        pointsAwarded: wordValue));
  }

  @override
  Future<bool> shouldEndRoundImmediately() async {
    // We got to a dead end, end the game
    return !segmentHasValidWords(grid.nextEmptySegment);
  }

  @override
  Future<void> processRoundIsEnding() async {
    if (_grid?.allSegmentsAreFixed ?? false) {
      _endGameStatus = EndGameStatus.won;
    } else if (timeRemaining?.isNegative ?? true) {
      _endGameStatus = EndGameStatus.lostOnTime;
    } else {
      _endGameStatus = EndGameStatus.lostOnDeadEnd;
    }
  }

  ///
  /// Attempt to fix a segment with the given [word]
  /// Returns true if the segment was successfully fixed
  FixTracksSolutionStatus tryFixSegment(String word) {
    if (_grid == null) return FixTracksSolutionStatus.unknown;
    if (word.length < _minimumSegmentLength) {
      return FixTracksSolutionStatus.wordIsTooShort;
    }
    if (!_dictionary.contains(word)) {
      return FixTracksSolutionStatus.isNotInDictionary;
    }

    final segment = _grid!.nextEmptySegment;
    if (segment == null) return FixTracksSolutionStatus.noMoreSegmentsToFix;

    // The word must have the correct length
    if (word.length != segment.length) {
      return FixTracksSolutionStatus.isNotTheRightLength;
    }

    // Check that pre-existing letters match the provided word
    for (int i = 0; i < segment.length; i++) {
      final tile = _grid!.tileOfSegmentAt(segment: segment, index: i);
      if (tile == null) return FixTracksSolutionStatus.unknown;
      if (tile.hasLetter && tile.letter != word[i]) {
        return FixTracksSolutionStatus.hasMisplacedLetters;
      }
    }

    for (final segment in _grid!.segments) {
      // The word must be unique among fixed segments
      if (segment.isComplete && segment.word == word) {
        return FixTracksSolutionStatus.isAlreadyUsed;
      }
    }

    // All checks passed, fix the segment
    segment.word = word;
    for (int i = 0; i < segment.length; i++) {
      final tile = _grid!.tileOfSegmentAt(segment: segment, index: i);
      if (tile == null) return FixTracksSolutionStatus.unknown;
      tile.letter = word[i];
    }

    return FixTracksSolutionStatus.isValid;
  }

  bool segmentHasValidWords(PathSegment? segment) {
    if (_grid == null || segment == null) return false;

    final letterMap = <int, String>{};
    for (int i = 0; i < segment.length; i++) {
      final tile = _grid!.tileOfSegmentAt(segment: segment, index: i);
      if (tile == null) return false;
      if (tile.hasLetter) {
        letterMap[i] = tile.letter!;
      }
    }
    final hasWordInDictionary = _dictionary.firstWhereOrNull((e) =>
        e.length == segment.length &&
        letterMap.entries.every((entry) => e[entry.key] == entry.value));

    return hasWordInDictionary != null;
  }
}
