import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/managers/blueberry_war_game_manager.dart';
import 'package:train_de_mots/blueberry_war/models/player_agent.dart';
import 'package:train_de_mots/blueberry_war/to_remove/any_dumb_stuff.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class PlayerContainer extends StatefulWidget {
  const PlayerContainer({super.key, required this.player});

  final PlayerAgent player;

  @override
  State<PlayerContainer> createState() => _PlayerContainerState();
}

class _PlayerContainerState extends State<PlayerContainer> {
  vector_math.Vector2 previousPosition = vector_math.Vector2.zero();
  bool _isBeingDestroyed = false;
  bool _isDragging = false;
  Offset? _dragStartPosition;
  Offset? _dragCurrentPosition;

  DateTime? _fadingStartTime;
  bool get _isFading => _fadingStartTime != null;
  double _fadeAnimationProgress = 0.0;

  BlueberryWarGameManager get _gm => Managers.instance.miniGames.blueberryWar;

  @override
  void initState() {
    super.initState();

    widget.player.onTeleport.listen(_hasStartedTeleporting);
    widget.player.onDestroyed.listen(_hasBeenDestroyed);
    _gm.onClockTicked.listen(_clockTicked);
  }

  @override
  void dispose() {
    widget.player.onTeleport.cancel(_hasStartedTeleporting);
    widget.player.onDestroyed.cancel(_hasBeenDestroyed);
    _gm.onClockTicked.cancel(_clockTicked);

    super.dispose();
  }

  void _hasBeenDestroyed() {
    setState(() {
      _isBeingDestroyed = true;
      _isDragging = false;
      _fadingStartTime = DateTime.now();
      _fadeAnimationProgress = 0.0;
    });
  }

  void _hasStartedTeleporting(
    vector_math.Vector2 from,
    vector_math.Vector2 to,
  ) {
    setState(() {
      _isDragging = false;
      _fadingStartTime = DateTime.now();
      _fadeAnimationProgress = 0.0;
    });
  }

  void _performFading() {
    if (!_isFading) return;
    final elapsedTime = DateTime.now().difference(_fadingStartTime!);

    _fadeAnimationProgress =
        elapsedTime.inMilliseconds / _gm.teleportationDuration.inMilliseconds;
    if (_fadeAnimationProgress >= 1.0 && _isBeingDestroyed) {
      _fadingStartTime = null;
    } else if (_fadeAnimationProgress >= 2.0) {
      _fadingStartTime = null;
      _fadeAnimationProgress = 0.0;
    }
  }

  void _clockTicked() {
    _performFading();
    setState(() {});
  }

  ///
  /// Only allow dragging if not teleporting and not moving
  bool get _canBeDragged => !_cannotBeDragged;
  bool get _cannotBeDragged =>
      _isFading ||
      widget.player.velocity.length2 > _gm.velocityThresholdSquared ||
      _gm.isGameOver;

  void _onDragStart(DragStartDetails details) {
    if (_isDragging) return;

    setState(() {
      _isDragging = true;
      // Start at the middle of the widget
      _dragStartPosition = Offset(
        widget.player.radius.x,
        widget.player.radius.y,
      );
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragCurrentPosition = details.localPosition;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _dragCurrentPosition = details.localPosition;
    final newVelocity = (_dragStartPosition! - _dragCurrentPosition!) * 10;

    // Ensure the velocity is within a reasonable range
    final maxVelocity = 2000.0;
    double scale = 1.0;
    if (newVelocity.distance > maxVelocity) {
      scale = maxVelocity / newVelocity.distance;
    }
    widget.player.velocity = vector_math.Vector2(
      newVelocity.dx * scale,
      newVelocity.dy * scale,
    );

    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
      _dragCurrentPosition = null;
    });
  }

  vector_math.Vector2 _getPlayerPosition() {
    if (!_isFading || _fadeAnimationProgress >= 1.0) {
      previousPosition = widget.player.position - widget.player.radius;
    }
    return previousPosition;
  }

  int _computeAlpha() {
    if (!_isFading) return 255;
    if (_fadeAnimationProgress <= 1.0) {
      // Fade out before teleporting
      return ((1.0 - _fadeAnimationProgress) * 255).toInt();
    } else {
      // Fade in after teleporting
      return ((_fadeAnimationProgress - 1.0) * 255.0).toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _getPlayerPosition();
    final alpha = _computeAlpha();

    if (widget.player.isDestroyed && !_isFading) {
      return const SizedBox.shrink();
    }

    final mainWidget = Container(
      width: widget.player.radius.x * 2,
      height: widget.player.radius.y * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.player.isDestroyed
            ? Colors.red.withAlpha(alpha)
            : Colors.blue.withAlpha(alpha),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withAlpha(alpha), width: 2.0),
      ),
    );

    return Positioned(
      left: position.x,
      top: position.y,
      child: Stack(
        children: [
          _canBeDragged
              ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onVerticalDragStart: _onDragStart,
                    onHorizontalDragStart: _onDragStart,
                    onVerticalDragUpdate: _onDragUpdate,
                    onHorizontalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    onHorizontalDragEnd: _onDragEnd,
                    child: mainWidget,
                  ),
                )
              : mainWidget,
          if (_isDragging)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: DragLinePainter(
                    start: _dragStartPosition,
                    current: _dragCurrentPosition,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DragLinePainter extends CustomPainter {
  final Offset? start;
  final Offset? current;

  DragLinePainter({this.start, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || current == null) return;

    final paint = Paint()
      ..color = const Color.fromARGB(255, 15, 37, 48)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start!, current!, paint);
  }

  @override
  bool shouldRepaint(covariant DragLinePainter oldDelegate) {
    return start != oldDelegate.start || current != oldDelegate.current;
  }
}
