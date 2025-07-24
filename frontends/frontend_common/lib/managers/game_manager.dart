import 'dart:async';

import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/serializable_blueberry_war_game_state.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/helpers.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/treasure_hunt/models/serializable_treasure_hunt_game_state.dart';
import 'package:frontend_common/managers/twitch_manager.dart';
import 'package:logging/logging.dart';
import 'package:vector_math/vector_math.dart';

final _logger = Logger('GameManager');

class GameManager {
  ///
  /// Prepare the singleton
  static final _instance = GameManager._();
  static GameManager get instance => _instance;
  GameManager._() {
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final dt = DateTime.now().difference(_lastTick);
      _lastTick = DateTime.now();
      _gameState.timeRemaining -= dt;

      onGameTicked.notifyListeners((callback) => callback());

      _tickMiniGame(dt: dt);
    });
  }

  ///
  /// Callback to know when a round has started or ended
  var _lastTick = DateTime.now();
  int get currentRound => _gameState.round;
  bool get isRoundRunning =>
      _gameState.status == WordsTrainGameStatus.roundStarted;
  bool get isRoundSuccess => _gameState.isRoundSuccess;

  Duration get timeRemaining => _gameState.timeRemaining;

  bool _hasPlayedAtLeastOneRound = false;
  bool get hasPlayedAtLeastOneRound => _hasPlayedAtLeastOneRound;

  bool get shouldShowExtension => _gameState.configuration.showExtension;

  ///
  /// Flag to indicate if the game has started
  final _gameState = SerializableGameState(
    status: WordsTrainGameStatus.uninitialized,
    round: 0,
    isRoundSuccess: false,
    timeRemaining: Duration.zero,
    newCooldowns: {},
    letterProblem: null,
    pardonRemaining: 0,
    pardonners: [],
    boostRemaining: 0,
    boostStillNeeded: 0,
    boosters: [],
    canAttemptTheBigHeist: false,
    isAttemptingTheBigHeist: false,
    configuration: SerializableConfiguration(showExtension: true),
    miniGameState: null,
  );

  ///
  /// A copy of the current game state. This is slow and should not be used apart
  /// from debugging purposes.
  SerializableGameState get gameStateCopy =>
      SerializableGameState.deserialize(_gameState.serialize());

  void updateGameState(SerializableGameState newGameState) {
    if (_gameState.status != newGameState.status) {
      _gameState.status = newGameState.status;
      if (_gameState.status == WordsTrainGameStatus.roundStarted ||
          _gameState.round > 0) {
        _hasPlayedAtLeastOneRound = true;
        _gameState.newCooldowns.clear();
        _gameState.pardonners.clear();
        onPardonnersChanged.notifyListeners((callback) => callback());
        _gameState.boosters.clear();
        onBoostAvailabilityChanged.notifyListeners((callback) => callback());
      }
      onGameStatusUpdated.notifyListeners((callback) => callback());
      _logger.info('Game status changed to ${_gameState.status}');
    }

    if (_gameState.round != newGameState.round) {
      _gameState.round = newGameState.round;
      _gameState.isRoundSuccess = newGameState.isRoundSuccess;
      _logger.info('Round changed to ${newGameState.round}');
    }

    if (_gameState.timeRemaining != newGameState.timeRemaining) {
      _gameState.timeRemaining = newGameState.timeRemaining;
      _logger.info('Time remaining changed to ${newGameState.timeRemaining}');
    }

    if (newGameState.newCooldowns.isNotEmpty) {
      _gameState.newCooldowns = newGameState.newCooldowns;
      _logger.info('New solution founders');
      onNewCooldowns.notifyListeners((callback) => callback());
    }

    if (_gameState.letterProblem != newGameState.letterProblem) {
      _gameState.letterProblem = newGameState.letterProblem;
      _logger.info('Letter problem changed');
      onLetterProblemChanged.notifyListeners((callback) => callback());
    }

    if (!listEquality(_gameState.pardonners, newGameState.pardonners)) {
      _gameState.pardonners = newGameState.pardonners;
      _logger.info('Pardonners changed to ${newGameState.pardonners}');
      onPardonnersChanged.notifyListeners((callback) => callback());
    }

    if (_gameState.boostRemaining != newGameState.boostRemaining) {
      _gameState.boostRemaining = newGameState.boostRemaining;
      _logger.info('Boost count changed to ${newGameState.boostRemaining}');
      onBoostAvailabilityChanged.notifyListeners((callback) => callback());
    }

    if (_gameState.boostStillNeeded != newGameState.boostStillNeeded) {
      _gameState.boostStillNeeded = newGameState.boostStillNeeded;
      _logger.info(
          'Boost still needed changed to ${newGameState.boostStillNeeded}');
    }

    if (!listEquality(_gameState.boosters, newGameState.boosters)) {
      _gameState.boosters = newGameState.boosters;
      _logger.info('Boosters changed to ${newGameState.boosters}');
    }

    if (_gameState.canAttemptTheBigHeist !=
        newGameState.canAttemptTheBigHeist) {
      _gameState.canAttemptTheBigHeist = newGameState.canAttemptTheBigHeist;
      onGameStatusUpdated.notifyListeners((callback) => callback());
      _logger.info(
          'Can attempt the big heist changed to ${newGameState.canAttemptTheBigHeist}');
    }

    if (_gameState.isAttemptingTheBigHeist !=
        newGameState.isAttemptingTheBigHeist) {
      _gameState.isAttemptingTheBigHeist = newGameState.isAttemptingTheBigHeist;
      onAttemptingTheBigHeist.notifyListeners((callback) => callback());
      _logger.info(
          'Is attempting the big heist changed to ${newGameState.isAttemptingTheBigHeist}');
    }

    if (_gameState.configuration.showExtension !=
        newGameState.configuration.showExtension) {
      _gameState.configuration.showExtension =
          newGameState.configuration.showExtension;
      onGameStatusUpdated.notifyListeners((callback) => callback());
    }

    if (_gameState.miniGameState != newGameState.miniGameState) {
      _gameState.miniGameState = newGameState.miniGameState;
      _logger.info('Mini game state changed');
      onMiniGameStateUpdated.notifyListeners((callback) => callback());
    }
  }

  ///
  /// Callback for each tick
  final onGameTicked = GenericListener<Function()>();

  ///
  /// Callback to know when the game has started
  WordsTrainGameStatus get status => _gameState.status;
  final onGameStatusUpdated = GenericListener<Function()>();
  void startGame() {
    _logger.info('Starting a new game');
    updateGameState(
        _gameState.copyWith(status: WordsTrainGameStatus.initializing));
  }

  ///
  /// Callback to know when the game has stopped
  void stopGame() {
    _logger.info('Stopping the current game');
    updateGameState(
        _gameState.copyWith(status: WordsTrainGameStatus.uninitialized));
  }

  ///
  /// Callback to know when a solution was found
  final onNewCooldowns = GenericListener<Function()>();
  Map<String, Duration> get newCooldowns =>
      Map.unmodifiable(_gameState.newCooldowns);

  ///
  /// Callback to know when the letters were changed
  final onLetterProblemChanged = GenericListener<Function()>();
  SerializableLetterProblem? get problem => _gameState.letterProblem;

  ///
  /// Stealer and pardonner management
  final onPardonnersChanged = GenericListener<Function()>();
  List<String> get pardonners => List.unmodifiable(_gameState.pardonners);

  final onPardonGranted = GenericListener<Function(bool)>();
  Future<bool> pardonStealer() async {
    final isSuccess = await TwitchManager.instance.pardonStealer();
    onPardonGranted.notifyListeners((callback) => callback(isSuccess));
    return isSuccess;
  }

  ///
  /// Boost availability
  int get boostCount => _gameState.boostRemaining;
  final onBoostAvailabilityChanged = GenericListener<Function()>();

  final onBoostGranted = GenericListener<Function(bool)>();
  Future<bool> boostTrain() async {
    final isSuccess = await TwitchManager.instance.boostTrain();
    onBoostGranted.notifyListeners((callback) => callback(isSuccess));
    return isSuccess;
  }

  List<String> get boosters => List.unmodifiable(_gameState.boosters);

  ///
  /// Boost availability
  final onChangeLaneGranted = GenericListener<Function(bool)>();
  Future<bool> changeLane() async {
    final isSuccess = await TwitchManager.instance.changeLane();
    onChangeLaneGranted.notifyListeners((callback) => callback(isSuccess));
    return isSuccess;
  }

  ///
  /// Big heist management
  bool get canAttemptTheBigHeist => _gameState.canAttemptTheBigHeist;
  bool get isAttemptingTheBigHeist => _gameState.isAttemptingTheBigHeist;
  final onAttemptingTheBigHeist = GenericListener<Function()>();

  ///
  /// Mini game is active
  bool get isMiniGameActive => _gameState.miniGameState != null;
  SerializableMiniGameState? get miniGameState => _gameState.miniGameState;
  final onMiniGameStateUpdated = GenericListener<Function()>();
  void updateMiniGameState(SerializableMiniGameState newMiniGameState) {
    _gameState.miniGameState = newMiniGameState;
    onMiniGameStateUpdated.notifyListeners((callback) => callback());
  }

  MiniGames? get currentMiniGameType => _gameState.miniGameState?.type;
  void _tickMiniGame({required Duration dt}) {
    if (_gameState.miniGameState == null) return;

    late final SerializableMiniGameState newGameState;
    switch (currentMiniGameType!) {
      case MiniGames.treasureHunt:
        {
          final thm =
              _gameState.miniGameState as SerializableTreasureHuntGameState;
          newGameState = thm.copyWith(timeRemaining: thm.timeRemaining - dt);
          break;
        }
      case MiniGames.blueberryWar:
        {
          final bwm =
              _gameState.miniGameState as SerializableBlueberryWarGameState;
          newGameState = bwm.copyWith(timeRemaining: bwm.timeRemaining - dt);

          BlueberryWarGameManagerHelpers.updateAllAgents(
              allAgents: bwm.allAgents, dt: dt, problem: bwm.problem);
          // Check for teleportations
          for (final agent in bwm.allAgents) {
            if (agent is! BlueberryAgent) continue;
            // TODO: Fix the teleportation detection on frontend
            // TODO: Fix state corruption when hitting the red target
            // If we detect a velocity of zero and the position is
            if (agent.velocity == Vector2.zero()) {
              agent.onTeleport.notifyListeners(
                  (callback) => callback(agent.position, agent.position));
            }
          }
          break;
        }
    }
    updateMiniGameState(newGameState);
  }
}
