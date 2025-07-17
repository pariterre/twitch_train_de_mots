import 'package:common/blueberry_war/models/player_agent.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class PlayerContainer extends StatefulWidget {
  const PlayerContainer({
    super.key,
    required this.player,
    required this.isGameOver,
    required this.clockTicker,
    required this.onPlayerSlingShoot,
  });

  final PlayerAgent player;
  final bool isGameOver;
  final GenericListener clockTicker;
  final Function(PlayerAgent player, vector_math.Vector2 newVelocity)
      onPlayerSlingShoot;

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

  final teleportationDuration = const Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();

    widget.player.onTeleport.listen(_hasStartedTeleporting);
    widget.player.onDestroyed.listen(_hasBeenDestroyed);
    widget.clockTicker.listen(_clockTicked);
  }

  @override
  void dispose() {
    widget.player.onTeleport.cancel(_hasStartedTeleporting);
    widget.player.onDestroyed.cancel(_hasBeenDestroyed);
    widget.clockTicker.cancel(_clockTicked);

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
    final elapsedTime = DateTime.now().difference(_fadingStartTime!);

    _fadeAnimationProgress =
        elapsedTime.inMilliseconds / teleportationDuration.inMilliseconds;
    if (_fadeAnimationProgress >= 1.0 && _isBeingDestroyed) {
      _fadingStartTime = null;
    } else if (_fadeAnimationProgress >= 2.0) {
      _fadingStartTime = null;
      _fadeAnimationProgress = 0.0;
    }
  }

  void _clockTicked() {
    if (_isFading) _performFading();
    setState(() {});
  }

  ///
  /// Only allow dragging if not teleporting and not moving
  bool get _canBeDragged => !_cannotBeDragged;
  bool get _cannotBeDragged =>
      _isFading || widget.player.canBeSlingShot || widget.isGameOver;

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
    widget.onPlayerSlingShoot(
        widget.player, vector_math.Vector2(newVelocity.dx, newVelocity.dy));

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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: Image.asset(
        'packages/common/assets/images/blueberry_war/blueberries.png',
        fit: BoxFit.cover,
        opacity: AlwaysStoppedAnimation<double>(
          alpha / 255.0,
        ),
        color:
            widget.player.isDestroyed ? Color.fromARGB(alpha, 255, 0, 0) : null,
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
