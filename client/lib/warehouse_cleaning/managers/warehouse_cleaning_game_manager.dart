import 'dart:async';
import 'dart:math';

import 'package:common/generic/managers/dictionary_manager.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/valuable_letter.dart';
import 'package:common/warehouse_cleaning/models/agent.dart';
import 'package:common/warehouse_cleaning/models/avatar_agent.dart';
import 'package:common/warehouse_cleaning/models/box_agent.dart';
import 'package:common/warehouse_cleaning/models/letter_agent.dart';
import 'package:common/warehouse_cleaning/models/serializable_warehouse_cleaning_game_state.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_config.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';
import 'package:diacritic/diacritic.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/managers/mini_games_manager.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

final _logger = Logger('WarehouseCleaningGameManager');
final _random = Random();

enum Direction { up, down, left, right }

// TODO: Finalize the text on screen when winning or losing

///
/// Easy accessors translating index into row/col pair or row/col pair into
/// index

class WarehouseCleaningGameManager extends MiniGameManager {
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
  final onTrySolution = GenericListener<
      Function(
          {required String playerName,
          required String word,
          required bool isSolutionRight,
          required int pointsAwarded})>();
  final onLetterFound = GenericListener<Function(Tile)>();
  final onAvatarMoved = GenericListener<Function()>();

  WarehouseCleaningGrid? _grid;
  WarehouseCleaningGrid get grid => _grid!;

  ///
  /// Get the number of letters that were found
  int get letterFoundCount => problem.hiddenLetterStatuses.fold(
      0, (prev, status) => prev + (status == LetterStatus.normal ? 1 : 0));

  ///
  /// End game status
  @override
  bool get hasWon => letterFoundCount == problem.letters.length;

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
    final startingPosition = vector_math.Vector2(
      WarehouseCleaningConfig.startingCol.toDouble() *
          WarehouseCleaningConfig.tileSize,
      WarehouseCleaningConfig.startingRow.toDouble() *
          WarehouseCleaningConfig.tileSize,
    );
    final startingTile = tileFromPosition(startingPosition);
    if (startingTile == null) {
      throw "Starting tile should not be null";
    }

    allAgents.clear();
    for (int i = 0; i < WarehouseCleaningConfig.initialAvatarCount; i++) {
      allAgents.add(AvatarAgent(
        id: i,
        tileIndex: startingTile.index,
        position: startingPosition,
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
          tileIndex: tile.index,
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
          tileIndex: tile.index,
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

    _triesRemaining = 45;
    _playersPoints.clear();

    await super.initialize();
  }

  @override
  SerializableWarehouseCleaningGameState serializeMiniGame() {
    return SerializableWarehouseCleaningGameState(
      roundTimer: roundTimer,
      grid: _grid!,
      triesRemaining: _triesRemaining,
    );
  }

  @override
  Duration get initialRoundDuration =>
      const Duration(seconds: 45) +
      Managers.instance.train.previousRoundTimeRemaining;

  void trySolution(String playerName, String message) {
    if (roundStatus != ControllableTimerStatus.inProgress) return;

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
    if (roundStatus != ControllableTimerStatus.inProgress) return;

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
      if (tile == null) continue;
      tile.reveal();
      if (tile.isLetter) {
        onLetterFound.notifyListeners((callback) => callback(tile));
      }
    }
  }

  void _collectLetter(LetterAgent letter) {
    final tile = tileFromPosition(letter.position);
    if (tile == null || tile.isMysteryLetter) return;

    tile.reveal();
    letter.isCollected = true;
    problem.hiddenLetterStatuses[tile.letterIndex!] = LetterStatus.normal;

    onLetterFound.notifyListeners((callback) => callback(tile));
  }

  ///
  /// The game loop
  @override
  Future<void> onRoundClockTicked(
      Duration deltaTime, ControllableTimerStatus status) async {
    switch (status) {
      case ControllableTimerStatus.notInitialized:
        break;
      case ControllableTimerStatus.initialized:
        break;
      case ControllableTimerStatus.inProgress:
        await _processRound(deltaTime);
        break;
      case ControllableTimerStatus.paused:
        break;
      case ControllableTimerStatus.ended:
        break;
    }
  }

  @override
  void onRoundStatusChanged(ControllableTimerStatus newStatus) {
    super.onRoundStatusChanged(newStatus);

    if (newStatus == ControllableTimerStatus.ended) _processRoundIsEnding();
  }

  Future<void> _processRound(Duration deltaTime) async {
    // Update the position of the avatar
    _updateAllAvatarAgents(
        dt: deltaTime,
        avatars: avatars,
        boxes: boxes,
        letters: letters,
        onLetterCollected: _collectLetter);

    // Revel tiles around the avatar
    for (final avatar in avatars) {
      final previousTileIndex = avatar.tileIndex;
      final tileIndex = tileFromPosition(avatar.position)?.index ?? -1;
      if (tileIndex != previousTileIndex) {
        _grid!.revealAt(index: tileIndex);
        avatar.tileIndex = tileIndex;
        onAvatarMoved.notifyListeners((callback) => callback());
      }
    }
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

  Future<void> _processRoundIsEnding() async {
    _revealSolution();
  }

  ///
  /// Update all the agents in the list. This method should be called by the
  /// game loop.
  void _updateAllAvatarAgents({
    required Duration dt,
    required List<AvatarAgent> avatars,
    required List<BoxAgent> boxes,
    required List<LetterAgent> letters,
    required Function(LetterAgent letter) onLetterCollected,
  }) {
    for (int i = 0; i < avatars.length; i++) {
      // Move all agents
      final agent = avatars[i];
      agent.update(
          dt: dt,
          colliders: [...boxes, ...letters],
          onLetterCollision: onLetterCollected);
    }
  }
}
