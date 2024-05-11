import 'package:flutter/material.dart';

class GrowingWidget extends StatefulWidget {
  const GrowingWidget(
      {super.key,
      required this.child,
      required this.growingFactor,
      this.duration = const Duration(milliseconds: 500)});

  final Widget child;
  final double growingFactor;
  final Duration duration;

  @override
  State<GrowingWidget> createState() => _GrowingWidgetState();
}

class _GrowingWidgetState extends State<GrowingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);
  late Animation<double> _animation = _animation =
      Tween<double>(begin: 1, end: widget.growingFactor).animate(_controller);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        child: widget.child,
        builder: (context, child) {
          return Transform.scale(
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            scale: _animation.value,
            child: child,
          );
        });
  }
}
