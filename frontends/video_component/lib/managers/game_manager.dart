import 'package:common/models/custom_callback.dart';
import 'package:common/models/simplified_game_state.dart';
import 'package:common/models/game_status.dart';
import 'package:frontend/managers/twitch_manager.dart';
import 'package:logging/logging.dart';

final _logger = Logger('GameManager');

class GameManager {
  ///
  /// Prepare the singleton
  static final _instance = GameManager._();
  static GameManager get instance => _instance;
  GameManager._();

  ///
  /// Callback to know when a round has started or ended
  int get currentRound => _gameState.round;
  bool get isRoundRunning => _gameState.status == GameStatus.roundStarted;
  int _previousRound = -1;
  int get previousRound => _previousRound;

  bool _hasPlayedAtLeastOneRound = false;
  bool get hasPlayedAtLeastOneRound => _hasPlayedAtLeastOneRound;

  ///
  /// Flag to indicate if the game has started
  final _gameState = SimplifiedGameState(
    status: GameStatus.uninitialized,
    round: 0,
    letterProblem: null,
    pardonRemaining: 0,
    pardonners: [],
    boostRemaining: 0,
    boostStillNeeded: 0,
    boosters: [],
    canAttemptTheBigHeist: false,
    isAttemptingTheBigHeist: false,
  );

  void updateGameState(SimplifiedGameState newGameState) {
    if (_gameState.status != newGameState.status) {
      _gameState.status = newGameState.status;
      if (_gameState.status == GameStatus.roundStarted ||
          _gameState.round > 0) {
        _hasPlayedAtLeastOneRound = true;
      }
      onGameStatusUpdated.notifyListeners();
      _logger.info('Game status changed to ${_gameState.status}');
    }

    if (_gameState.round != newGameState.round) {
      _previousRound = _gameState.round;
      _gameState.round = newGameState.round;
      _logger.info('Round changed to ${newGameState.round}');
    }

    if (_gameState.letterProblem != newGameState.letterProblem) {
      _gameState.letterProblem = newGameState.letterProblem;
      _logger.info('Letter problem changed');
      onLetterProblemChanged.notifyListeners();
    }

    if (_gameState.pardonners != newGameState.pardonners) {
      _gameState.pardonners = newGameState.pardonners;
      _logger.info('Pardonners changed to ${newGameState.pardonners}');
      onPardonnersChanged.notifyListeners();
    }

    if (_gameState.boostRemaining != newGameState.boostRemaining) {
      _gameState.boostRemaining = newGameState.boostRemaining;
      _logger.info('Boost count changed to ${newGameState.boostRemaining}');
      onBoostAvailabilityChanged.notifyListeners();
    }

    if (_gameState.boostStillNeeded != newGameState.boostStillNeeded) {
      _gameState.boostStillNeeded = newGameState.boostStillNeeded;
      _logger.info(
          'Boost still needed changed to ${newGameState.boostStillNeeded}');
    }

    if (_gameState.boosters != newGameState.boosters) {
      _gameState.boosters = newGameState.boosters;
      _logger.info('Boosters changed to ${newGameState.boosters}');
    }

    if (_gameState.canAttemptTheBigHeist !=
        newGameState.canAttemptTheBigHeist) {
      _gameState.canAttemptTheBigHeist = newGameState.canAttemptTheBigHeist;
      onGameStatusUpdated.notifyListeners();
      _logger.info(
          'Can attempt the big heist changed to ${newGameState.canAttemptTheBigHeist}');
    }

    if (_gameState.isAttemptingTheBigHeist !=
        newGameState.isAttemptingTheBigHeist) {
      _gameState.isAttemptingTheBigHeist = newGameState.isAttemptingTheBigHeist;
      onAttemptingTheBigHeist.notifyListeners();
      _logger.info(
          'Is attempting the big heist changed to ${newGameState.isAttemptingTheBigHeist}');
    }
  }

  ///
  /// Callback to know when the game has started
  GameStatus get status => _gameState.status;
  final onGameStatusUpdated = CustomCallback();
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
  /// Callback to know when the letters were changed
  final onLetterProblemChanged = CustomCallback();
  SimplifiedLetterProblem? get problem => _gameState.letterProblem;

  ///
  /// Stealer and pardonner management
  final onPardonnersChanged = CustomCallback();
  List<String> get pardonners => List.unmodifiable(_gameState.pardonners);

  final onPardonGranted = CustomCallback<Function(bool)>();
  Future<bool> pardonStealer() async {
    final isSuccess = await TwitchManager.instance.pardonStealer();
    onPardonGranted.notifyListenersWithParameter(isSuccess);
    return isSuccess;
  }

  ///
  /// Boost availability
  int get boostCount => _gameState.boostRemaining;
  final onBoostAvailabilityChanged = CustomCallback();

  final onBoostGranted = CustomCallback<Function(bool)>();
  Future<bool> boostTrain() async {
    final isSuccess = await TwitchManager.instance.boostTrain();
    onBoostGranted.notifyListenersWithParameter(isSuccess);
    return isSuccess;
  }

  List<String> get boosters => List.unmodifiable(_gameState.boosters);

  ///
  /// Big heist management
  bool get canAttemptTheBigHeist => _gameState.canAttemptTheBigHeist;
  final onAttemptingTheBigHeist = CustomCallback();
}
