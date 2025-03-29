import 'dart:async';
import 'dart:math';

import 'package:common/managers/dictionary_manager.dart';
import 'package:common/models/exceptions.dart';
import 'package:common/models/generic_listener.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/managers/mini_games_manager.dart';
import 'package:train_de_mots/treasure_hunt/models/enums.dart';
import 'package:train_de_mots/treasure_hunt/models/game_tile.dart';
import 'package:train_de_mots/treasure_hunt/models/tile.dart';

final _logger = Logger('TreasureHuntGameManager');

// TODO: Add sound effects
// TODO: Add frontend
// TODO: Add backend

///
/// Easy accessors translating index into row/col pair or row/col pair into
/// index
int toGridIndex(GameTile tile, int nbCols) => tile.row * nbCols + tile.col;
GameTile toGridTile(int index, int nbCols) =>
    GameTile(index < 0 ? -1 : index ~/ nbCols, index < 0 ? -1 : index % nbCols);

class TreasureHuntGameManager implements MiniGameManager {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  TreasureHuntGameManager() {
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

    _isInitialized = true;
    _logger.config('Ready');
  }

  final _random = Random();

  ///
  /// Time remaining
  bool _isReady = false;
  @override
  bool get isReady => _isReady;
  bool _isTimerRunning = false;
  Timer? _timer;
  final _startingTimeRemaining = const Duration(seconds: 30);
  late Duration _timeRemaining = _startingTimeRemaining;
  @override
  Duration get timeRemaining => _timeRemaining;

  ///
  /// Current problem
  final _dictionary = DictionaryManager.wordsWithAtLeast(6).toList();
  SimplifiedLetterProblem? _problem;
  SimplifiedLetterProblem get problem =>
      _problem == null ? throw "This should not happen" : _problem!;

  ///
  /// Number of tries remaining
  final _startingTriesRemaining = 1;
  late int _triesRemaining = _startingTriesRemaining;
  int get triesRemaining => _triesRemaining;

  ///
  /// Rewards when a treasure or a letter are found
  final Duration _rewardInTime = const Duration(seconds: 5);
  final int _rewardInTrials = 1;

  // Listeners
  @override
  final onGameIsReady = GenericListener<Function()>();
  final onGameStarted = GenericListener<Function()>();
  final onClockTicked = GenericListener<Function(Duration)>();
  final onTrySolution =
      GenericListener<Function(String sender, String word, bool isSuccess)>();
  final onTileRevealed = GenericListener<Function()>();
  final onRewardFound = GenericListener<Function(Tile)>();
  @override
  final onGameEnded = GenericListener<Function(bool)>();

  // Size of the grid
  final int nbRows = 20;
  final int nbCols = 10;
  final int rewardsCount = 40;

  // The actual grid
  List<Tile> _grid = [];
  Map<int, int> _letterGrid = {}; // Grid index : Word letter index

  void trySolution(String sender, String message) {
    if (!_isTimerRunning) return;

    // Transform the message so it is only the first word all in uppercase
    final words = message.split(' ');
    if (words.isEmpty || words.length > 1) return;
    final word = words.first.toUpperCase();

    if (word == problem.letters.join()) {
      for (int i = 0; i < _problem!.uselessLetterStatuses.length; i++) {
        _problem!.uselessLetterStatuses[i] = LetterStatus.normal;
        _problem!.hiddenLetterStatuses[i] = LetterStatus.normal;
      }

      onTrySolution.notifyListeners((callback) => callback(sender, word, true));

      // For each _letterGrid, reveal the letter
      for (final index in _letterGrid.keys) {
        revealTile(tileIndex: index);
        onRewardFound.notifyListeners((callback) => callback(_grid[index]));
      }
    } else {
      onTrySolution
          .notifyListeners((callback) => callback(sender, word, false));
    }
  }

  ///
  /// Get the number of letters that were found
  int get letterFoundCount => problem.hiddenLetterStatuses.fold(
      0, (prev, status) => prev + (status == LetterStatus.normal ? 1 : 0));

  ///
  /// If the game is over
  bool get hasWon => letterFoundCount == problem.letters.length;
  bool get hasLost => isGameOver && !hasWon;
  bool get isGameOver =>
      hasWon || _timeRemaining.inSeconds <= 0 || _triesRemaining <= 0;

  List<String> get letters => List.from(problem.letters, growable: false);

  ///
  /// Get the value of a tile of a specific [index].
  Tile getTile(int index) => _grid[index];

  ///
  /// Get the number of rewards that were found
  int get rewardsFoundCount => _grid.asMap().keys.fold(
      0,
      (prev, index) =>
          prev + (_grid[index].isRevealed && _grid[index].hasReward ? 1 : 0));

  ///
  /// Get the letter of a tile
  String? getLetter(int index) =>
      _grid[index].isRevealed ? problem.letters[getLetterIndex(index)] : null;

  ///
  /// Get the letter index associated with a Tile index
  int getLetterIndex(int tile) => _letterGrid[tile]!;

  ///
  /// Get all the letters that were found
  Iterable<bool> get getLettersFoundIndices =>
      _letterGrid.entries.map((entry) => _grid[entry.key].isRevealed);

  ///
  /// Reveal a letter in the problem
  bool _revealLetter(int index) {
    // Do not reveal the mystery letter
    if (problem.uselessLetterStatuses[index] == LetterStatus.revealed) {
      return false;
    }
    if (problem.hiddenLetterStatuses[index] != LetterStatus.hidden) {
      return false;
    }

    problem.hiddenLetterStatuses[index] = LetterStatus.normal;
    return true;
  }

  ///
  /// Main interface for a user to reveal a tile from the grid
  RevealResult revealTile({GameTile? tile, int? tileIndex}) {
    if (isGameOver) return RevealResult.gameOver;
    _isTimerRunning = true;

    if (tile == null && tileIndex == null) {
      throw 'You must provide either a tile or an index';
    } else if (tile != null && tileIndex != null) {
      throw 'You must provide either a tile or an index, not both';
    }

    if (tile != null) {
      tileIndex = toGridIndex(tile, nbCols);
    } else {
      tile = toGridTile(tileIndex!, nbCols);
    }

    // Safe guards
    // If tile not in the grid
    if (!_isInsideGrid(tile)) return RevealResult.outsideGrid;
    // If tile was already revealed
    if (_grid[tileIndex].isRevealed) return RevealResult.alreadyRevealed;

    // Change the values of the surrounding tiles if it is a reward
    switch (_grid[tileIndex].value) {
      case TileValue.letter:
      case TileValue.treasure:
        _adjustSurroundingHints(tile);
        _triesRemaining += _rewardInTrials;
        if (_grid[tileIndex].value == TileValue.letter) {
          if (_revealLetter(getLetterIndex(tileIndex))) {
            _timeRemaining += _rewardInTime;
          }
        }
        onRewardFound
            .notifyListeners((callback) => callback(_grid[tileIndex!]));
        break;
      default:
        _triesRemaining--;
    }

    // Start the recursive process of revealing all the required tiles
    _revealTileRecursive(tileIndex);
    onTileRevealed.notifyListeners((callback) => callback());

    // Check if the game is over
    if (isGameOver) {
      _proceedGameOver();
      return RevealResult.gameOver;
    } else {
      return _grid[tileIndex].hasReward ? RevealResult.hit : RevealResult.miss;
    }
  }

  ///
  /// Reveal a tile. If it is a zero, it is recursively called to all its
  /// neighbourhood so it automatically reveals all the surroundings
  void _revealTileRecursive(int idx, {List<bool>? isChecked}) {
    // For each zeros encountered, we must check around if it is another zero
    // so it can be reveal. We must make sure we don't recheck a previously
    // checked tile though so we don't go in an infinite loop of checking.
    isChecked ??= List.filled(nbRows * nbCols, false); // If first time

    // If it is already revealed, do nothing
    if (isChecked[idx]) return;
    isChecked[idx] = true;

    // Reveal the current tile
    _grid[idx].reveal();

    // If the current tile is not zero, stop revealing, otherwise reveal the tiles around
    if (_grid[idx].value != TileValue.zero) return;

    final currentTile = toGridTile(idx, nbCols);
    for (var j = -1; j < 2; j++) {
      for (var k = -1; k < 2; k++) {
        // Do not reveal itself
        if (j == 0 && k == 0) continue;

        // Do not try to reveal tile outside of the grid
        final newTile = GameTile(currentTile.row + j, currentTile.col + k);
        if (!_isInsideGrid(newTile)) continue;

        // If current tile is a reward, only reveal new zeros
        final newIndex = toGridIndex(newTile, nbCols);
        if (_grid[idx].hasReward && _grid[newIndex].value == TileValue.zero) {
          continue;
        }

        // Reveal the tile if it was not already revealed
        _revealTileRecursive(newIndex, isChecked: isChecked);
      }
    }
  }

  ///
  /// Get if a tile is inside or outside the current grid
  bool _isInsideGrid(GameTile tile) {
    // Do not check rows or column outside of the grid
    return (tile.row >= 0 &&
        tile.col >= 0 &&
        tile.row < nbRows &&
        tile.col < nbCols);
  }

  ///
  /// Get a random word from the list (capitalized)
  void _generateProblem() {
    final word = _dictionary[_random.nextInt(_dictionary.length)];

    // One letter will not be on the grid. For internal reasons of LetterDisplayer, we must flag it as "revealed"
    final mysteryLetterIndex = _random.nextInt(word.length);

    _problem = SimplifiedLetterProblem(
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

  @override
  Future<void> initialize() async {
    _generateGrid();
    _isTimerRunning = false;
    _timeRemaining = _startingTimeRemaining;
    _triesRemaining = _startingTriesRemaining;
    _isReady = true;
    onGameIsReady.notifyListeners((callback) => callback());
  }

  @override
  Future<void> start() async {
    _startGameLoop();
    onGameStarted.notifyListeners((callback) => callback());
  }

  ///
  /// Generate a new grid with randomly positionned rewards
  void _generateGrid() {
    _generateProblem();

    // Create an empty grid
    _grid = List.generate(
        nbRows * nbCols,
        (index) => Tile(
            index: index,
            value: TileValue.zero,
            isConcealed: true,
            isUseless: false));

    // Fetch a word to find
    _letterGrid = {};

    // Populate it with rewards
    for (var i = 0; i < rewardsCount; i++) {
      var rewardIndex = -1;
      do {
        rewardIndex = _random.nextInt(nbRows * nbCols);
        // Make sure it this tile does not already have a reward
      } while (_grid[rewardIndex].hasReward);

      if (_letterGrid.length < letters.length) {
        _letterGrid[rewardIndex] = _letterGrid.length;
        _grid[rewardIndex].addLetter(
            uselessStatus:
                _problem!.uselessLetterStatuses[_letterGrid.length - 1]);
      } else {
        _grid[rewardIndex].addTreasure();
      }
    }

    // Recalculate the value of each tile based on number of rewards around it
    for (var i = 0; i < nbRows * nbCols; i++) {
      // Do not recompute tile with a reward in it
      if (_grid[i].hasReward) continue;

      var rewardsCountAroundTile = 0;

      final currentTile = toGridTile(i, nbCols);
      // Check the previous row to next row
      for (var j = -1; j <= 1; j++) {
        // Check the previous col to next col
        for (var k = -1; k <= 1; k++) {
          // Do not check itself
          if (j == 0 && k == 0) continue;

          // Find the current checked tile
          final checkedTile =
              GameTile(currentTile.row + j, currentTile.col + k);
          if (!_isInsideGrid(checkedTile)) continue;

          // If there is a rewared, add it to the counter
          if (_grid[toGridIndex(checkedTile, nbCols)].hasReward) {
            rewardsCountAroundTile++;
          }
        }
      }

      // Store the number in the tile
      _grid[i].value = TileValue.values[rewardsCountAroundTile];
    }
  }

  ///
  /// When a reward is found, lower all the surronding numbers
  void _adjustSurroundingHints(GameTile tile) {
    for (var j = -1; j <= 1; j++) {
      // Check the previous col to next col
      for (var k = -1; k <= 1; k++) {
        // Do not check itself
        if (j == 0 && k == 0) continue;

        final nextTile = GameTile(tile.row + j, tile.col + k);
        if (!_isInsideGrid(nextTile)) continue;
        final index = toGridIndex(nextTile, nbCols);

        // If this is not a reward, reduce that tile by one
        _grid[index].decrement();
      }
    }
  }

  ///
  /// Start the game loop
  Future<void> _startGameLoop() async {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _gameLoop();
    });
  }

  void _revealSolution() {
    // Reveal all the tiles in the grid
    for (final index in _letterGrid.keys) {
      final tile = _grid[index];
      tile.reveal();
      onRewardFound.notifyListeners((callback) => callback(tile));
    }

    // Reveal all the letters in the problem
    for (int i = 0; i < problem.letters.length; i++) {
      if (problem.hiddenLetterStatuses[i] == LetterStatus.hidden) {
        problem.hiddenLetterStatuses[i] = LetterStatus.revealed;
      }
      if (problem.uselessLetterStatuses[i] == LetterStatus.hidden) {
        problem.uselessLetterStatuses[i] = LetterStatus.revealed;
      }
    }

    onTileRevealed.notifyListeners((callback) => callback());
  }

  ///
  /// The game loop
  void _gameLoop() {
    if (!_isTimerRunning) return;

    _tickClock();

    if (isGameOver) {
      _proceedGameOver();
      return;
    }
  }

  void _proceedGameOver() {
    _isTimerRunning = false;
    _timer?.cancel();
    _timer = null;

    _revealSolution();
    onGameEnded.notifyListeners((callback) => callback(hasWon));
  }

  ///
  /// Tick the clock by one second
  void _tickClock() {
    _timeRemaining -= const Duration(seconds: 1);
    onClockTicked.notifyListeners((callback) => callback(_timeRemaining));
  }
}
