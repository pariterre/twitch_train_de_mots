import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/blueberry_war/managers/blueberry_war_game_manager.dart';
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
  GenericListener<Function(bool)> get onGameEnded;

  ///
  /// Request the immediate end of the mini game
  Future<void> end();

  ///
  /// Get a serialized version of the game state
  SerializableMiniGameState serialize();
}

class MiniGamesManager {
  ///
  /// Callback when a minigame started
  final onMinigameStarted = GenericListener<Function()>();

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
    _isInitialized = true;
    _logger.config('Ready');
  }

  final Map<MiniGames, MiniGameManager> _miniGames = {};
  TreasureHuntGameManager get treasureHunt =>
      _miniGames[MiniGames.treasureHunt] as TreasureHuntGameManager;
  BlueberryWarGameManager get blueberryWar =>
      _miniGames[MiniGames.blueberryWar] as BlueberryWarGameManager;

  ///
  /// Run a mini game, returns
  Future<void> initialize(MiniGames game) async {
    if (_miniGames[game] == null) {
      throw Exception('Mini game $game is not implemented.');
    }
    _currentGame = game;
    await _miniGames[_currentGame]!.initialize();

    onMinigameStarted.notifyListeners((callback) => callback());
  }

  Future<void> finalize() async {
    if (_currentGame == null) {
      throw Exception('No mini game is running.');
    }
    await _miniGames[_currentGame]!.end();
    _currentGame = null;
    onMinigameEnded.notifyListeners((callback) => callback());
  }

  MiniGames? _currentGame;
  MiniGameManager? get current => _miniGames[_currentGame];
}
