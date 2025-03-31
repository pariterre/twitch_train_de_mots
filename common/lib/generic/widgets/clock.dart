import 'dart:math';

import 'package:flutter/material.dart';

class Clock extends StatelessWidget {
  const Clock({
    super.key,
    required this.timeRemaining,
    required this.maxDuration,
    this.borderWidth = 0,
  });

  final Duration timeRemaining;
  final Duration maxDuration;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = min(constraints.maxHeight, constraints.maxWidth);

      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: timeRemaining.inMilliseconds > 0 ? 1 : 0,
              backgroundColor: const Color.fromARGB(255, 15, 75, 15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 100, 15, 15)),
              strokeWidth: size,
            ),
          ),
          SizedBox(
            width: size - borderWidth,
            height: size - borderWidth,
            child: CircularProgressIndicator(
              value:
                  1 - timeRemaining.inMilliseconds / maxDuration.inMilliseconds,
              backgroundColor: Colors.red[900],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              strokeWidth: size - borderWidth,
            ),
          )
        ],
      );
    });
  }
}
