import 'dart:async';
import 'dart:math';

import 'package:common/generic/managers/dictionary_manager.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/valuable_letter.dart';
import 'package:common/warehouse_cleaning/models/serializable_warehouse_cleaning_game_state.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/managers/mini_games_manager.dart';

final _logger = Logger('WarehouseCleaningGameManager');
final _random = Random();

enum Direction { up, down, left, right }

// TODO: Fix bug with mystery letter (does not fit the red tile and can currently be picked up)
// TODO: Finalize the text on screen when winning or losing

///
/// Easy accessors translating index into row/col pair or row/col pair into
/// index

class WarehouseCleaningGameManager implements MiniGameManager {
  WarehouseCleaningGameManager() {
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
    HardwareKeyboard.instance.addHandler((event) => _onKeyPressed(event));
  }

  bool _onKeyPressed(KeyEvent event) {
    // TODO Remove the key press
    if (event is! KeyDownEvent) return false;

    // Catch up, down, left and right arrow keys to move the avatar
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveAvatar(Direction.up);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveAvatar(Direction.down);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveAvatar(Direction.left);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveAvatar(Direction.right);
    }
    return false;
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
  Duration _timeRemaining = Duration.zero;
  @override
  Duration get timeRemaining => _timeRemaining;
  bool _forceEndOfGame = false;

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

  ///
  /// Avatar position
  Tile? _avatarTile;
  Tile get avatarTile => _avatarTile!;

  // Listeners
  @override
  final onGameIsReady = GenericListener<Function()>();
  final onGameStarted = GenericListener<Function()>();
  @override
  final onGameUpdated = GenericListener<Function()>();
  final onTrySolution = GenericListener<
      Function(
          {required String playerName,
          required String word,
          required bool isSolutionRight,
          required int pointsAwarded})>();
  final onLetterFound = GenericListener<Function(Tile)>();
  @override
  final onGameEnded = GenericListener<Function({required bool hasWon})>();
  final onAvatarMoved = GenericListener<Function()>();

  // Size of the grid
  final int _rowCount = 31;
  final int _columnCount = 15;
  WarehouseCleaningGrid? _grid;
  WarehouseCleaningGrid get grid => _grid!;

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
  // 'Le hangard oublié de cette station recèle de trésors! Partez à l\'aventure '
  // 'avec vos collègues pour découvrir les lettres cachées.\n\n'
  // 'Utilisez l\'extension pour déplacer l\'avatar de votre choix. '
  // 'Mais attention, chaque mouvement vous coûtera un essai!\n\n';

  @override
  Future<void> initialize() async {
    _generateProblem();

    final startingRow = _rowCount ~/ 2;
    final startingCol = _columnCount ~/ 2;
    _grid = WarehouseCleaningGrid.random(
        rowCount: _rowCount,
        columnCount: _columnCount,
        problem: _problem!,
        startingRow: startingRow,
        startingCol: startingCol);

    _avatarTile = _grid!.revealAt(row: startingRow, col: startingCol)!;

    _isMainTimerRunning = false;
    _timeRemaining = Duration(
      seconds:
          30 + Managers.instance.train.previousRoundTimeRemaining.inSeconds,
    );
    _triesRemaining = 220;
    _playersPoints.clear();
    _isReady = true;
    _forceEndOfGame = false;
    onGameIsReady.notifyListeners((callback) => callback());
  }

  @override
  SerializableWarehouseCleaningGameState serialize() {
    return SerializableWarehouseCleaningGameState(
      grid: _grid!,
      isTimerRunning: _isMainTimerRunning,
      timeRemaining: _timeRemaining,
      triesRemaining: _triesRemaining,
    );
  }

  @override
  Future<void> start() async {
    Managers.instance.tickerManager.onClockTicked.listen(_gameLoop);

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
    if (words.isEmpty || words.length > 1 || words.first[0] == '!') return;

    final word = removeDiacritics(words.first.toUpperCase());
    // Refuse any word that contains non-letter characters
    if (!RegExp(r'^[A-Z]+$').hasMatch(word)) return;

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
    onTrySolution.notifyListeners((callback) => callback(
        playerName: playerName,
        word: word,
        isSolutionRight: isSolutionRight,
        pointsAwarded: wordValue));
  }

  void _moveAvatar(Direction direction) {
    if (!_isMainTimerRunning) return;

    int newRow = avatarTile.row;
    int newCol = avatarTile.col;
    switch (direction) {
      case Direction.up:
        newRow--;
        break;
      case Direction.down:
        newRow++;
        break;
      case Direction.left:
        newCol--;
        break;
      case Direction.right:
        newCol++;
        break;
    }

    final tile = grid.tileAt(row: newRow, col: newCol);
    if (tile != null && tile.content != TileContent.box) {
      _grid!.revealAt(index: tile.index);
      _avatarTile = tile;

      if (tile.content == TileContent.letter && tile.isNotVisited) {
        problem.hiddenLetterStatuses[tile.letterIndex!] = LetterStatus.normal;
        onLetterFound.notifyListeners((callback) => callback(tile));
      } else {
        _triesRemaining--;
      }

      tile.markVisited();
      onAvatarMoved.notifyListeners((callback) => callback());
    }
  }

  void _revealSolution() {
    // Reveal all the letters in the problem
    for (int i = 0; i < problem.letters.length; i++) {
      if (problem.hiddenLetterStatuses[i] == LetterStatus.hidden) {
        problem.hiddenLetterStatuses[i] = LetterStatus.revealed;
      }
    }

    // Reveal all the tiles in the grid
    for (int i = 0; i < _grid!.cellCount; i++) {
      final tile = _grid!.tileAt(index: i);
      if (tile == null || !tile.isLetter) continue;
      tile.reveal();
      onLetterFound.notifyListeners((callback) => callback(tile));
    }
  }

  ///
  /// The game loop
  void _gameLoop() {
    if (isGameOver) return _processGameOver();
    if (!_isMainTimerRunning) {
      if (Managers.instance.train.gameStatus ==
          WordsTrainGameStatus.miniGameStarted) {
        _isMainTimerRunning = true;
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
    if (!_isMainTimerRunning) return;

    _isMainTimerRunning = false;
    _forceEndOfGame = false;

    _revealSolution();
    onGameEnded.notifyListeners((callback) => callback(hasWon: hasWon));
    Managers.instance.tickerManager.onClockTicked.cancel(_gameLoop);
  }

  ///
  /// Tick the clock by one second
  void _tickClock() {
    _timeRemaining -= Managers.instance.tickerManager.deltaTime;
  }
}
