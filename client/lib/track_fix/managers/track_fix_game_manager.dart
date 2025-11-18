import 'dart:async';
import 'dart:math';

import 'package:common/generic/managers/dictionary_manager.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/valuable_letter.dart';
import 'package:common/track_fix/models/serializable_track_fix_game_state.dart';
import 'package:common/track_fix/models/track_fix_grid.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/managers/mini_games_manager.dart';

final _logger = Logger('TrackFixGameManager');
final _random = Random();

///
/// Easy accessors translating index into row/col pair or row/col pair into
/// index

class TrackFixGameManager implements MiniGameManager {
  TrackFixGameManager() {
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

  ///
  /// Time remaining
  bool _isReady = false;
  @override
  bool get isReady => _isReady;
  bool _isMainTimerRunning = false;
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  @override
  Duration get timeRemaining => _timeRemaining;
  bool _forceEndOfGame = false;

  Duration _autoplayTimeRemaining = Duration(seconds: 10);

  ///
  /// Current problem
  final _dictionary = DictionaryManager.wordsWithAtLeast(6).toList();
  SerializableLetterProblem? _problem;
  SerializableLetterProblem get problem =>
      _problem == null ? throw "This should not happen" : _problem!;
  List<String> get letters => List.from(problem.letters, growable: false);

  ///
  /// Number of tries remaining
  int _triesRemaining = 0;
  int get triesRemaining => _triesRemaining;

  // Listeners
  @override
  final onGameIsReady = GenericListener<Function()>();
  final onGameStarted = GenericListener<Function()>();
  @override
  final onGameUpdated = GenericListener<Function()>();
  final onClockTicked = GenericListener<Function(Duration)>();
  final onTrySolution = GenericListener<
      Function(
          String sender, String word, bool isSuccess, int pointsAwarded)>();
  final onTileRevealed = GenericListener<Function(Tile)>();
  final onRewardFound = GenericListener<Function(Tile)>();
  @override
  final onGameEnded = GenericListener<Function(bool)>();

  // Size of the grid
  final int _rowCount = 20;
  final int _columnCount = 10;
  final int _rewardsCount = 40;
  Grid? _grid;
  Grid get grid => _grid!;

  ///
  /// Get the number of letters that were found
  int get letterFoundCount => problem.hiddenLetterStatuses.fold(
      0, (prev, status) => prev + (status == LetterStatus.normal ? 1 : 0));

  ///
  /// If the game is over
  bool get hasWon => letterFoundCount == problem.letters.length;
  bool get hasLost => isGameOver && !hasWon;
  bool get isGameOver =>
      _forceEndOfGame ||
      hasWon ||
      _timeRemaining.inSeconds <= 0 ||
      _triesRemaining <= 0;

  @override
  String? get instructions => null;
  // TODO Write the telegram

  @override
  Future<void> initialize() async {
    _generateProblem();
    _grid = Grid.random(
        rowCount: _rowCount,
        columnCount: _columnCount,
        rewardsCount: _rewardsCount,
        problem: _problem!);
    _isMainTimerRunning = false;
    _timeRemaining = Duration(
      seconds:
          max(20, Managers.instance.train.previousRoundTimeRemaining.inSeconds),
    );
    _triesRemaining = 10;
    _playersPoints.clear();
    _isReady = true;
    _forceEndOfGame = false;
    _autoplayTimeRemaining = Duration(seconds: 10);
    onGameIsReady.notifyListeners((callback) => callback());
  }

  @override
  SerializableTrackFixGameState serialize() {
    return SerializableTrackFixGameState(
      grid: _grid!,
      isTimerRunning: _isMainTimerRunning,
      timeRemaining: _timeRemaining,
      triesRemaining: _triesRemaining,
    );
  }

  @override
  Future<void> start() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _gameLoop());

    onGameStarted.notifyListeners((callback) => callback());
  }

  @override
  Future<void> end() async {
    _forceEndOfGame = true;
  }

  void trySolution(String playerName, String message) {
    if (!_isMainTimerRunning) return;

    // Transform the message so it is only the first word all in uppercase
    final words = message.split(' ');
    if (words.isEmpty || words.length > 1) return;
    final word = words.first.toUpperCase();
    final wordValue = 5 *
        word
            .split('')
            .map((e) => ValuableLetter.getValueOfLetter(e))
            .reduce((a, b) => a + b);

    final isSolutionRight = word == problem.letters.join();
    if (isSolutionRight) {
      for (int i = 0; i < _problem!.uselessLetterStatuses.length; i++) {
        _problem!.uselessLetterStatuses[i] = LetterStatus.normal;
        _problem!.hiddenLetterStatuses[i] = LetterStatus.normal;
      }
      _playersPoints[playerName] = wordValue;
    } else {
      _triesRemaining--;
    }
    onTrySolution.notifyListeners(
        (callback) => callback(playerName, word, isSolutionRight, wordValue));
  }

  ///
  /// The game loop
  void _gameLoop() {
    if (isGameOver) return _processGameOver();
    if (!_isMainTimerRunning) {
      if (Managers.instance.configuration.autoplay) {
        _autoplayTimeRemaining -= const Duration(seconds: 1);
        if (_autoplayTimeRemaining.inSeconds <= 0) _isMainTimerRunning = true;
      }
      return;
    }

    _tickClock();
  }

  ///
  /// Get a random word from the list (capitalized)
  void _generateProblem() {
    final word = _dictionary[_random.nextInt(_dictionary.length)];

    // One letter will not be on the grid. For internal reasons of LetterDisplayer, we must flag it as "revealed"
    final mysteryLetterIndex = _random.nextInt(word.length);

    _problem = SerializableLetterProblem(
      letters: word.split(''),
      scrambleIndices: List.generate(word.length, (index) => index),
      uselessLetterStatuses: List.generate(
          word.length,
          (i) => i == mysteryLetterIndex
              ? LetterStatus.revealed
              : LetterStatus.normal),
      hiddenLetterStatuses:
          List.generate(word.length, (_) => LetterStatus.hidden),
    );
  }

  void _processGameOver() {
    _isMainTimerRunning = false;
    _timer?.cancel();
    _timer = null;
    _forceEndOfGame = false;

    onGameEnded.notifyListeners((callback) => callback(hasWon));
  }

  ///
  /// Tick the clock by one second
  void _tickClock() {
    //_timeRemaining -= const Duration(seconds: 1);
    onClockTicked.notifyListeners((callback) => callback(_timeRemaining));
  }
}
