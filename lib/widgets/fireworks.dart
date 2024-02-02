import 'package:flutter/material.dart';
import 'dart:math';

class FireworksController {
  final key = UniqueKey();

  Color minColor;
  Color maxColor;
  bool huge;

  FireworksController({
    this.huge = false,
    this.minColor = const Color.fromARGB(185, 0, 155, 0),
    this.maxColor = const Color.fromARGB(185, 255, 255, 50),
  });

  void trigger() {
    if (_explode != null) _explode!(huge);
  }

  void dispose() {
    _explode = null;
  }

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

  Function? _explode;
}

class Fireworks extends StatefulWidget {
  const Fireworks({super.key, required this.controller});

  final FireworksController controller;

  @override
  State createState() => _FireworksState();
}

class _FireworksState extends State<Fireworks> with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<_Particle> particles = [];
  final int numParticles = 100;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _animationController.addListener(() {
      updateParticles();
      setState(() {});
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();

    widget.controller.dispose();
  }

  void updateParticles() {
    for (var particle in particles) {
      final double dx = cos(particle.angle) * particle.speed;
      final double dy = sin(particle.angle) * particle.speed / 1.5;

      particle.x += dx;
      particle.y += dy;
      particle.radius -= particle.decaySpeed;
    }

    particles.removeWhere((particle) => particle.radius <= 0);
  }

  late BoxConstraints _constraints;

  void _explode(bool huge) {
    final rand = Random();

    setState(() {
      particles.addAll(List.generate(
        numParticles,
        (_) => _Particle(
            x: _constraints.maxWidth / 2,
            y: _constraints.maxHeight / 2,
            radius: 10 + rand.nextDouble() * 10,
            angle: rand.nextDouble() * 2 * pi,
            speed: rand.nextDouble() * (huge ? 10 : 6),
            decaySpeed: (rand.nextDouble() * 0.5 + 0.5) / (huge ? 3 : 2),
            color: widget.controller.color),
      ));
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // This is a bit overkill to always update the controller's explode function
    // but because it is a StatefulWidget, it is not possible to access otherwise
    widget.controller._explode = _explode;

    return GestureDetector(
      onTap: () => _explode(widget.controller.huge),
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
  double y;
  double radius;
  double angle;
  double speed;
  double decaySpeed;
  Color color;

  final rand = Random();
  late final Paint _painter = Paint()..color = color;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.angle,
    required this.speed,
    required this.decaySpeed,
    required this.color,
  });
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
