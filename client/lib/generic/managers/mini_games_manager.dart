import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:logging/logging.dart';
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
  /// Prepare the mini game
  Future<void> initialize();

  ///
  /// Start the mini game
  Future<void> start();

  ///
  /// Callback when the game has initialized
  GenericListener<Function()> get onGameIsReady;

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
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  MiniGamesManager() {
    _asyncInitializations();
  }

  Future<void> _asyncInitializations() async {
    _logger.config('Initializing...');
    _miniGames[MiniGames.treasureHunt] = TreasureHuntGameManager();
    _isInitialized = true;
    _logger.config('Ready');
  }

  final Map<MiniGames, MiniGameManager> _miniGames = {};
  TreasureHuntGameManager get treasureHunt =>
      _miniGames[MiniGames.treasureHunt] as TreasureHuntGameManager;

  ///
  /// Run a mini game, returns
  void initialize(MiniGames game) {
    if (_miniGames[game] == null) {
      throw Exception('Mini game $game is not implemented.');
    }
    _currentGame = game;
    _miniGames[_currentGame]!.initialize();
  }

  MiniGames? _currentGame;
  MiniGameManager? get current => _miniGames[_currentGame];
}
