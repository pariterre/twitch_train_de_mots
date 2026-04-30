import 'dart:async';

import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/serializable_blueberry_war_game_state.dart';
import 'package:common/generic/managers/global_ticker_manager.dart';
import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/generic/models/success_level.dart';
import 'package:frontend_common/managers/twitch_manager.dart';
import 'package:logging/logging.dart';

final _logger = Logger('GameManager');

class GameManager {
  ///
  /// Prepare the singleton
  static final _instance = GameManager._();
  static GameManager get instance => _instance;
  GameManager._();

  bool _isInitialized = false;
  late final GlobalTickerManager _tickerManager;
  GlobalTickerManager get tickerManager {
    if (!_isInitialized) {
      throw ManagerNotInitializedException(
          'GameManager is not initialized. Please call GameManager.initialize() before using it.');
    }
    return _tickerManager;
  }

  Future<void> initialize({required GlobalTickerManager tickerManager}) async {
    _tickerManager = tickerManager;
    _isInitialized = true;

    _tickerManager.onClockTicked.listen(_tickGame);
  }

  ///
  /// Callback to know when a round has started or ended
  int get currentRound => _gameState.roundCount;
  bool get isRoundRunning =>
      _gameState.gameStatus == WordsTrainGameStatus.roundStarted;
  SuccessLevel get successLevel => _gameState.successLevel;

  Duration get timeRemaining =>
      _gameState.roundTimer.endsAt?.difference(DateTime.now()) ??
      Duration(seconds: -1);

  bool get hasPlayedAtLeastOneRound => _gameState.hasPlayedAtLeastOnce;
  bool get shouldShowExtension => _gameState.configuration.showExtension;

  ///
  /// Flag to indicate if the game has started
  SerializableGameState _gameState = SerializableGameState(
    hasPlayedAtLeastOnce: false,
    roundCount: 0,
    gameStatus: WordsTrainGameStatus.uninitialized,
    isRoundAMiniGame: false,
    successLevel: SuccessLevel.failed,
    roundSuccesses: [],
    roundTimer: SerializableControllableTimer(
        isInitialized: false, startedAt: null, endsAt: null, pausedAt: null),
    letterProblem: SerializableLetterProblem.empty(),
    players: {},
    pardonRemaining: 0,
    pardonners: [],
    boostRemaining: 0,
    boostStillNeeded: 0,
    boosters: [],
    canChangeLane: false,
    canRequestFireworks: false,
    canRequestTheBigHeist: false,
    isAttemptingTheBigHeist: false,
    canRequestFixTracksMiniGame: false,
    isAttemptingFixTracksMiniGame: false,
    configuration: SerializableConfiguration(showExtension: true),
    miniGameState: null,
  );

  ///
  /// A copy of the current game state. This is slow and should not be used apart
  /// from debugging purposes.
  SerializableGameState get gameStateCopy =>
      SerializableGameState.deserialize(_gameState.serialize());

  void updateGameState(SerializableGameState newGameState) {
    _gameState = newGameState;
    // if (_gameState.gameStatus != newGameState.gameStatus) {
    //   _gameState.gameStatus = newGameState.gameStatus;
    //   if (_gameState.gameStatus == WordsTrainGameStatus.roundStarted ||
    //       _gameState.roundCount > 0) {
    //     _hasPlayedAtLeastOneRound = true;
    //     _gameState.players.clear();
    //     _gameState.pardonners.clear();
    //     onPardonnersChanged.notifyListeners((callback) => callback());
    //     _gameState.boosters.clear();
    //     onBoostAvailabilityChanged.notifyListeners((callback) => callback());
    //   }
    //   onGameStatusUpdated.notifyListeners((callback) => callback());
    //   _logger.info('Game status changed to ${_gameState.gameStatus}');
    // }

    // if (_gameState.roundCount != newGameState.roundCount ||
    //     _gameState.successLevel != newGameState.successLevel) {
    //   _gameState.roundCount = newGameState.roundCount;
    //   _gameState.successLevel = newGameState.successLevel;
    //   onRoundUpdated.notifyListeners((callback) => callback());
    //   _logger.info('Round changed to ${newGameState.roundCount}');
    // }

    // if (_gameState.roundTimer != newGameState.roundTimer) {
    //   _gameState.roundTimer = newGameState.roundTimer;
    //   _logger.info('Round timer changed to ${newGameState.roundTimer}');
    // }

    // if (newGameState.players != _gameState.players) {
    //   _gameState.players = newGameState.players;
    //   _logger.info('New solution founders');
    //   onCooldownsUpdated.notifyListeners((callback) => callback());
    // }

    // if (_gameState.letterProblem != newGameState.letterProblem) {
    //   _gameState.letterProblem = newGameState.letterProblem;
    //   _logger.info('Letter problem changed');
    //   onLetterProblemChanged.notifyListeners((callback) => callback());
    // }

    // if (!listEquality(_gameState.pardonners, newGameState.pardonners)) {
    //   _gameState.pardonners = newGameState.pardonners;
    //   _logger.info('Pardonners changed to ${newGameState.pardonners}');
    //   onPardonnersChanged.notifyListeners((callback) => callback());
    // }

    // if (_gameState.boostRemaining != newGameState.boostRemaining) {
    //   _gameState.boostRemaining = newGameState.boostRemaining;
    //   _logger.info('Boost count changed to ${newGameState.boostRemaining}');
    //   onBoostAvailabilityChanged.notifyListeners((callback) => callback());
    // }

    // if (_gameState.boostStillNeeded != newGameState.boostStillNeeded) {
    //   _gameState.boostStillNeeded = newGameState.boostStillNeeded;
    //   _logger.info(
    //       'Boost still needed changed to ${newGameState.boostStillNeeded}');
    // }

    // if (!listEquality(_gameState.boosters, newGameState.boosters)) {
    //   _gameState.boosters = newGameState.boosters;
    //   _logger.info('Boosters changed to ${newGameState.boosters}');
    // }

    // if (_gameState.canRequestTheBigHeist !=
    //     newGameState.canRequestTheBigHeist) {
    //   _gameState.canRequestTheBigHeist = newGameState.canRequestTheBigHeist;
    //   onGameStatusUpdated.notifyListeners((callback) => callback());
    //   _logger.info(
    //       'Can request the big heist changed to ${newGameState.canRequestTheBigHeist}');
    // }

    // if (_gameState.isAttemptingTheBigHeist !=
    //     newGameState.isAttemptingTheBigHeist) {
    //   _gameState.isAttemptingTheBigHeist = newGameState.isAttemptingTheBigHeist;
    //   onAttemptingTheBigHeist.notifyListeners((callback) => callback());
    //   _logger.info(
    //       'Is attempting the big heist changed to ${newGameState.isAttemptingTheBigHeist}');
    // }

    // if (_gameState.canRequestFixTracksMiniGame !=
    //     newGameState.canRequestFixTracksMiniGame) {
    //   _gameState.canRequestFixTracksMiniGame =
    //       newGameState.canRequestFixTracksMiniGame;
    //   onGameStatusUpdated.notifyListeners((callback) => callback());
    //   _logger.info(
    //       'Can request the end of railway mini game changed to ${newGameState.canRequestFixTracksMiniGame}');
    // }

    // if (_gameState.isAttemptingFixTracksMiniGame !=
    //     newGameState.isAttemptingFixTracksMiniGame) {
    //   _gameState.isAttemptingFixTracksMiniGame =
    //       newGameState.isAttemptingFixTracksMiniGame;
    //   onFixingTheTrack.notifyListeners((callback) => callback());
    //   _logger.info(
    //       'Is attempting the end of railway mini game changed to ${newGameState.isAttemptingFixTracksMiniGame}');
    // }

    // if (_gameState.configuration.showExtension !=
    //     newGameState.configuration.showExtension) {
    //   _gameState.configuration.showExtension =
    //       newGameState.configuration.showExtension;
    //   onGameStatusUpdated.notifyListeners((callback) => callback());
    // }

    // if (_gameState.miniGameState != newGameState.miniGameState) {
    //   if (_gameState.miniGameState is SerializableBlueberryWarGameState &&
    //       newGameState.miniGameState is SerializableBlueberryWarGameState) {
    //     // Keep the listeners of the blueberry agents
    //     for (final agent
    //         in (newGameState.miniGameState as SerializableBlueberryWarGameState)
    //             .allAgents) {
    //       if (agent is! BlueberryAgent) continue;
    //       final currentAgent =
    //           (_gameState.miniGameState as SerializableBlueberryWarGameState)
    //               .allAgents
    //               .firstWhere((a) => a.id == agent.id);
    //       agent.onTeleport.copyListenersFrom(currentAgent.onTeleport);
    //       agent.onDestroyed.copyListenersFrom(currentAgent.onDestroyed);
    //     }
    //   }
    //   _gameState.miniGameState = newGameState.miniGameState;
    //   _logger.info('Mini game state changed');
    //   onMiniGameStateUpdated.notifyListeners((callback) => callback());
    // }
  }

  ///
  /// Callback for each tick
  Future<void> _tickGame(Duration deltaTime) async {
    _tickMiniGame(deltaTime);
  }

  ///
  /// Callback to know when the game has started
  WordsTrainGameStatus get status => _gameState.gameStatus;
  bool get isRoundAMiniGame => _gameState.isRoundAMiniGame;
  final onGameStatusUpdated = GenericListener<Function()>();
  final onRoundUpdated = GenericListener<Function()>();
  void startGame() {
    _logger.info('Starting a new game');
    updateGameState(
        _gameState.copyWith(gameStatus: WordsTrainGameStatus.initializing));
  }

  ///
  /// Callback to know when the game has stopped
  void stopGame() {
    _logger.info('Stopping the current game');
    updateGameState(
        _gameState.copyWith(gameStatus: WordsTrainGameStatus.uninitialized));
  }

  ///
  /// Callback to know when a solution was found
  final onCooldownsUpdated = GenericListener<Function()>();
  Map<String, DateTime> get cooldowns => Map.unmodifiable(_gameState.players);

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
  final onChangeLaneGranted = GenericListener<Function()>();
  Future<bool> requestChangeLane() async {
    final isSuccess = await TwitchManager.instance.changeLane();
    return isSuccess;
  }

  Future<void> changeLaneGranted() async {
    onChangeLaneGranted.notifyListeners((callback) => callback());
  }

  ///
  /// Big heist management
  bool get canRequestTheBigHeist => _gameState.canRequestTheBigHeist;
  bool get isAttemptingTheBigHeist => _gameState.isAttemptingTheBigHeist;
  final onAttemptingTheBigHeist = GenericListener<Function()>();

  ///
  /// Track fix management
  bool get canRequestFixTracksMiniGame =>
      _gameState.canRequestFixTracksMiniGame;
  bool get isAttemptingFixTracksMiniGame =>
      _gameState.isAttemptingFixTracksMiniGame;
  final onFixingTheTrack = GenericListener<Function()>();

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
  void _tickMiniGame(Duration deltaTime) {
    if (_gameState.miniGameState == null) return;

    final dt = deltaTime;

    switch (currentMiniGameType!) {
      case MiniGames.treasureHunt:
        break;

      case MiniGames.blueberryWar:
        {
          final bwm =
              _gameState.miniGameState as SerializableBlueberryWarGameState;

          BlueberryWarGameManagerHelpers.updateAllAgents(
              allAgents: bwm.allAgents, dt: dt, problem: bwm.problem);
          // Check for teleportations
          for (final agent in bwm.allAgents) {
            if (agent is! BlueberryAgent) continue;
            // If we detect a velocity of zero and when the blueberry is in starting block
            if (agent.position.x > BlueberryWarConfig.blueberryFieldSize.x &&
                agent.velocity.length2 <
                    BlueberryWarConfig.velocityThreshold2 + 1.0) {
              agent.onTeleport.notifyListeners(
                  (callback) => callback(agent.position, agent.position));
            }
          }
          break;
        }
      case MiniGames.warehouseCleaning:
        break;

      case MiniGames.fixTracks:
        break;
    }
  }
}
