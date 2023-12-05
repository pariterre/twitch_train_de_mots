import 'dart:math';

import 'package:flutter/material.dart';

class Clock extends StatelessWidget {
  const Clock({
    super.key,
    required this.timeRemaining,
    required this.maxDuration,
  });

  final Duration timeRemaining;
  final Duration maxDuration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = min(constraints.maxHeight, constraints.maxWidth);

      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          value: 1 - timeRemaining.inMilliseconds / maxDuration.inMilliseconds,
          backgroundColor: Colors.red[900],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          strokeWidth: size,
        ),
      );
    });
  }
}
