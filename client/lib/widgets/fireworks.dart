import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _logger = Logger('Fireworks');

class FireworksController {
  final key = UniqueKey();

  Color minColor;
  Color maxColor;
  bool isHuge;

  FireworksController({
    this.isHuge = false,
    this.minColor = const Color.fromARGB(185, 0, 155, 0),
    this.maxColor = const Color.fromARGB(185, 255, 255, 50),
    this.explodeOnTap = true,
  });

  void trigger() {
    if (_explode != null) _explode!(isHuge);
  }

  void triggerReversed() {
    if (_explode != null) _explode!(isHuge, isReversed: true);
  }

  void dispose() {
    _explode = null;
  }

  bool explodeOnTap;

  Color get color {
    final rand = Random();
    final alpha =
        minColor.alpha + rand.nextInt(maxColor.alpha - minColor.alpha + 1);
    final red = minColor.red + rand.nextInt(maxColor.red - minColor.red + 1);
    final green =
        minColor.green + rand.nextInt(maxColor.green - minColor.green + 1);
    final blue =
        minColor.blue + rand.nextInt(maxColor.blue - minColor.blue + 1);

    return Color.fromARGB(alpha, red, green, blue);
  }

  Function(bool isHuge, {bool isReversed})? _explode;
}

class Fireworks extends StatefulWidget {
  const Fireworks({super.key, required this.controller});

  final FireworksController controller;

  @override
  State createState() => _FireworksState();
}

class _FireworksState extends State<Fireworks> with TickerProviderStateMixin {
  bool _isReversed = false;
  late AnimationController _animationController;
  List<_Particle> particles = [];
  final int numParticles = 100;

  @override
  void initState() {
    super.initState();
    _logger.info('New fireworks initialized');

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));

    _animationController.addListener(() {
      updateParticles();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _logger.info('Fireworks disposed');

    _animationController.dispose();
    super.dispose();

    widget.controller.dispose();
  }

  void updateParticles() {
    _logger.finer('Fireworks updating...');
    final explosion = 1 - pow(1 - _animationController.value, 4);

    for (var particle in particles) {
      // Find the final position after the explosion
      final dx = cos(particle.angle) *
          particle.speed *
          _animationController.duration!.inMilliseconds;
      final dy = sin(particle.angle) *
          particle.speed *
          _animationController.duration!.inMilliseconds;

      particle.x = particle.xInitial + dx * explosion;
      particle.y = particle.yInitial + dy * explosion;

      final visibilityDecay =
          pow(particle.visibilityTime - _animationController.value, 3);
      particle.radius = particle.radiusInitial * visibilityDecay;
    }

    particles.removeWhere((particle) =>
        _isReversed ? _animationController.value == 0 : particle.radius <= 0);
  }

  late BoxConstraints _constraints;

  void _explode(bool huge, {bool isReversed = false}) {
    _logger.info('Fireworks exploding');
    final rand = Random();

    particles.clear();
    particles.addAll(List.generate(
      numParticles,
      (_) => _Particle(
          x: _constraints.maxWidth / 2,
          y: _constraints.maxHeight / 2,
          radius: 10 + rand.nextDouble() * 100,
          angle: rand.nextDouble() * 2 * pi,
          speed: rand.nextDouble() * (huge ? 0.650 : 0.350),
          visibilityTime: (_animationController.duration!.inMilliseconds -
                  (rand.nextDouble() * 0.5 + 0.5) *
                      (_animationController.duration!.inMilliseconds *
                          (huge ? 0.5 : 0.7))) /
              _animationController.duration!.inMilliseconds,
          color: widget.controller.color),
    ));

    if (isReversed) {
      _isReversed = true;
      _animationController.reverse(from: 1);
    } else {
      _isReversed = false;
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is a bit overkill to always update the controller's explode function
    // but because it is a StatefulWidget, it is not possible to access otherwise
    widget.controller._explode = _explode;

    return GestureDetector(
      onTap: widget.controller.explodeOnTap
          ? () => _explode(widget.controller.isHuge, isReversed: false)
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _constraints = constraints;

          return CustomPaint(
            painter: _FireworksPainter(particles),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  double x;
  double xInitial;
  double y;
  double yInitial;
  double radius;
  double radiusInitial;
  double angle;
  double speed;
  double visibilityTime;
  Color color;

  final rand = Random();
  late final Paint _painter = Paint()..color = color;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.angle,
    required this.speed,
    required this.visibilityTime,
    required this.color,
  })  : xInitial = x,
        yInitial = y,
        radiusInitial = radius;
}

class _FireworksPainter extends CustomPainter {
  final List<_Particle> particles;
  final rand = Random();

  _FireworksPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.radius,
        particle._painter,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
