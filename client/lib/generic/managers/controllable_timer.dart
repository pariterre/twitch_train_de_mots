import 'package:common/generic/managers/serializable_controllable_timer.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

final _logger = Logger('ControllableTimer');

class ControllableTimer {
  ///
  /// If the class has properly been initialized. It is not possible to call any
  /// method before initialization, and the manager should be re-initialized after termination.
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  ///
  /// How much time is left
  DateTime? _endsAt;
  DateTime? get endsAt => _endsAt;
  Duration? get timeRemaining =>
      (_endsAt?.difference(DateTime.now()) ?? Duration.zero) +
      (pauseTime ?? Duration.zero);
  Duration? get pauseTime =>
      _pausedAt != null ? DateTime.now().difference(_pausedAt!) : null;

  ///
  /// Manage ending flag
  bool _shouldEndImmediately = false;

  ///
  /// If the timer is currently paused, and since when
  DateTime? _pausedAt;
  DateTime? get pausedAt => _pausedAt;

  ///
  /// Previous status of the timer, used to detect status changes
  ControllableTimerStatus _previousStatus =
      ControllableTimerStatus.notInitialized;

  ///
  /// Set up the available callbacks for the timer.
  final void Function(ControllableTimerStatus newStatus)? onStatusChanged;
  final void Function(Duration deltaTime, ControllableTimerStatus status)?
      onClockTicked;
  final Future<bool> Function()? shouldEndImmediately;

  ///
  /// Create a new ControllableTimer with the given callbacks.
  /// The timer is not started until [start] is called.
  /// The timer can be [pause] and [resume].
  /// [addTime] can be used to add time to the timer, and [stop] can be used to end immediately.
  /// The latter won't have immediate effect if timer is on pause, but will end immediately once resumed.
  /// [dispose] can be used to cancel the timer.
  /// [onStatusChanged] is a callback called when the status of the timer changes, with the new status as a parameter.
  /// [onClockTicked] is a callback called on every fixed clock tick until the timer ends,
  /// with the time elapsed since the last tick as a parameter.
  /// [shouldEndImmediately] is a callback called on every fixed clock tick.
  /// If it returns true, the timer will end immediately during the current tick, granted it is not on pause.
  ControllableTimer({
    this.onStatusChanged,
    this.onClockTicked,
    this.shouldEndImmediately,
  });

  ///
  ///
  ///
  void initialize() {
    if (isInitialized) throw Exception('Timer is already initialized.');

    reset();
    _isInitialized = true;
    Managers.instance.tickerManager.onFixedClockTicked.listen(_loop);
  }

  void reset() {
    _endsAt = null;
    _pausedAt = null;
    _shouldEndImmediately = false;
  }

  ///
  /// Start the timer with the given duration.
  void start({required Duration duration}) {
    if (!isInitialized) throw Exception('Timer is not initialized.');

    reset();
    _endsAt = DateTime.now().add(duration);

    _logger.info('Timer started, will end in ${duration.inSeconds} seconds');
  }

  ///
  /// Pause the timer. It can be resumed later with resume, which will add the
  void pause() {
    if (!isInitialized) throw Exception('Timer is not initialized.');

    _pausedAt = DateTime.now();
    _logger.info('Timer paused');
  }

  ///
  /// Resume the timer if it was paused.
  void resume() {
    if (!isInitialized) throw Exception('Timer is not initialized.');

    final pauseDuration = DateTime.now().difference(_pausedAt!);
    _endsAt = _endsAt?.add(pauseDuration);
    _pausedAt = null;
    _logger.info('Timer resumed');
  }

  ///
  /// Add time to the timer.
  void addTime(Duration duration) {
    if (!isInitialized) throw Exception('Timer is not initialized.');
    if (status != ControllableTimerStatus.inProgress &&
        status != ControllableTimerStatus.paused) {
      throw Exception('Timer is not started.');
    }

    _endsAt = _endsAt?.add(duration);
    _logger.finer('Added ${duration.inMilliseconds} milliseconds to the round');
  }

  ///
  /// Subtract time from the timer.
  void subtractTime(Duration duration) {
    if (!isInitialized) throw Exception('Timer is not initialized.');
    if (status != ControllableTimerStatus.inProgress &&
        status != ControllableTimerStatus.paused) {
      throw Exception('Timer is not started.');
    }

    _endsAt = _endsAt?.subtract(duration);
    _logger.finer(
        'Subtracted ${duration.inMilliseconds} milliseconds from the round');
  }

  ///
  /// Force the timer to go off immediately.
  void stop() {
    if (!isInitialized) throw Exception('Timer is not initialized.');
    if (status != ControllableTimerStatus.inProgress &&
        status != ControllableTimerStatus.paused) {
      throw Exception('Timer is not started.');
    }

    _shouldEndImmediately = true;
    _logger.info('Set the timer to go off immediately');
  }

  SerializableControllableTimer toSerializable() {
    return SerializableControllableTimer(
      isInitialized: isInitialized,
      endsAt: _endsAt,
      pausedAt: _pausedAt,
    );
  }

  ///
  /// Dispose the timer. The loop will be stopped and the timer will be reset.
  /// It can however be re-initialized later with [initialize].
  void dispose() {
    if (!isInitialized) throw Exception('Timer is not initialized.');

    reset();
    _isInitialized = false;
    Managers.instance.tickerManager.onFixedClockTicked.cancel(_loop);
  }

  ControllableTimerStatus get status {
    final isStarted = _endsAt != null;
    final isPaused = _pausedAt != null;
    final isOver = (_shouldEndImmediately ||
        (timeRemaining != null && timeRemaining!.isNegative));

    if (!isInitialized) {
      return ControllableTimerStatus.notInitialized;
    } else if (isPaused) {
      return ControllableTimerStatus.paused;
    } else if (isOver) {
      return ControllableTimerStatus.ended;
    } else if (isStarted) {
      return ControllableTimerStatus.inProgress;
    } else {
      return ControllableTimerStatus.initialized;
    }
  }

  ///
  /// The loop, called on every fixed clock tick until the timer ends
  Future<void> _loop(Duration deltaTime) async {
    _shouldEndImmediately |=
        shouldEndImmediately != null && await shouldEndImmediately!();

    final currentStatus = status;
    if (_previousStatus != currentStatus && onStatusChanged != null) {
      onStatusChanged!(currentStatus);
      _previousStatus = currentStatus;
    }

    if (onClockTicked != null) onClockTicked!(deltaTime, currentStatus);
  }
}
