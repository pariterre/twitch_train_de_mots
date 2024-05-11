import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class SnowfallOverlay extends StatelessWidget {
  const SnowfallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: List.generate(
          100,
          (index) {
            // Generate random snowflake properties
            final size = Random().nextDouble() * 5;
            final opacity = Random().nextDouble() * 0.1 + 0.2;

            final xOffset =
                Random().nextDouble() * MediaQuery.of(context).size.width;
            final yOffset =
                Random().nextDouble() * MediaQuery.of(context).size.height;

            final xSpeed = (Random().nextDouble() - 0.5) * 2;
            final ySpeed = Random().nextDouble() * 0.2 + 1;

            return _Snowflake(
              size: size,
              opacity: opacity,
              initialXOffset: xOffset,
              initialYOffset: yOffset,
              xSpeed: xSpeed,
              ySpeed: ySpeed,
            );
          },
        ),
      ),
    );
  }
}

class _Snowflake extends StatefulWidget {
  const _Snowflake({
    required this.size,
    required this.initialXOffset,
    required this.initialYOffset,
    required this.xSpeed,
    required this.ySpeed,
    required this.opacity,
  });

  final double size;
  final double initialXOffset;
  final double initialYOffset;
  final double xSpeed;
  final double ySpeed;
  final double opacity;

  @override
  State<_Snowflake> createState() => _SnowflakeState();
}

class _SnowflakeState extends State<_Snowflake> {
  late double xOffset = widget.initialXOffset;
  late double yOffset = widget.initialYOffset;

  @override
  void initState() {
    super.initState();
    startFalling();
  }

  void startFalling() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        xOffset += widget.xSpeed;
        yOffset += widget.ySpeed;

        // Wrap around the screen
        if (xOffset > MediaQuery.of(context).size.width + widget.size) {
          xOffset = 0;
        }
        if (xOffset < -widget.size) {
          xOffset = MediaQuery.of(context).size.width;
        }
        if (yOffset > MediaQuery.of(context).size.height) {
          yOffset = -widget.size;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: xOffset,
      top: yOffset,
      child: Opacity(
        opacity: widget.opacity,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
