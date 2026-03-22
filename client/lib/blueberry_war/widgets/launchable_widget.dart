import 'dart:math';

import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class LaunchableWidgetController {
  _LaunchableWidgetState? _state;

  void startTimer() {
    if (_state == null) {
      throw Exception('Controller is not attached to a LaunchableWidgetState');
    }

    final ticker = Managers.instance.tickerManager;
    ticker.onClockTicked
        .listen(() => _state!._advancePosition(ticker.deltaTime));
  }

  void setVelocity(double xVelocity, double yVelocity) {
    if (_state == null) {
      throw Exception('Controller is not attached to a LaunchableWidgetState');
    }
    _state!._xVelocity = xVelocity;
    _state!._yVelocity = yVelocity;
  }
}

class LaunchableWidget extends StatefulWidget {
  const LaunchableWidget({
    super.key,
    required this.controller,
    this.xPosition,
    this.yPosition,
    required this.maxWidth,
    required this.maxHeight,
    required this.child,
  });

  final LaunchableWidgetController controller;
  final double? xPosition;
  final double? yPosition;
  final double maxWidth;
  final double maxHeight;
  final Widget child;

  @override
  State<LaunchableWidget> createState() => _LaunchableWidgetState();
}

class _LaunchableWidgetState extends State<LaunchableWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  final _minPositionX = 0.0;
  late final _maxPositionX = widget.maxWidth;
  final _minPositionY = 0.0;
  late final _maxPositionY = widget.maxHeight;

  final _random = Random();

  late double _xPosition = widget.xPosition ?? _maxPositionX / 2;
  late double _yPosition = widget.yPosition ?? _maxPositionY / 2;
  late double _xVelocity = _random.nextDouble() * 30 - 15;
  late double _yVelocity = _random.nextDouble() * 30 - 15;
  double get _velocity => _xVelocity * _xVelocity + _yVelocity * _yVelocity;

  void _advancePosition(Duration deltaTime) {
    if (_velocity < 0.01) return;

    setState(() {
      // Calculate push based on the time since the last update
      final delta =
          deltaTime.inMilliseconds / 100.0; // Convert to 100th milliseconds
      if (delta <= 0) return; // Avoid division by zero
      // Update position based on velocity
      _xPosition += _xVelocity * delta;
      _yPosition += _yVelocity * delta;

      // Add friction
      _xVelocity *= 0.99;
      _yVelocity *= 0.99;

      // Bounce off the edges
      if (_xPosition < _minPositionX || _xPosition > _maxPositionX) {
        _xVelocity = -_xVelocity;
      }
      if (_yPosition < _minPositionY || _yPosition > _maxPositionY) {
        _yVelocity = -_yVelocity;
      }

      // Ensure the letter stays within bounds
      if (_xPosition < _minPositionX) _xPosition = _minPositionX;
      if (_xPosition > _maxPositionX) _xPosition = _maxPositionX;
      if (_yPosition < _minPositionY) _yPosition = _minPositionY;
      if (_yPosition > _maxPositionY) _yPosition = _maxPositionY;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(left: _xPosition, top: _yPosition, child: widget.child);
  }
}
