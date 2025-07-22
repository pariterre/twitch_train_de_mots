import 'dart:async';
import 'dart:math';

import 'package:common/blueberry_war/models/agent.dart';
import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/blueberry_war/models/player_agent.dart';
import 'package:common/blueberry_war/models/serializable_blueberry_war_game_state.dart';
import 'package:common/generic/managers/dictionary_manager.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/managers/mini_games_manager.dart';
import 'package:vector_math/vector_math.dart';

final _logger = Logger('BlueberryWarGameManager');
final _random = Random();

final _dictionary = DictionaryManager.wordsWithAtLeast(10).toList();

///
/// Easy accessors translating index into row/col pair or row/col pair into
/// index

class BlueberryWarGameManager implements MiniGameManager {
  ///
  /// Duration of each game tick (16ms for 60 FPS)
  final Duration _tickDuration = const Duration(milliseconds: 16);
  DateTime _lastTick = DateTime.now();
  Vector2 fieldSize = Vector2(1920, 1080);

  ///
  /// Whether the game manager is initialized
  bool _forceEndOfGame = false;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool _isGameOver = false;
  bool get isGameOver => _isGameOver;
  bool? _hasWon = false;
  bool get hasWon => _hasWon!;

  ///
  /// Time related stuff for the game
  bool _isReady = false;
  @override
  bool get isReady => _isReady;

  Timer? _timer;
  DateTime? _startTime;
  DateTime get startTime => _startTime ?? DateTime.now();
  bool get gameStarted => _startTime != null;
  DateTime? _finalTime;
  DateTime? get finalTime => _finalTime;
  Duration _roundDuration = const Duration(seconds: 30);
  @override
  Duration get timeRemaining =>
      _roundDuration -
      (_finalTime ?? DateTime.now()).difference(_startTime ?? DateTime.now());

  ///
  /// Current problem for the game
  SerializableLetterProblem? _problem;
  SerializableLetterProblem get problem => _problem!;

  ///
  /// List of agents in the game (players and letters)
  final allAgents = <Agent>[];
  List<LetterAgent> get letters =>
      allAgents.whereType<LetterAgent>().toList(growable: false);
  final initialPlayerCount = 10;
  List<PlayerAgent> get players =>
      allAgents.whereType<PlayerAgent>().toList(growable: false);

  // Listeners
  @override
  final onGameIsReady = GenericListener<Function()>();
  final onClockTicked = GenericListener<Function()>();
  @override
  final onGameUpdated = GenericListener<Function()>();
  final onLetterHitByPlayer =
      GenericListener<Function(int letterIndex, bool isDestroyed)>();
  final onLetterHitByLetter = GenericListener<
      Function(int firstIndex, int secondIndex, bool firstIsBoss,
          bool secondIsBoss)>();
  final onBlueberryDestroyed = GenericListener<Function(int blueberryIndex)>();
  @override
  final onGameEnded = GenericListener<Function(bool)>();
  final onTrySolution =
      GenericListener<Function(String sender, String word, bool isSuccess)>();

  ///
  /// Constructor
  BlueberryWarGameManager() {
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

  @override
  // TODO: implement instructions
  String? get instructions => null;

  ///
  /// Initialize the game manager
  @override
  Future<void> initialize() async {
    _logger.fine('BlueberryWarGameManager initializing');
    _isGameOver = false;
    _generateProblem();

    // Populate letters with random agents
    allAgents.clear();
    for (int i = 0; i < _problem!.letters.length; i++) {
      final isBoss =
          _problem!.uselessLetterStatuses[i] == LetterStatus.revealed;
      allAgents.add(
        LetterAgent(
          id: i,
          isBoss: isBoss,
          problemIndex: i,
          letter: _problem!.letters[i],
          position: Vector2(fieldSize.x * 2 / 3, fieldSize.y * 2 / 5),
          velocity: isBoss
              ? Vector2.zero()
              : Vector2(
                  _random.nextDouble() * 1500 - 750,
                  _random.nextDouble() * 1500 - 750,
                ),
          maxVelocity: 6000.0,
          radius: Vector2(40.0, 50.0),
          mass: 1.0,
          coefficientOfFriction: (isBoss ? -0.2 : 0.5),
        ),
      );
    }

    // Populate players with random agents
    for (int i = 0; i < initialPlayerCount; i++) {
      allAgents.add(
        PlayerAgent(
          id: i + 1000,
          position: PlayerAgent.generateRandomStartingPosition(
            playerFieldSize:
                BlueberryWarGameManagerHelpers.playerFieldSize(fieldSize),
            playerRadius: BlueberryWarGameManagerHelpers.playerRadius,
          ),
          velocity: Vector2.zero(),
          maxVelocity: 2000.0,
          radius: BlueberryWarGameManagerHelpers.playerRadius,
          mass: 3.0,
          coefficientOfFriction: 0.8,
        ),
      );
    }

    _roundDuration = Duration(
      seconds:
          max(30, Managers.instance.train.previousRoundTimeRemaining.inSeconds),
    );

    // Notify listeners that the game is ready
    _isInitialized = true;
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    _finalTime = null;
    _isGameOver = false;
    _hasWon = null;
    _lastTick = DateTime.now();
    _isReady = true;
    onGameIsReady.notifyListeners((callback) => callback());
  }

  @override
  Future<void> start() async {
    _timer?.cancel();
    _timer = Timer.periodic(_tickDuration, (timer) => _gameLoop());
  }

  @override
  Future<void> end() async {
    _forceEndOfGame = true;
  }

  void slingShoot({required PlayerAgent player, required Vector2 newVelocity}) {
    if (player.canBeSlingShot) {
      _logger.info(
          'Sling shooting player ${player.id} with velocity $newVelocity');

      // Ensure the velocity is within a reasonable range
      double scale = 1.0;
      if (newVelocity.length2 > (player.maxVelocity * player.maxVelocity)) {
        scale = player.maxVelocity / newVelocity.length;
      }

      player.velocity = newVelocity * scale;
      onGameUpdated.notifyListeners((callback) => callback());
    } else {
      _logger
          .warning('Player ${player.id} cannot be slingshot, ignoring request');
    }
  }

  void trySolution(String sender, String message) {
    if (!gameStarted || _isGameOver) return;

    // Transform the message so it is only the first word all in uppercase
    final words = message.split(' ');
    if (words.isEmpty || words.length > 1) return;
    final word = words.first.toUpperCase();

    final isSolutionRight = word == problem.letters.join();
    if (isSolutionRight) {
      for (int i = 0; i < _problem!.uselessLetterStatuses.length; i++) {
        _problem!.hiddenLetterStatuses[i] = LetterStatus.normal;
      }
    }
    onTrySolution
        .notifyListeners((callback) => callback(sender, word, isSolutionRight));
  }

  ///
  /// Get a random word from the list (capitalized)
  void _generateProblem() {
    final word = _dictionary[_random.nextInt(_dictionary.length)];

    // One letter will not be on the grid. For internal reasons of LetterDisplayer,
    // we must flag it as "revealed"
    final isBoss = _random.nextInt(word.length);

    _problem = SerializableLetterProblem(
      letters: word.split(''),
      scrambleIndices: List.generate(word.length, (index) => index),
      uselessLetterStatuses: List.generate(
        word.length,
        (i) => i == isBoss ? LetterStatus.revealed : LetterStatus.normal,
      ),
      hiddenLetterStatuses: List.generate(
        word.length,
        (_) => LetterStatus.hidden,
      ),
    );
  }

  @override
  SerializableBlueberryWarGameState serialize() =>
      SerializableBlueberryWarGameState(
        isStarted: gameStarted,
        isOver: _isGameOver,
        isWon: _hasWon ?? false,
        timeRemaining: timeRemaining,
        fieldSize: fieldSize,
        allAgents: allAgents,
        problem: _problem!,
      );

  ///
  /// The game loop
  void _gameLoop() {
    if (!_isInitialized) {
      _logger.warning('Game loop called before initialization');
      return;
    }

    // Check if the game is over
    _manageStartOfGame();
    _manageForGameOver();
    bool shouldCallUpdate = false;
    BlueberryWarGameManagerHelpers.updateAllAgents(
      dt: DateTime.now().difference(_lastTick),
      fieldSize: fieldSize,
      allAgents: allAgents,
      problem: _problem!,
      onBlueberryDestroyed: (player) {
        onBlueberryDestroyed.notifyListeners((callback) => callback(player.id));
        shouldCallUpdate = true;
      },
      onLetterHitByPlayer: (letter) {
        onLetterHitByPlayer.notifyListeners(
          (callback) => callback(letter.problemIndex, letter.isDestroyed),
        );
        shouldCallUpdate = true;
      },
      onLetterHitByLetter: (first, second) {
        onLetterHitByLetter.notifyListeners(
          (callback) => callback(first.problemIndex, second.problemIndex,
              first.isBoss, second.isBoss),
        );
      },
    );
    BlueberryWarGameManagerHelpers.checkForPlayersTeleportation(
      allAgents: allAgents,
      fieldSize: fieldSize,
      onPlayerTeleported: (player) => shouldCallUpdate = true,
    );
    if (shouldCallUpdate) {
      // Notify listeners that the game has been updated with more than just
      // movement and collisions
      onGameUpdated.notifyListeners((callback) => callback());
    }
    _tickClock();
  }

  void _manageStartOfGame() {
    if (_startTime != null) return;

    for (final agent in allAgents) {
      if (agent is! PlayerAgent) continue;
      if (agent.velocity.length2 != 0.0) {
        _logger.info('Blueberry war timer started');
        _startTime = DateTime.now();
        break;
      }
    }
  }

  void _manageForGameOver() {
    if (_isGameOver) {
      // Stop the timer if all the agents have stopped moving
      if (allAgents.every(
        (agent) =>
            agent.velocity.length2 <
                BlueberryWarGameManagerHelpers.velocityThreshold2 ||
            agent.isDestroyed,
      )) {
        _logger.info('Game over, stopping the timer');
        _timer?.cancel();
      }
      return;
    }

    if (_forceEndOfGame) {
      _logger.info('Blueberry war game forced to end');
      _isGameOver = true;
      _hasWon = false;
    } else if (problem.hiddenLetterStatuses
        .every((status) => status != LetterStatus.hidden)) {
      _logger.info('All letters revealed in blueberry war, you win!');
      _isGameOver = true;
      _hasWon = true;
    } else if (timeRemaining.isNegative) {
      _logger.info('Blueberry war game over due to time running out');
      _isGameOver = true;
      _hasWon = false;
    } else if (players.every((player) => player.isDestroyed)) {
      _logger.info('All players destroyed in blueberry war, you lose!');
      _isGameOver = true;
      _hasWon = false;
    }

    if (!_isGameOver) return;

    // Make all the agents quickly slowing down
    for (final agent in allAgents) {
      agent.coefficientOfFriction = 0.9;
    }

    // Reveal the problem
    for (int i = 0; i < _problem!.hiddenLetterStatuses.length; i++) {
      _problem!.hiddenLetterStatuses[i] = LetterStatus.revealed;
    }

    _finalTime = DateTime.now();
    onGameEnded.notifyListeners((callback) => callback(_hasWon!));
  }

  ///
  /// Tick the clock by one second
  void _tickClock() {
    _logger.finer('Game loop ticked at ${DateTime.now()}');
    _lastTick = DateTime.now();
    onClockTicked.notifyListeners((callback) => callback());
  }
}
