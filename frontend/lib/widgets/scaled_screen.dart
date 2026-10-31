import 'package:flutter/material.dart';

/// Lays out [child] on a virtual canvas of [designWidth] logical pixels and
/// scales it to fill the space left under [header], so the content keeps the
/// same proportions regardless of the screen size. The [header] keeps its
/// natural size and only shrinks if it is too wide.
class ScaledScreen extends StatelessWidget {
  const ScaledScreen({
    super.key,
    this.header,
    required this.child,
    this.designWidth = 450.0,
    this.alignment = Alignment.center,
  });

  final Widget? header;
  final Widget child;
  final double designWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (header != null) FittedBox(fit: BoxFit.scaleDown, child: header),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            // The FittedBox must be given tight constraints, otherwise it only
            // shrinks its child and never enlarges it
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: alignment,
                child: SizedBox(width: designWidth, child: child),
              ),
            );
          }),
        ),
      ],
    );
  }
}
