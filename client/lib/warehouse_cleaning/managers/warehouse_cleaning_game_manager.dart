import 'dart:async';
import 'dart:math';

import 'package:common/generic/managers/dictionary_manager.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/valuable_letter.dart';
import 'package:common/warehouse_cleaning/models/agent.dart';
import 'package:common/warehouse_cleaning/models/avatar_agent.dart';
import 'package:common/warehouse_cleaning/models/box_agent.dart';
import 'package:common/warehouse_cleaning/models/letter_agent.dart';
import 'package:common/warehouse_cleaning/models/serializable_warehouse_cleaning_game_state.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_game_manager_helpers.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';
import 'package:diacritic/diacritic.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/managers/mini_games_manager.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

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
  List<String> get problemLetters =>
      List.from(problem.letters, growable: false);

  ///
  /// Number of tries remaining
  int _triesRemaining = 0;
  int get triesRemaining => _triesRemaining;

  ///
  /// Avatar position
  Tile? tileFromPosition(vector_math.Vector2 position) => _grid?.tileAt(
      row: (position.y / WarehouseCleaningConfig.tileSize).round(),
      col: (position.x / WarehouseCleaningConfig.tileSize).round());

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
  // TODO Reinstate instructions with the new game
  // 'Le hangard oublié de cette station recèle de trésors! Partez à l\'aventure '
  // 'avec vos collègues pour découvrir les lettres cachées.\n\n'
  // 'Utilisez l\'extension pour déplacer l\'avatar de votre choix. '
  // 'Mais attention, chaque mouvement vous coûtera un essai!\n\n';

  ///
  /// List of agents in the game (avatars and boxes)
  final allAgents = <Agent>[];
  List<AvatarAgent> get avatars =>
      allAgents.whereType<AvatarAgent>().toList(growable: false);
  List<BoxAgent> get boxes =>
      allAgents.whereType<BoxAgent>().toList(growable: false);
  List<LetterAgent> get letters =>
      allAgents.whereType<LetterAgent>().toList(growable: false);

  @override
  Future<void> initialize() async {
    _generateProblem();

    _grid = WarehouseCleaningGrid.random(
        rowCount: WarehouseCleaningConfig.rowCount,
        columnCount: WarehouseCleaningConfig.columnCount,
        problem: _problem!,
        startingRow: WarehouseCleaningConfig.startingRow,
        startingCol: WarehouseCleaningConfig.startingCol);

    // Populate the agents list with the avatar
    for (int i = 0; i < WarehouseCleaningConfig.initialAvatarCount; i++) {
      allAgents.add(AvatarAgent(
        id: i,
        position: vector_math.Vector2(
          WarehouseCleaningConfig.startingCol.toDouble() *
              WarehouseCleaningConfig.tileSize,
          WarehouseCleaningConfig.startingRow.toDouble() *
              WarehouseCleaningConfig.tileSize,
        ),
        radius: WarehouseCleaningConfig.avatarRadius,
        maxVelocity: WarehouseCleaningConfig.avatarMaxVelocity,
        velocity: vector_math.Vector2.zero(),
        coefficientOfFriction:
            WarehouseCleaningConfig.avatarFrictionCoefficient,
      ));
    }

    // Populate the agents list with the boxes and letters
    int currentIndex = WarehouseCleaningConfig.initialAvatarCount;
    for (int index = 0; index < _grid!.cellCount; index++) {
      final tile = _grid!.tileAt(index: index);
      if (tile == null) {
        continue;
      } else if (tile.isLetter) {
        allAgents.add(LetterAgent(
          id: currentIndex,
          value: tile.letter!,
          position: vector_math.Vector2(
            tile.col.toDouble() * WarehouseCleaningConfig.tileSize,
            tile.row.toDouble() * WarehouseCleaningConfig.tileSize,
          ),
          radius: WarehouseCleaningConfig.boxRadius,
        ));
      } else if (tile.isBox) {
        allAgents.add(BoxAgent(
          id: currentIndex,
          position: vector_math.Vector2(
            tile.col.toDouble() * WarehouseCleaningConfig.tileSize,
            tile.row.toDouble() * WarehouseCleaningConfig.tileSize,
          ),
          radius: WarehouseCleaningConfig.boxRadius,
        ));
      }
      currentIndex++;
    }

    // Perform an initial reveal of the fog of war around the avatar starting position
    final avatarTile = tileFromPosition(avatars.first.position);
    avatarTile == null ? null : _grid!.revealAt(index: avatarTile.index);

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

  void slingShoot(AvatarAgent avatar, vector_math.Vector2 newVelocity) {
    if (avatar.canBeSlingShot) {
      _logger.fine(
          'Sling shooting avatar ${avatar.id} with velocity $newVelocity');

      // Ensure the velocity is within a reasonable range
      double scale = 1.0;
      if (newVelocity.length2 > (avatar.maxVelocity * avatar.maxVelocity)) {
        scale = avatar.maxVelocity / newVelocity.length;
      }

      avatar.velocity = newVelocity * scale;

      // Remove one try for sling shooting
      _triesRemaining--;

      onAvatarMoved.notifyListeners((callback) => callback());
    } else {
      _logger
          .warning('Avatar ${avatar.id} cannot be slingshot, ignoring request');
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

  void _collectLetter(LetterAgent letter) {
    final tile = tileFromPosition(letter.position);
    if (tile == null) return;

    tile.reveal();
    letter.isCollected = true;
    problem.hiddenLetterStatuses[tile.letterIndex!] = LetterStatus.normal;

    onLetterFound.notifyListeners((callback) => callback(tile));
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

    // Update the position of the avatar
    WarehouseCleaningGameManagerHelpers.updateAvatarAgents(
        dt: Managers.instance.tickerManager.deltaTime,
        avatars: avatars,
        boxes: boxes,
        letters: letters,
        onLetterCollected: _collectLetter);

    // Revel tiles around the avatar
    for (final avatar in avatars) {
      final tile = tileFromPosition(avatar.position);
      if (tile != null) {
        _grid!.revealAt(index: tile.index);
      }
      onAvatarMoved.notifyListeners((callback) => callback());
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
