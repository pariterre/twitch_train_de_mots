import 'package:common/models/custom_callback.dart';

class GameManager {
  ///
  /// Prepare the singleton
  static final _instance = GameManager._();
  static GameManager get instance => _instance;
  GameManager._();

  ///
  /// Flag to indicate if the game has started
  bool _gameIsRunning = false;

  ///
  /// Callback to know when the game has started
  final onGameStarted = CustomCallback();
  bool get gameIsRunning => _gameIsRunning;
  void startGame() {
    _gameIsRunning = true;
    onGameStarted.notifyListeners();
  }

  ///
  /// Callback to know when the game has stopped
  final onGameStopped = CustomCallback();
  void stopGame() {
    _gameIsRunning = false;
    onGameStopped.notifyListeners();
  }

  ///
  /// Stealer and pardonner management
  final List<String> _currentPardonners = [];
  final onPardonnersChanged = CustomCallback();
  List<String> get currentPardonners => List.unmodifiable(_currentPardonners);
  void newPardonners(List<String> newPardonners) {
    _currentPardonners.clear();
    _currentPardonners.addAll(newPardonners);
    onPardonnersChanged.notifyListenersWithParameter(currentPardonners);
  }
  // TODO: Request for pardonners status when connecting
}
