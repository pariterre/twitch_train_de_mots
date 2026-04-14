import 'package:common/warehouse_cleaning/models/avatar_agent.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class AvatarContainer extends StatefulWidget {
  const AvatarContainer({
    super.key,
    required this.avatar,
    required this.tileSize,
    required this.isGameOver,
    required this.clockTicker,
    required this.onAvatarSlingShoot,
  });

  final AvatarAgent avatar;
  final double tileSize;
  final bool isGameOver;
  final GenericListener<Function(Duration deltaTime)> clockTicker;
  final Function(AvatarAgent avatar, vector_math.Vector2 newVelocity)
      onAvatarSlingShoot;

  @override
  State<AvatarContainer> createState() => _AvatarContainerState();
}

class _AvatarContainerState extends State<AvatarContainer> {
  vector_math.Vector2 _previousPosition = vector_math.Vector2.zero();
  bool _isDragging = false;
  Offset? _dragStartPosition;
  Offset? _dragCurrentPosition;

  @override
  void initState() {
    super.initState();

    widget.clockTicker.listen(_clockTicked);
  }

  @override
  void dispose() {
    widget.clockTicker.cancel(_clockTicked);

    super.dispose();
  }

  void _clockTicked(Duration deltaTime) {
    if (!mounted) return;
    setState(() {});
  }

  ///
  /// Only allow dragging if not teleporting and not moving
  bool get _canBeDragged => !_cannotBeDragged;
  bool get _cannotBeDragged =>
      !widget.avatar.canBeSlingShot || widget.isGameOver;

  void _onDragStart(DragStartDetails details) {
    if (_isDragging) return;

    setState(() {
      _isDragging = true;
      // Start at the middle of the widget
      _dragStartPosition =
          Offset(widget.avatar.radius.x * 2, widget.avatar.radius.y * 2);
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
    final newVelocity = (_dragStartPosition! - _dragCurrentPosition!) * 2;
    widget.onAvatarSlingShoot(
        widget.avatar, vector_math.Vector2(newVelocity.dx, newVelocity.dy));

    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
      _dragCurrentPosition = null;
    });
  }

  vector_math.Vector2 _getAvatarPosition() {
    _previousPosition = widget.avatar.position;
    return _previousPosition;
  }

  @override
  Widget build(BuildContext context) {
    final position = _getAvatarPosition();

    final mainWidget = Container(
      width: widget.avatar.radius.x * 4,
      height: widget.avatar.radius.y * 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: Image.asset(
        'packages/common/assets/images/blueberry_war/blueberries.png',
        fit: BoxFit.cover,
      ),
    );

    return Positioned(
      left: position.x + widget.tileSize / 2 - 2 * widget.avatar.radius.x,
      top: position.y + widget.tileSize / 2 - 2 * widget.avatar.radius.y,
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
