import 'dart:async';

import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/serializable_blueberry_war_game_state.dart';
import 'package:common/generic/managers/global_ticker_manager.dart';
import 'package:common/generic/models/exceptions.dart';
import 'package:common/generic/models/game_status.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/helpers.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:common/generic/models/serializable_player.dart';
import 'package:common/generic/models/success_level.dart';
import 'package:common/warehouse_cleaning/models/serializable_warehouse_cleaning_game_state.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_game_manager_helpers.dart';
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

  void initialize({required GlobalTickerManager tickerManager}) {
    _tickerManager = tickerManager;
    _isInitialized = true;

    _tickerManager.onFixedClockTicked.listen(_tickGame);
  }

  ///
  /// Callback to know when a round has started or ended
  int get currentRound => _gameState.roundCount;
  bool get isRoundRunning =>
      _gameState.gameStatus == WordsTrainGameStatus.roundStarted;
  SuccessLevel get successLevel => _gameState.successLevel;

  Duration get timeRemaining =>
      _gameState.roundTimer.timeRemaining ?? Duration.zero;
  bool get isPaused =>
      status == WordsTrainGameStatus.roundStarted &&
      (isRoundAMiniGame
          ? miniGameState.roundTimer.isPaused
          : _gameState.roundTimer.isPaused);

  bool get hasPlayedAtLeastOneRound => _gameState.hasPlayedAtLeastOnce;
  bool get shouldShowExtension => _gameState.configuration.showExtension;

  ///
  /// Flag to indicate if the game has started
  SerializableGameState _gameState = SerializableGameState.empty();

  ///
  /// A copy of the current game state. This is slow and should not be used apart
  /// from debugging purposes.
  SerializableGameState get gameStateCopy =>
      SerializableGameState.deserialize(_gameState.serialize());

  void updateGameState(SerializableGameState newGameState) {
    if (_gameState.gameStatus != newGameState.gameStatus) {
      _logger.fine('Game status changed to ${newGameState.gameStatus}');
      onGameStatusUpdated.notifyListeners((callback) => callback());
    }

    if (_gameState.roundTimer != newGameState.roundTimer) {
      _logger.fine(
          'Round timer changed to ${newGameState.roundTimer.timeRemaining}');
      onGameStatusUpdated.notifyListeners((callback) => callback());
    }

    if (_gameState.roundCount != newGameState.roundCount ||
        _gameState.successLevel != newGameState.successLevel) {
      _logger.fine('Round changed to ${newGameState.roundCount}');
      onRoundUpdated.notifyListeners((callback) => callback());
    }

    if (!mapEquality(_gameState.players, newGameState.players)) {
      _logger.fine('New players informations');
      onPlayersUpdated.notifyListeners((callback) => callback());
    }

    if (_gameState.letterProblem != newGameState.letterProblem) {
      _logger.fine('Letter problem changed');
      onLetterProblemChanged.notifyListeners((callback) => callback());
    }

    if (!listEquality(
        _gameState.playersWhoCanPardon, newGameState.playersWhoCanPardon)) {
      _logger.fine('Pardonners changed to ${newGameState.playersWhoCanPardon}');
      onPardonnersChanged.notifyListeners((callback) => callback());
    }

    if (_gameState.boostRemaining != newGameState.boostRemaining ||
        !listEquality(_gameState.boosters, newGameState.boosters) ||
        _gameState.boostStillNeeded != newGameState.boostStillNeeded) {
      _logger.fine('Boost count changed to ${newGameState.boostRemaining}');
      onBoostAvailabilityChanged.notifyListeners((callback) => callback());
    }

    if (_gameState.canRequestTheBigHeist !=
        newGameState.canRequestTheBigHeist) {
      onGameStatusUpdated.notifyListeners((callback) => callback());
      _logger.fine(
          'Can request the big heist changed to ${newGameState.canRequestTheBigHeist}');
    }

    if (_gameState.isAttemptingTheBigHeist !=
        newGameState.isAttemptingTheBigHeist) {
      onAttemptingTheBigHeist.notifyListeners((callback) => callback());
      _logger.fine(
          'Is attempting the big heist changed to ${newGameState.isAttemptingTheBigHeist}');
    }

    if (_gameState.canRequestFixTracksMiniGame !=
        newGameState.canRequestFixTracksMiniGame) {
      onGameStatusUpdated.notifyListeners((callback) => callback());
      _logger.fine(
          'Can request the end of railway mini game changed to ${newGameState.canRequestFixTracksMiniGame}');
    }

    if (_gameState.isAttemptingFixTracksMiniGame !=
        newGameState.isAttemptingFixTracksMiniGame) {
      onFixingTheTrack.notifyListeners((callback) => callback());
      _logger.fine(
          'Is attempting the end of railway mini game changed to ${newGameState.isAttemptingFixTracksMiniGame}');
    }

    if (_gameState.configuration.showExtension !=
        newGameState.configuration.showExtension) {
      _gameState.configuration.showExtension =
          newGameState.configuration.showExtension;
      onGameStatusUpdated.notifyListeners((callback) => callback());
    }

    if (_gameState.miniGameState != newGameState.miniGameState) {
      if (_gameState.miniGameState is SerializableBlueberryWarGameState &&
          newGameState.miniGameState is SerializableBlueberryWarGameState) {
        final newMgm =
            newGameState.miniGameState as SerializableBlueberryWarGameState;
        final oldMgm =
            _gameState.miniGameState as SerializableBlueberryWarGameState;

        // Keep the listeners of the blueberry agents
        for (final key in newMgm.allAgents.keys) {
          final newAgent = newMgm.allAgents[key];
          final oldAgent = oldMgm.allAgents[key];
          if (newAgent == null || oldAgent == null) continue;

          newAgent.onTeleport.copyListenersFrom(oldAgent.onTeleport);
          newAgent.onDestroyed.copyListenersFrom(oldAgent.onDestroyed);
        }
      } else if (_gameState.miniGameState
              is SerializableWarehouseCleaningGameState &&
          newGameState.miniGameState
              is SerializableWarehouseCleaningGameState) {
        final newMgm = newGameState.miniGameState
            as SerializableWarehouseCleaningGameState;
        final oldMgm =
            _gameState.miniGameState as SerializableWarehouseCleaningGameState;

        for (int index = 0; index < newMgm.avatars.length; index++) {
          if (!oldMgm.avatars[index].canBeSlingShot) {
            // To smooth the animation, we keep the position and velocity of the
            // avatar if it cannot be sling shot (i.e the user cannot interact with it)
            newMgm.allAgents[newMgm.avatars[index].id.toString()] =
                newMgm.avatars[index].copyWith(
                    position: oldMgm.avatars[index].position,
                    velocity: oldMgm.avatars[index].velocity);
          }
        }
      }
      _logger.fine('Mini game state changed');
      onMiniGameStateUpdated.notifyListeners((callback) => callback());
    }

    _gameState = newGameState;
  }

  ///
  /// Callback for each tick
  void _tickGame(Duration deltaTime) {
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
  final onPlayersUpdated = GenericListener<Function()>();
  Map<String, SerializablePlayer> get players => _gameState.players;

  ///
  /// Callback to know when the letters were changed
  final onLetterProblemChanged = GenericListener<Function()>();
  SerializableLetterProblem? get problem => _gameState.letterProblem;

  ///
  /// Stealer and pardonner management
  final onPardonnersChanged = GenericListener<Function()>();
  int get pardonCount => _gameState.pardonRemaining;
  List<String> get pardonners => _gameState.playersWhoCanPardon;

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

  void changeLaneGranted() {
    onChangeLaneGranted.notifyListeners((callback) => callback());
  }

  ///
  /// Fireworks management
  bool get canRequestFireworks => _gameState.canRequestFireworks;

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
  bool get isMiniGameActive =>
      _gameState.miniGameState is! SerializableMiniGameStateNone;
  SerializableMiniGameState get miniGameState => _gameState.miniGameState;
  final onMiniGameStateUpdated = GenericListener<Function()>();
  void updateMiniGameState(SerializableMiniGameState newMiniGameState) {
    _gameState = _gameState.copyWith(miniGameState: newMiniGameState);
    onMiniGameStateUpdated.notifyListeners((callback) => callback());
  }

  MiniGames? get currentMiniGameType => _gameState.miniGameState.type;
  void _tickMiniGame(Duration deltaTime) {
    switch (currentMiniGameType!) {
      case MiniGames.none:
        break;

      case MiniGames.treasureHunt:
        break;

      case MiniGames.blueberryWar:
        {
          final mgm =
              _gameState.miniGameState as SerializableBlueberryWarGameState;

          BlueberryWarGameManagerHelpers.updateAllAgents(
              allAgents: mgm.allAgents, dt: deltaTime, problem: mgm.problem);
          // Check for teleportations
          for (final agent in mgm.allAgents.values) {
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
        {
          final mgm = _gameState.miniGameState
              as SerializableWarehouseCleaningGameState;
          WareHouseCleaningGameManagerHelpers.updateAllAvatarAgents(
              dt: deltaTime,
              avatars: mgm.avatars,
              boxes: mgm.boxes,
              letters: mgm.letters,
              onLetterCollected: (letter) => {});

          break;
        }

      case MiniGames.fixTracks:
        break;
    }
  }
}
