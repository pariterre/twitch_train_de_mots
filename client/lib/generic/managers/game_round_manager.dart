import 'package:common/generic/models/generic_listener.dart';
import 'package:common/generic/managers/serializable_game_round_manager.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

final _logger = Logger('GameRoundManager');

enum GameRoundStatus {
  notInitialized,
  initialized,
  inProgress,
  paused,
  isEnding,
  ended,
}

abstract mixin class GameRoundManager {
  ///
  /// If the class has properly been initialized. It is not possible to call any
  /// method before initialization, and the manager should be re-initialized after termination.
  bool _isRoundInitialized = false;
  bool get isRoundInitialized => _isRoundInitialized;

  ///
  /// How much time is left in the game
  DateTime? _roundEndsAt;
  DateTime? get roundEndsAt => _roundEndsAt;
  Duration? get timeRemaining => _roundEndsAt?.difference(DateTime.now());

  DateTime? _pauseStartedAt;
  void pauseRound() {
    if (!_isRoundInitialized) throw Exception('Round is not initialized.');

    if (_pauseStartedAt != null) {
      throw Exception('Round is already paused.');
    }
    _pauseStartedAt = DateTime.now();
    _logger.info('Round paused');
  }

  void resumeRound() {
    if (!_isRoundInitialized) throw Exception('Round is not initialized.');

    if (_pauseStartedAt == null) {
      throw Exception('Round is not paused.');
    }
    final pauseDuration = DateTime.now().difference(_pauseStartedAt!);
    _roundEndsAt = _roundEndsAt?.add(pauseDuration);
    _pauseStartedAt = null;
    _logger.info('Round resumed');
  }

  ///
  /// Prepare the round
  Future<void> initializeRound() async {
    if (_isRoundInitialized) throw Exception('Round is already initialized.');

    _roundEndsAt = null;
    _pauseStartedAt = null;
    _isRoundInitialized = true;
    Managers.instance.tickerManager.onFixedClockTicked.listen(_roundLoop);
    onRoundInitialized.notifyListeners((callback) => callback());
  }

  ///
  /// The status of the round, depending on the time remaining and if it's paused or not
  GameRoundStatus get roundStatus {
    final isInitialized = _isRoundInitialized;
    final isStarted = _roundEndsAt != null;
    final isPaused = _pauseStartedAt != null;
    final isOver = (timeRemaining?.isNegative ?? true) && !isPaused;
    final isEnding = isStarted && isOver;

    if (!isInitialized) {
      return GameRoundStatus.notInitialized;
    } else if (isEnding) {
      return GameRoundStatus.isEnding;
    } else if (isOver) {
      return GameRoundStatus.ended;
    } else if (isPaused) {
      return GameRoundStatus.paused;
    } else if (isStarted) {
      return GameRoundStatus.inProgress;
    } else {
      return GameRoundStatus.initialized;
    }
  }

  ///
  /// Start the round
  Future<void> startRound({Duration? duration}) async {
    if (!_isRoundInitialized) throw Exception('Round is not initialized.');
    if (duration == null) {
      throw Exception('Duration must be provided to start the round.');
    }

    _roundEndsAt = DateTime.now().add(duration);
    _pauseStartedAt = null;
    onRoundStarted.notifyListeners((callback) => callback());
    _logger.info('Round started');
  }

  void addTimeToRound(Duration duration) {
    if (roundStatus != GameRoundStatus.inProgress) {
      throw Exception('Round is not in progress.');
    }

    _roundEndsAt = _roundEndsAt?.add(duration);
    _logger.info('Added ${duration.inSeconds} seconds to the round');
  }

  Future<void> endRound() async {
    if (!_isRoundInitialized) throw Exception('Round is not initialized.');

    _roundEndsAt = DateTime.now();
    onRoundEnded.notifyListeners((callback) => callback());
    _logger.info('Round ended');
  }

  ///
  /// Terminate the manager. It necessitates to call initialize again to start a new round
  Future<void> terminateRound() async {
    if (!_isRoundInitialized) throw Exception('Round is not initialized.');

    _roundEndsAt = null;
    _pauseStartedAt = null;
    _isRoundInitialized = false;
    Managers.instance.tickerManager.onFixedClockTicked.cancel(_roundLoop);
  }

  ///
  /// Callback when the round is initialized
  final onRoundInitialized = GenericListener<Function()>();

  ///
  /// Callback when the round started
  final onRoundStarted = GenericListener<Function()>();

  ///
  /// Callback when clock ticks
  final onRoundClockTicked = GenericListener<Function()>();

  ///
  /// Callback when is paused
  final onRoundPaused = GenericListener<Function()>();

  ///
  /// Callback when is resumed
  final onRoundResumed = GenericListener<Function()>();

  ///
  /// Callback when the round ended
  final onRoundEnded = GenericListener<Function()>();

  ///
  /// Serialize the round manager state to be sent to the clients
  SerializableGameRoundManager toSerializableRound() =>
      SerializableGameRoundManager(
        roundEndsAt: _roundEndsAt,
        pauseStartedAt: _pauseStartedAt,
      );

  ///
  /// The game loop, called on every fixed clock tick
  Future<void> _roundLoop(Duration deltaTime) async {
    // Check if should be ended immediately
    if (await shouldEndRoundImmediately()) _roundEndsAt = DateTime.now();

    // Process the relevant logic depending on the round state
    switch (roundStatus) {
      case GameRoundStatus.notInitialized:
        break;
      case GameRoundStatus.initialized:
        await processPreRound(deltaTime);
        break;
      case GameRoundStatus.inProgress:
        await processRound(deltaTime);
        break;
      case GameRoundStatus.paused:
        await processRoundPaused(deltaTime);
        break;
      case GameRoundStatus.isEnding:
        await processRoundIsEnding();
        _roundEndsAt = null;
        onRoundEnded.notifyListeners((callback) => callback());
        break;
      case GameRoundStatus.ended:
        await processPostRound(deltaTime);
        break;
    }

    await onRoundClockTicked.notifyListeners((callback) => callback());
  }

  /// -----------------------------------------
  /// Methods to override by the implementations of the round manager
  /// -----------------------------------------

  ///
  /// Main processing of the pre-round, while waiting for the round to be started.
  /// This can be used to prepare the game and do some animations before the round starts, while still being able to cancel it if needed
  Future<void> processPreRound(Duration deltaTime) async {}

  ///
  /// Main processing of the game loop
  Future<void> processRound(Duration deltaTime) async {}

  ///
  /// Main processing when the round is paused during the game loop
  Future<void> processRoundPaused(Duration deltaTime) async {}

  ///
  /// If the round should end even if the time is not over. This can be used to end the round when a certain condition is met
  Future<bool> shouldEndRoundImmediately() async {
    return false;
  }

  ///
  /// Processing of the end of the round
  Future<void> processRoundIsEnding() async {}

  ///
  /// Processing after the round ended, while waiting for the manager to be terminated or re-initialized
  Future<void> processPostRound(Duration deltaTime) async {}
}
