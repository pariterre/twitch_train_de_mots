import 'package:logging/logging.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

final _logger = Logger('TimeTrigger');

mixin class TimeTrigger {
  ///
  /// How much time is left until the trigger
  DateTime? _triggerAt;
  DateTime? get triggerAt => _triggerAt;
  Duration? get timeBeforeTrigger => _triggerAt?.difference(DateTime.now());

  void startTrigger(Duration duration) {
    if (_triggerAt != null) {
      throw Exception('Trigger is already started.');
    }
    _triggerAt = DateTime.now().add(duration);
    _pauseStartedAt = null;

    Managers.instance.tickerManager.onFixedClockTicked.cancel(_loop);
    _logger
        .info('Trigger started, will trigger in ${duration.inSeconds} seconds');
  }

  DateTime? _pauseStartedAt;
  void pauseTrigger() {
    if (_pauseStartedAt != null) {
      throw Exception('Trigger is already paused.');
    }
    _pauseStartedAt = DateTime.now();
    _logger.info('Trigger paused');
  }

  void resumeTrigger() {
    if (_pauseStartedAt == null) {
      throw Exception('Trigger is not paused.');
    }

    final pauseDuration = DateTime.now().difference(_pauseStartedAt!);
    _triggerAt = _triggerAt?.add(pauseDuration);
    _pauseStartedAt = null;
    _logger.info('Trigger resumed');
  }

  void addTimeToTrigger(Duration duration) {
    if (_triggerAt == null) {
      throw Exception('Trigger is not started.');
    }

    _triggerAt = _triggerAt?.add(duration);
    _logger.info('Added ${duration.inSeconds} seconds to the round');
  }

  void triggerNow() {
    _triggerAt = DateTime.now();
    _logger.info('Set the trigger to go off immediately');
  }

  ///
  /// Cancel the trigger. It necessitates to call start again to restart the trigger
  Future<void> cancelTrigger() async {
    _triggerAt = null;
    _pauseStartedAt = null;
    Managers.instance.tickerManager.onFixedClockTicked.cancel(_loop);
  }

  ///
  /// The loop, called on every fixed clock tick until the trigger goes off
  void _loop(Duration deltaTime) {
    // Check if should be ended immediately
    if (shouldTriggerImmediately()) _triggerAt = DateTime.now();

    if (timeBeforeTrigger != null && timeBeforeTrigger!.isNegative) {
      onTriggerWentOff();
      cancelTrigger();
    } else {
      onTriggerClockTicked(deltaTime);
    }
  }

  /// -----------------------------------------
  /// Methods to override by the implementations of the round manager
  /// -----------------------------------------

  ///
  /// Called during the loop at each frame. Can be used to delay the trigger if needed.
  ///
  void onTriggerClockTicked(Duration deltaTime) {}

  ///
  /// If the trigger should go off immediately. This can be used to trigger the event when a certain condition is met
  bool shouldTriggerImmediately() {
    return false;
  }

  ///
  /// This is called when the trigger goes off.
  void onTriggerWentOff() {}
}
