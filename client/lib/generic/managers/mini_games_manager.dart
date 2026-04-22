import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/models/mini_games.dart';
import 'package:common/generic/models/serializable_mini_game_state.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/blueberry_war/managers/blueberry_war_game_manager.dart';
import 'package:train_de_mots/fix_tracks/managers/fix_tracks_game_manager.dart';
import 'package:train_de_mots/generic/managers/controllable_timer.dart';
import 'package:train_de_mots/treasure_hunt/managers/treasure_hunt_game_manager.dart';
import 'package:train_de_mots/warehouse_cleaning/managers/warehouse_cleaning_game_manager.dart';

final _logger = Logger('MiniGamesManager');

abstract class MiniGameManager {
  ///
  /// Initialize the mini game manager. It should prepare everything to be able to
  /// start the mini game, but it should not start the round yet. It is called when
  /// the mini game is selected, and it is followed by a call to [startRound] when the round actually starts.
  Future<void> initialize() async {
    _roundTimer.initialize();
  }

  bool get isInitialized => _roundTimer.isInitialized;

  void dispose() {
    if (_roundTimer.isInitialized) _roundTimer.dispose();
  }

  ///
  /// The instructions to display to the user on the telegram when first playing
  /// the minigame
  String? get instructions;

  ///
  /// The status of the round, which can be used to know if the round is in progress, paused, ended, etc.
  late final _roundTimer = ControllableTimer(
    onStatusChanged: onRoundStatusChanged,
    onClockTicked: onRoundClockTicked,
    shouldEndImmediately: shouldEndRoundImmediately,
  );
  SerializableControllableTimer get roundTimer => _roundTimer.toSerializable();

  ///
  /// Pause the round timer
  void pauseRound() {
    _roundTimer.pause();
  }

  /// Resume the round timer
  void resumeRound() {
    _roundTimer.resume();
  }

  ControllableTimerStatus get roundStatus => _roundTimer.status;

  ///
  /// The duration the minigame round should last.
  Duration get initialRoundDuration;

  ///
  /// Add time to the round timer. It can be used to reward players by giving them more time to solve the puzzle.
  void addTime(Duration time) {
    _roundTimer.addTime(time);
  }

  ///
  /// The time remaining in the round. It can be used to display a timer to the users, or to know when the round is about to end.
  /// If the round is not started yet, or if it has ended, it should return null.
  Duration? get timeRemaining => _roundTimer.timeRemaining;

  ///
  /// Start the mini game round. It should start the round timer, and trigger any
  /// event that should happen at the start of the round. It is called after [initialize],
  /// when the round actually starts.
  void startRound() {
    _roundTimer.start(duration: initialRoundDuration);
    onRoundStarted.notifyListeners((callback) => callback());
  }

  void terminateRound() {
    _roundTimer.stop();
  }

  ///
  /// Callback when the Minigame initialized
  final onInitialized = GenericListener<Function()>();

  ///
  /// Callback when the game starts
  final onRoundStarted = GenericListener<Function()>();

  ///
  /// Callback when the game updates, for example when a player tries a solution. It can be used to trigger a UI update.
  final onGameUpdated = GenericListener<Function()>();

  ///
  /// Callback when the game ends
  final onRoundEnded = GenericListener<Function()>();

  ///
  /// If the game has ended and the players have won
  bool get hasWon;

  ///
  /// Get the points each player has earned in the mini game
  Map<String, int> get playersPoints;

  ///
  /// Get a serialized version of the game state
  SerializableMiniGameState serializeMiniGame();

  ///
  /// Callback when the round status changes, with the new status as a parameter
  void onRoundStatusChanged(ControllableTimerStatus newStatus) {
    switch (newStatus) {
      case ControllableTimerStatus.notInitialized:
      case ControllableTimerStatus.initialized:
        onInitialized.notifyListeners((callback) => callback());
        break;
      case ControllableTimerStatus.inProgress:
      case ControllableTimerStatus.paused:
        break;
      case ControllableTimerStatus.ended:
        pauseRound();
        onRoundEnded.notifyListeners((callback) => callback());
        break;
    }
  }

  ///
  /// Callback on every clock tick, with the time elapsed since the last tick and the current status as parameters
  void onRoundClockTicked(Duration deltaTime, ControllableTimerStatus status) {}

  ///
  /// Callback on every clock tick. If it returns true, the round will end immediately, granted it is not on pause.
  Future<bool> shouldEndRoundImmediately() async => false;
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
    _miniGames[MiniGames.warehouseCleaning] = WarehouseCleaningGameManager();
    _miniGames[MiniGames.fixTracks] = FixTracksGameManager();
    _isInitialized = true;
    _logger.config('Ready');
  }

  final Map<MiniGames, MiniGameManager> _miniGames = {};
  TreasureHuntGameManager get treasureHunt =>
      _miniGames[MiniGames.treasureHunt] as TreasureHuntGameManager;
  BlueberryWarGameManager get blueberryWar =>
      _miniGames[MiniGames.blueberryWar] as BlueberryWarGameManager;
  WarehouseCleaningGameManager get warehouseCleaning =>
      _miniGames[MiniGames.warehouseCleaning] as WarehouseCleaningGameManager;
  FixTracksGameManager get fixTracks =>
      _miniGames[MiniGames.fixTracks] as FixTracksGameManager;

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
    manager!.dispose();
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
