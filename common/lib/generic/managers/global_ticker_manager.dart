import 'package:common/generic/models/generic_listener.dart';
import 'package:flutter/scheduler.dart';

class GlobalTickerManager {
  final onClockTicked = GenericListener<Function()>();

  GlobalTickerManager({
    required TickerProvider vsync,
  }) {
    _deltaTime = Duration.zero;
    _previousTickTime = DateTime.now();

    _ticker = vsync.createTicker(_tick);
    _ticker!.start();
  }

  Ticker? _ticker;

  /// Recreates the [Ticker] with the new [TickerProvider].
  void resync(TickerProvider vsync) {
    final Ticker oldTicker = _ticker!;
    _ticker = vsync.createTicker(_tick);
    _ticker!.absorbTicker(oldTicker);
    _ticker!.start();
  }

  ///
  /// The amount of time that has passed between now and the most recent tick.
  Duration get deltaTime => _deltaTime;
  Duration _deltaTime = Duration.zero;

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

    onClockTicked.notifyListeners((callback) => callback());
  }
}
