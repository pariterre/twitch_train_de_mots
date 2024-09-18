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
  /// Flag to indicate if the game has started
  final _gameState = SimplifiedGameState(
      status: GameStatus.initializing,
      round: 0,
      pardonRemaining: 0,
      pardonners: [],
      boostRemaining: 0,
      boostStillNeeded: 0);
  SimplifiedGameState get gameState => _gameState;

  void updateGameState(SimplifiedGameState newGameState) {
    if (_gameState.status != newGameState.status) {
      _gameState.status = newGameState.status;
      _logger.info('Game status changed to ${_gameState.status}');
      switch (_gameState.status) {
        case GameStatus.roundStarted:
          onRoundStarted.notifyListeners();
          break;
        case GameStatus.initializing:
        case GameStatus.roundPreparing:
        case GameStatus.roundReady:
        case GameStatus.revealAnswers:
          onRoundEnded.notifyListeners();
          break;
        case GameStatus.uninitialized:
          break;
      }
    }

    if (_gameState.round != newGameState.round) {
      _gameState.round = newGameState.round;
      _logger.info('Round changed to ${newGameState.round}');
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
  }

  ///
  /// Callback to know when the game has started
  final onGameStarted = CustomCallback();
  GameStatus get status => _gameState.status;
  void startGame() {
    _logger.info('Starting a new game');
    _gameState.status = GameStatus.roundPreparing;
    onGameStarted.notifyListeners();
  }

  ///
  /// Callback to know when a round has started or ended
  int get currentRound => _gameState.round;
  bool get isRoundRunning => _gameState.status == GameStatus.roundStarted;
  final onRoundStarted = CustomCallback();
  final onRoundEnded = CustomCallback();

  ///
  /// Callback to know when the game has stopped
  final onGameEnded = CustomCallback();
  void stopGame() {
    _logger.info('Stopping the current game');
    _gameState.status = GameStatus.initializing;
    onGameEnded.notifyListeners();
  }

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
}
