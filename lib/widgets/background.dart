import 'package:flutter/material.dart';
import 'package:train_de_mots/models/color_scheme.dart';

class Background extends StatefulWidget {
  const Background({super.key, this.child});

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
      duration: const Duration(seconds: 60),
    )..repeat(reverse: true);

    _animation = DecorationTween(
      begin: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomLeft,
            colors: [
              CustomColorScheme.instance.backgroundColorLight,
              CustomColorScheme.instance.backgroundColorDark,
            ]),
      ),
      end: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CustomColorScheme.instance.backgroundColorLight,
              CustomColorScheme.instance.backgroundColorDark,
            ]),
      ),
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
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
        if (widget.child != null) widget.child!,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
