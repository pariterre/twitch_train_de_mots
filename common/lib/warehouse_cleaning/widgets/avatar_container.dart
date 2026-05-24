import 'package:common/warehouse_cleaning/models/avatar_agent.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class AvatarContainer extends StatefulWidget {
  const AvatarContainer({
    super.key,
    required this.avatar,
    required this.tileSize,
    required this.isRoundInProgress,
    required this.clockTicker,
    required this.onAvatarSlingShot,
  });

  final AvatarAgent avatar;
  final double tileSize;
  final bool isRoundInProgress;
  final GenericListener<Function(Duration deltaTime)> clockTicker;
  final Function(AvatarAgent avatar, vector_math.Vector2 newVelocity)
      onAvatarSlingShot;

  @override
  State<AvatarContainer> createState() => _AvatarContainerState();
}

class _AvatarContainerState extends State<AvatarContainer> {
  bool _isDragging = false;
  Offset? _dragStartPosition;
  Offset? _dragCurrentPosition;
  late vector_math.Vector2 _previousPosition = widget.avatar.position;

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
    if (_getPosition()) {
      setState(() {});
    }
  }

  ///
  /// Only allow dragging if not teleporting and not moving
  bool get _canBeDragged => !_cannotBeDragged;
  bool get _cannotBeDragged =>
      !widget.avatar.canBeSlingShot || !widget.isRoundInProgress;

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
    widget.onAvatarSlingShot(
        widget.avatar, vector_math.Vector2(newVelocity.dx, newVelocity.dy));

    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
      _dragCurrentPosition = null;
    });
  }

  bool _getPosition() {
    final newPosition = widget.avatar.position;
    if (_previousPosition != newPosition) {
      _previousPosition = newPosition;
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = widget.avatar.radius * 4;

    final mainWidget = Container(
      width: avatarSize.x,
      height: avatarSize.y,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: Image.asset(
        'packages/common/assets/images/blueberry_war/blueberries.png',
        cacheWidth: avatarSize.x.toInt(),
        cacheHeight: avatarSize.y.toInt(),
        fit: BoxFit.cover,
      ),
    );

    return Positioned(
      left: _previousPosition.x +
          widget.tileSize / 2 -
          2 * widget.avatar.radius.x,
      top: _previousPosition.y +
          widget.tileSize / 2 -
          2 * widget.avatar.radius.y,
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
