import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/blueberry_war/managers/blueberry_war_game_manager.dart';
import 'package:train_de_mots/track_fix/managers/track_fix_game_manager.dart';
import 'package:train_de_mots/treasure_hunt/managers/treasure_hunt_game_manager.dart';

final _logger = Logger('MiniGamesManager');

abstract class MiniGameManager {
  ///
  /// How much time is left in the mini game
  Duration get timeRemaining;

  ///
  /// If the mini game is ready to start. A signal to [onGameIsReady] is also
  /// expected to be sent
  bool get isReady;

  ///
  /// The instructions to display to the user on the telegram when first playing
  /// the minigame
  String? get instructions;

  ///
  /// Prepare the mini game
  Future<void> initialize();

  ///
  /// Start the mini game
  Future<void> start();

  ///
  /// Callback when the game has initialized
  GenericListener<Function()> get onGameIsReady;

  ///
  /// Callback when the game updated
  GenericListener<Function()> get onGameUpdated;

  ///
  /// Connect to the mini game results
  GenericListener<Function({required bool hasWon})> get onGameEnded;

  ///
  /// Request the immediate end of the mini game
  Future<void> end();

  ///
  /// Get the points each player has earned in the mini game
  Map<String, int> get playersPoints;

  ///
  /// Get a serialized version of the game state
  SerializableMiniGameState serialize();
}

class MiniGamesManager {
  ///
  /// Callback when a minigame started
  final onMinigameStarted = GenericListener<Function()>();

  ///
  /// Callback when the minigame updated. This connects to the `onGameUpdated`
  /// of the current mini game manager and relays the event to the listeners
  final onMinigameUpdated = GenericListener<Function()>();

  ///
  /// Callback when a minigame ended
  final onMinigameEnded = GenericListener<Function()>();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  MiniGamesManager() {
    _asyncInitializations();
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');
    _miniGames[MiniGames.treasureHunt] = TreasureHuntGameManager();
    _miniGames[MiniGames.blueberryWar] = BlueberryWarGameManager();
    // _miniGames[MiniGames.trackFix] = TrackFixGameManager();
    _isInitialized = true;
    _logger.config('Ready');
  }

  final Map<MiniGames, MiniGameManager> _miniGames = {};
  TreasureHuntGameManager get treasureHunt =>
      _miniGames[MiniGames.treasureHunt] as TreasureHuntGameManager;
  BlueberryWarGameManager get blueberryWar =>
      _miniGames[MiniGames.blueberryWar] as BlueberryWarGameManager;
  // TrackFixGameManager get trackFix =>
  //     _miniGames[MiniGames.trackFix] as TrackFixGameManager;

  ///
  /// Run a mini game, returns
  Future<void> initialize(MiniGames game) async {
    if (_isActive) {
      throw Exception('Mini game already running: $_currentOrPreviousGame');
    }
    _isActive = true;
    _currentOrPreviousGame = game;
    await manager!.initialize();

    // Register to the mini game events to relay them anything that needs to
    // listen to them too
    manager!.onGameUpdated.listen(_notifyThatMiniGameHasUpdated);

    // Notify that the mini game is ready to start
    onMinigameStarted.notifyListeners((callback) => callback());
  }

  void _notifyThatMiniGameHasUpdated() {
    onMinigameUpdated.notifyListeners((callback) => callback());
  }

  Map<String, int> getPlayersPoints() {
    if (!_isActive) {
      throw Exception('No mini game is running.');
    }

    return manager!.playersPoints;
  }

  Future<void> finalize() async {
    if (!_isActive) {
      throw Exception('No mini game is running.');
    }

    // Cancel the listeners to avoid memory leaks
    manager!.onGameUpdated.cancel(_notifyThatMiniGameHasUpdated);

    // Terminate the mini game
    await manager!.end();
    _isActive = false;
    onMinigameEnded.notifyListeners((callback) => callback());
  }

  bool _isActive = false;
  MiniGames _currentOrPreviousGame = MiniGames.values[0];
  MiniGames? get current => _isActive ? _currentOrPreviousGame : null;
  MiniGames get currentOrPrevious => _currentOrPreviousGame;
  MiniGameManager? get manager =>
      _isActive ? _miniGames[_currentOrPreviousGame] : null;
}
