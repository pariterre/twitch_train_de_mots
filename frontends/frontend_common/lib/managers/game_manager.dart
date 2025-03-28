import 'dart:async';

import 'package:common/models/game_status.dart';
import 'package:common/models/generic_listener.dart';
import 'package:common/models/helpers.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:frontend_common/managers/twitch_manager.dart';
import 'package:logging/logging.dart';

final _logger = Logger('GameManager');

class GameManager {
  ///
  /// Prepare the singleton
  static final _instance = GameManager._();
  static GameManager get instance => _instance;
  GameManager._() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _gameState.timeRemaining -= const Duration(seconds: 1);
      onGameTicked.notifyListeners((callback) => callback());
    });
  }

  ///
  /// Callback to know when a round has started or ended
  int get currentRound => _gameState.round;
  bool get isRoundRunning => _gameState.status == GameStatus.roundStarted;
  bool get isRoundSuccess => _gameState.isRoundSuccess;

  Duration get timeRemaining => _gameState.timeRemaining;

  bool _hasPlayedAtLeastOneRound = false;
  bool get hasPlayedAtLeastOneRound => _hasPlayedAtLeastOneRound;

  bool get shouldShowExtension => _gameState.configuration.showExtension;

  ///
  /// Flag to indicate if the game has started
  final _gameState = SimplifiedGameState(
    status: GameStatus.uninitialized,
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
    configuration: SimplifiedConfiguration(showExtension: true),
  );

  void updateGameState(SimplifiedGameState newGameState) {
    if (_gameState.status != newGameState.status) {
      _gameState.status = newGameState.status;
      if (_gameState.status == GameStatus.roundStarted ||
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
  }

  ///
  /// Callback for each tick
  final onGameTicked = GenericListener<Function()>();

  ///
  /// Callback to know when the game has started
  GameStatus get status => _gameState.status;
  final onGameStatusUpdated = GenericListener<Function()>();
  void startGame() {
    _logger.info('Starting a new game');
    updateGameState(_gameState.copyWith(status: GameStatus.initializing));
  }

  ///
  /// Callback to know when the game has stopped
  void stopGame() {
    _logger.info('Stopping the current game');
    updateGameState(_gameState.copyWith(status: GameStatus.uninitialized));
  }

  ///
  /// Callback to know when a solution was found
  final onNewCooldowns = GenericListener<Function()>();
  Map<String, Duration> get newCooldowns =>
      Map.unmodifiable(_gameState.newCooldowns);

  ///
  /// Callback to know when the letters were changed
  final onLetterProblemChanged = GenericListener<Function()>();
  SimplifiedLetterProblem? get problem => _gameState.letterProblem;

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
}
