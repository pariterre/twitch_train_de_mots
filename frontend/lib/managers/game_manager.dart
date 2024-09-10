import 'package:common/models/custom_callback.dart';
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
  bool _isGameRunning = false;
  bool _isRoundRunning = false;

  ///
  /// Callback to know when the game has started
  final onGameStarted = CustomCallback();
  bool get isGameRunning => _isGameRunning;
  void startGame() {
    _logger.info('Starting a new game');
    _isGameRunning = true;
    onGameStarted.notifyListeners();
  }

  ///
  /// Callback to know when a round has started
  final onRoundStarted = CustomCallback();
  bool get isRoundRunning => _isRoundRunning;
  void startRound() {
    _logger.info('Starting a new round');
    _isRoundRunning = true;
    onRoundStarted.notifyListeners();
  }

  ///
  /// Callback to know when a round has ended
  final onRoundEnded = CustomCallback();
  void endRound() {
    _logger.info('Ending the current round');
    _isRoundRunning = false;
    onRoundEnded.notifyListeners();
  }

  ///
  /// Callback to know when the game has stopped
  final onGameStopped = CustomCallback();
  void stopGame() {
    _logger.info('Stopping the current game');
    _isGameRunning = false;
    onGameStopped.notifyListeners();
  }

  ///
  /// Stealer and pardonner management
  final List<String> _currentPardonners = [];
  final onPardonnersChanged = CustomCallback();
  List<String> get currentPardonners => List.unmodifiable(_currentPardonners);
  void newPardonners(List<String> newPardonners) {
    _logger.info('New pardonners: $newPardonners');
    _currentPardonners.clear();
    _currentPardonners.addAll(newPardonners);
    onPardonnersChanged.notifyListenersWithParameter(currentPardonners);
  }
  // TODO: Request for pardonners status when connecting
}
