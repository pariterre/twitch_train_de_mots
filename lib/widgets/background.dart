import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';

class Background extends ConsumerStatefulWidget {
  const Background({super.key, this.child});

  final Widget? child;

  @override
  ConsumerState<Background> createState() => _BackgroundState();
}

class _BackgroundState extends ConsumerState<Background>
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
  }

  void setupAnimation() {
    final scheme = ref.watch(schemeProvider);

    _animation = DecorationTween(
      begin: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomLeft,
            colors: [
              scheme.backgroundColorLight,
              scheme.backgroundColorDark,
            ]),
      ),
      end: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.backgroundColorLight,
              scheme.backgroundColorDark,
            ]),
      ),
    ).animate(_controller);
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
