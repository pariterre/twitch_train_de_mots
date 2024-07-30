import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:train_de_mots/managers/theme_manager.dart';
import 'package:train_de_mots/widgets/snowfall_overlay.dart';

final _logger = Logger('Background');

class Background extends StatefulWidget {
  const Background({super.key, this.child, this.withSnowfall = true});

  final bool withSnowfall;
  final Widget? child;

  @override
  State<Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<Background>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Decoration> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: true);

    final tm = ThemeManager.instance;
    tm.onChanged.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller.dispose();

    final tm = ThemeManager.instance;
    tm.onChanged.removeListener(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});

  void setupAnimation() {
    _logger.info('Setting up animation...');

    final tm = ThemeManager.instance;

    _animation = DecorationTween(
      begin: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomLeft,
            colors: [
              tm.backgroundColorLight,
              tm.backgroundColorDark,
            ]),
      ),
      end: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tm.backgroundColorLight,
              tm.backgroundColorDark,
            ]),
      ),
    ).animate(_controller);

    _logger.info('Animation set up.');
  }

  @override
  Widget build(BuildContext context) {
    setupAnimation();

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: _animation.value,
              height: MediaQuery.of(context).size.height,
            );
          },
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Image.asset(
            'assets/images/splash_screen.png',
            height: MediaQuery.of(context).size.height,
            opacity: const AlwaysStoppedAnimation(0.05),
            fit: BoxFit.cover,
          ),
        ),
        if (widget.withSnowfall) const SnowfallOverlay(),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
