// import 'dart:async';

// import 'package:collection/collection.dart';
// import 'package:common/generic/managers/dictionary_manager.dart';
// import 'package:common/generic/models/exceptions.dart';
// import 'package:common/generic/models/game_status.dart';
// import 'package:common/generic/models/generic_listener.dart';
// import 'package:common/generic/models/valuable_letter.dart';
// import 'package:common/track_fix/models/serializable_track_fix_game_state.dart';
// import 'package:common/track_fix/models/track_fix_grid.dart';
// import 'package:logging/logging.dart';
// import 'package:train_de_mots/generic/managers/managers.dart';
// import 'package:train_de_mots/generic/managers/mini_games_manager.dart';

// final _logger = Logger('TrackFixGameManager');

// final _dictionary = DictionaryManager.wordsWithAtLeast(
//     TrackFixGameManager._minimumSegmentLength);

// ///
// /// Easy accessors translating index into row/col pair or row/col pair into
// /// index

// enum EndGameStatus {
//   won,
//   lostOnTime,
//   lostOnDeadEnd,
// }

// enum TrackFixSolutionStatus {
//   isValid,
//   isNotTheRightLength,
//   hasMisplacedLetters,
//   isAlreadyUsed,
//   wordIsTooShort,
//   isNotInDictionary,
//   noMoreSegmentsToFix,
//   unknown,
// }

// class TrackFixGameManager implements MiniGameManager {
//   TrackFixGameManager() {
//     _asyncInitializations();
//   }

//   Future<void> _asyncInitializations() async {
//     _logger.config('Initializing...');

//     while (true) {
//       try {
//         final tm = Managers.instance.twitch;
//         tm.addChatListener(trySolution);
//         break;
//       } on ManagerNotInitializedException {
//         // Wait and repeat
//         await Future.delayed(const Duration(milliseconds: 100));
//       }
//     }

//     _logger.config('Ready');
//   }

//   ///
//   /// Players points earned during the game
//   final Map<String, int> _playersPoints = {};
//   @override
//   Map<String, int> get playersPoints => Map.from(_playersPoints);

//   ///
//   /// Time remaining
//   bool _isReady = false;
//   @override
//   bool get isReady => _isReady;
//   bool _isMainTimerRunning = false;
//   Timer? _timer;
//   Duration _timeRemaining = Duration.zero;
//   @override
//   Duration get timeRemaining => _timeRemaining;
//   bool _forceEndOfGame = false;

//   // Listeners
//   @override
//   final onGameIsReady = GenericListener<Function()>();
//   final onGameStarted = GenericListener<Function()>();
//   @override
//   final onGameUpdated = GenericListener<Function()>();
//   final onClockTicked = GenericListener<Function(Duration)>();
//   final onTrySolution = GenericListener<
//       Function({
//         required String playerName,
//         required String word,
//         required TrackFixSolutionStatus solutionStatus,
//         required int pointsAwarded,
//       })>();
//   @override
//   final onGameEnded = GenericListener<Function({required bool hasWon})>();

//   // Size and content of the grid
//   static const int _rowCount = 20;
//   static const int _columnCount = 10;
//   static const int _minimumSegmentLength = 4;
//   static const int _maximumSegmentLength = 8;
//   static const int _expectedSegmentsCount = 9;
//   static const int _expectedSegmentsWithLettersCount = 5;

//   Grid? _grid;
//   Grid get grid => _grid!;

//   ///
//   /// If the game is over
//   bool get _hasWon => _grid?.allSegmentsAreFixed ?? false;
//   EndGameStatus? get endGameStatus => !_isGameOver
//       ? null
//       : (_hasWon
//           ? EndGameStatus.won
//           : _timeRemaining.inSeconds <= 0
//               ? EndGameStatus.lostOnTime
//               : EndGameStatus.lostOnDeadEnd);

//   bool get _isGameOver =>
//       _forceEndOfGame || _hasWon || _timeRemaining.inSeconds <= 0;

//   @override
//   String? get instructions =>
//       'Le train s\'est arrêté devant des rails brisés, mais nous avons une dernière chance de le remettre en marche!\n'
//       '\n'
//       'Réparons les rails en remplissant les segments avec des mots valides. '
//       'Mais attention, si aucun mot valide n\'existe pour un segment, ou si nous '
//       'n\'arrivons pas à atteindre la fin du rail dans le temps imparti, le train restera bloqué!\n';

//   @override
//   Future<void> initialize() async {
//     while (true) {
//       _grid = Grid.random(
//         rowCount: _rowCount,
//         columnCount: _columnCount,
//         minimumSegmentLength: _minimumSegmentLength,
//         maximumSegmentLength: _maximumSegmentLength,
//         expectedSegmentsCount: _expectedSegmentsCount,
//         segmentsWithLettersCount: _expectedSegmentsWithLettersCount,
//       );
//       // Check that all segments have at least one valid word in the dictionary
//       for (final segment in _grid!.segments) {
//         if (!segmentHasValidWords(segment)) {
//           continue;
//         }
//       }
//       break;
//     }
//     _isMainTimerRunning = false;
//     _timeRemaining = Duration(seconds: 60);
//     _playersPoints.clear();
//     _isReady = true;
//     _forceEndOfGame = false;
//     onGameIsReady.notifyListeners((callback) => callback());
//   }

//   @override
//   SerializableTrackFixGameState serialize() {
//     return SerializableTrackFixGameState(
//       grid: _grid!,
//       isTimerRunning: _isMainTimerRunning,
//       timeRemaining: _timeRemaining,
//     );
//   }

//   @override
//   Future<void> start() async {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) => _gameLoop());

//     onGameStarted.notifyListeners((callback) => callback());
//   }

//   @override
//   Future<void> end() async {
//     _forceEndOfGame = true;
//   }

//   void trySolution(String playerName, String message) {
//     //if (!_isMainTimerRunning) return;

//     // Transform the message so it is only the first word all in uppercase
//     final words = message.split(' ');
//     if (words.isEmpty || words.length > 1) return;

//     final word = words.first.toUpperCase();
//     final wordValue = 3 *
//         word
//             .split('')
//             .map((e) => ValuableLetter.getValueOfLetter(e))
//             .reduce((a, b) => a + b);

//     final solutionStatus = tryFixSegment(word);
//     if (solutionStatus == TrackFixSolutionStatus.isValid) {
//       _playersPoints[playerName] = wordValue;
//     }

//     onTrySolution.notifyListeners((callback) => callback(
//         playerName: playerName,
//         word: word,
//         solutionStatus: solutionStatus,
//         pointsAwarded: wordValue));

//     if (!segmentHasValidWords(grid.nextEmptySegment)) {
//       // We got to a dead end, end the game
//       _forceEndOfGame = true;
//     }
//   }

//   ///
//   /// The game loop
//   void _gameLoop() {
//     if (_isGameOver) return _processGameOver();
//     if (!_isMainTimerRunning) {
//       if (Managers.instance.train.gameStatus ==
//           WordsTrainGameStatus.miniGameStarted) {
//         _isMainTimerRunning = true;
//       }
//       return;
//     }

//     _tickClock();
//   }

//   void _processGameOver() {
//     _isMainTimerRunning = false;
//     _timer?.cancel();
//     _timer = null;
//     _forceEndOfGame = false;

//     onGameEnded.notifyListeners((callback) => callback(hasWon: _hasWon));
//   }

//   ///
//   /// Tick the clock by one second
//   void _tickClock() {
//     _timeRemaining -= const Duration(seconds: 1);
//     onClockTicked.notifyListeners((callback) => callback(_timeRemaining));
//   }

//   ///
//   /// Attempt to fix a segment with the given [word]
//   /// Returns true if the segment was successfully fixed
//   TrackFixSolutionStatus tryFixSegment(String word) {
//     if (_grid == null) return TrackFixSolutionStatus.unknown;
//     if (word.length < _minimumSegmentLength) {
//       return TrackFixSolutionStatus.wordIsTooShort;
//     }
//     if (!_dictionary.contains(word)) {
//       return TrackFixSolutionStatus.isNotInDictionary;
//     }

//     final segment = _grid!.nextEmptySegment;
//     if (segment == null) return TrackFixSolutionStatus.noMoreSegmentsToFix;

//     // The word must have the correct length
//     if (word.length != segment.length) {
//       return TrackFixSolutionStatus.isNotTheRightLength;
//     }

//     // Check that pre-existing letters match the provided word
//     for (int i = 0; i < segment.length; i++) {
//       final tile = _grid!.tileOfSegmentAt(segment: segment, index: i);
//       if (tile == null) return TrackFixSolutionStatus.unknown;
//       if (tile.hasLetter && tile.letter != word[i]) {
//         return TrackFixSolutionStatus.hasMisplacedLetters;
//       }
//     }

//     for (final segment in _grid!.segments) {
//       // The word must be unique among fixed segments
//       if (segment.isComplete && segment.word == word) {
//         return TrackFixSolutionStatus.isAlreadyUsed;
//       }
//     }

//     // All checks passed, fix the segment
//     segment.word = word;
//     for (int i = 0; i < segment.length; i++) {
//       final tile = _grid!.tileOfSegmentAt(segment: segment, index: i);
//       if (tile == null) return TrackFixSolutionStatus.unknown;
//       tile.letter = word[i];
//     }

//     return TrackFixSolutionStatus.isValid;
//   }

//   bool segmentHasValidWords(PathSegment? segment) {
//     if (_grid == null || segment == null) return false;

//     final letterMap = <int, String>{};
//     for (int i = 0; i < segment.length; i++) {
//       final tile = _grid!.tileOfSegmentAt(segment: segment, index: i);
//       if (tile == null) return false;
//       if (tile.hasLetter) {
//         letterMap[i] = tile.letter!;
//       }
//     }
//     final hasWordInDictionary = _dictionary.firstWhereOrNull((e) =>
//         e.length == segment.length &&
//         letterMap.entries.every((entry) => e[entry.key] == entry.value));

//     return hasWordInDictionary != null;
//   }
// }
