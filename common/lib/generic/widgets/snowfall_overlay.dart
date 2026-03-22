import 'dart:math';

import 'package:flutter/material.dart';

class SnowfallOverlay extends StatefulWidget {
  const SnowfallOverlay({super.key, required this.snowFlakeCount});

  final int snowFlakeCount;

  @override
  State<SnowfallOverlay> createState() => _SnowfallOverlayState();
}

class _SnowfallOverlayState extends State<SnowfallOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_SnowflakeData> _flakes = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    // TODO: Find how to trigger this
    if (_flakes.length != widget.snowFlakeCount) {
      final random = Random();
      _flakes.clear();
      _flakes.addAll(List.generate(widget.snowFlakeCount, (_) {
        return _SnowflakeData(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 5,
          speedY: (random.nextDouble() * 0.2 + 0.1) * 0.1,
          speedX: ((random.nextDouble() - 0.5) * 0.2) * 0.1,
          opacity: random.nextDouble() * 0.3 + 0.2,
        );
      }));
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SnowPainter(_flakes, _controller),
      size: Size.infinite,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SnowPainter extends CustomPainter {
  final List<_SnowflakeData> _flakes;
  final AnimationController controller;

  _SnowPainter(this._flakes, this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final elapsed =
        (controller.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
    for (final flake in _flakes) {
      final dx = (flake.x * size.width + elapsed * flake.speedX * size.width) %
          size.width;
      final dy =
          (flake.y * size.height + elapsed * flake.speedY * size.height) %
              size.height;
      paint.color = Colors.white.withAlpha((flake.opacity * 255).toInt());

      canvas.drawCircle(
        Offset(dx, dy),
        flake.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SnowflakeData {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;

  _SnowflakeData({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}
