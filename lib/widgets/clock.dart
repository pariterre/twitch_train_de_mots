import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:train_de_mots/models/custom_scheme.dart';

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
    return Consumer(builder: (context, ref, child) {
      final scheme = ref.watch(schemeProvider);

      return LayoutBuilder(builder: (context, constraints) {
        final size = min(constraints.maxHeight, constraints.maxWidth);

        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value:
                1 - timeRemaining.inMilliseconds / maxDuration.inMilliseconds,
            backgroundColor: Colors.red[900],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            strokeWidth: size,
          ),
        );
      });
    });
  }
}
