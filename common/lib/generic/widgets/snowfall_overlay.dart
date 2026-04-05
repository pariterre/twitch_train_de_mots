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
  late final _ticker = createTicker(_updateSnowflakes);
  Duration _previousElapsedTime = Duration.zero;
  final List<_SnowflakeData> _flakes = [];

  @override
  void initState() {
    super.initState();

    _prepareSnowflakes();
    _ticker.start();
  }

  @override
  void didUpdateWidget(covariant SnowfallOverlay oldWidget) {
    if (oldWidget.snowFlakeCount != widget.snowFlakeCount) {
      _prepareSnowflakes();
    }

    super.didUpdateWidget(oldWidget);
  }

  void _updateSnowflakes(Duration elapsed) {
    final dt = (elapsed - _previousElapsedTime).inMilliseconds / 1000.0;
    _previousElapsedTime = elapsed;

    for (final flake in _flakes) {
      flake.x = (flake.x + flake.speedX * dt) % 1.0;
      flake.y = (flake.y + flake.speedY * dt) % 1.0;
    }

    setState(() {});
  }

  void _prepareSnowflakes() {
    final random = Random();
    if (_flakes.length < widget.snowFlakeCount) {
      _flakes.addAll(List.generate(widget.snowFlakeCount - _flakes.length, (_) {
        return _SnowflakeData(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 5 / 1700,
          speedY: (random.nextDouble() * 0.2 + 0.1) * 0.1,
          speedX: ((random.nextDouble() - 0.5) * 0.2) * 0.1,
          opacity: random.nextDouble() * 0.3 + 0.2,
        );
      }));
    } else if (_flakes.length > widget.snowFlakeCount) {
      _flakes.removeRange(widget.snowFlakeCount, _flakes.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.snowFlakeCount == 0) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _SnowPainter(_flakes),
      size: Size.infinite,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class _SnowPainter extends CustomPainter {
  final List<_SnowflakeData> _flakes;

  _SnowPainter(this._flakes) : super(repaint: null);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final flake in _flakes) {
      paint.color = Colors.white.withAlpha((flake.opacity * 255).toInt());
      canvas.drawCircle(
        Offset(flake.x * size.width, flake.y * size.height),
        flake.size * size.width,
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
