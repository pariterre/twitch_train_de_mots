import 'package:common/generic/models/generic_listener.dart';
import 'package:flutter/scheduler.dart';

class GlobalTickerManager {
  final onClockTicked = GenericListener<Function(Duration deltaTime)>();
  final onFixedClockTicked = GenericListener<Function(Duration deltaTime)>();

  GlobalTickerManager({
    required TickerProvider vsync,
    Duration fixedDeltaTime = const Duration(milliseconds: 16),
  }) : _fixedDeltaTime = fixedDeltaTime {
    _deltaTime = Duration.zero;
    _previousTickTime = DateTime.now();

    _ticker = vsync.createTicker(_tick);
    _ticker!.start();
  }

  Ticker? _ticker;
  final Duration _fixedDeltaTime;

  /// Recreates the [Ticker] with the new [TickerProvider].
  void resync(TickerProvider vsync) {
    final Ticker oldTicker = _ticker!;
    _ticker = vsync.createTicker(_tick);
    _ticker!.absorbTicker(oldTicker);
    _ticker!.start();
  }

  ///
  /// The amount of time that has passed between now and the most recent tick.
  Duration _deltaTime = Duration.zero;

  ///
  /// The amount of time that has passed since the last fixed tick. This is used to determine when to call the fixed tick callback.
  Duration _accumulator = Duration.zero;

  ///
  /// The time of the most recent tick.
  DateTime get previousTickTime => _previousTickTime;
  DateTime _previousTickTime = DateTime.now();

  ///
  /// Whether this controller is currently ticking or not
  bool get isTicking => _ticker != null && _ticker!.isActive;

  ///
  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  ///
  /// The most recently returned [TickerFuture], if any, is marked as having been
  /// canceled, meaning the future never completes and its [TickerFuture.orCancel]
  /// derivative future completes with a [TickerCanceled] error.
  void dispose() {
    _ticker!.dispose();
    _ticker = null;
  }

  void _tick(Duration elapsed) {
    final double elapsedInSeconds =
        elapsed.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
    assert(elapsedInSeconds >= 0.0);

    final DateTime now = DateTime.now();
    _deltaTime = now.difference(_previousTickTime);
    _previousTickTime = now;

    // Call the fixed related callabaks as many times as needed, before then calling the regular clock callbacks
    _accumulator += _deltaTime;
    final int maxAccumulatorTicks = 5;
    int tickCount = 0;
    while (_accumulator >= _fixedDeltaTime && tickCount < maxAccumulatorTicks) {
      onFixedClockTicked
          .notifyListeners((callback) => callback(_fixedDeltaTime));
      _accumulator -= _fixedDeltaTime;
      tickCount++;
    }

    // Call the regular clock callbacks
    onClockTicked.notifyListeners((callback) => callback(_deltaTime));
  }
}
