import 'package:common/blueberry_war/models/blueberry_agent.dart';
import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/blueberry_war/widgets/blueberry_container.dart';
import 'package:common/blueberry_war/widgets/letter_container.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class BlueberryWarPlayingField extends StatelessWidget {
  const BlueberryWarPlayingField({
    super.key,
    required this.blueberries,
    required this.letters,
    required this.isGameOver,
    required this.clockTicker,
    required this.onBlueberrySlingShoot,
    this.drawBlueberryFieldOnly = false,
  });

  final List<BlueberryAgent> blueberries;
  final List<LetterAgent> letters;
  final bool isGameOver;
  final GenericListener clockTicker;
  final Function(BlueberryAgent blueberry, vector_math.Vector2 newVelocity)
      onBlueberrySlingShoot;
  final bool drawBlueberryFieldOnly;

  @override
  Widget build(BuildContext context) {
    final fieldSize = BlueberryWarConfig.fieldSize;
    final blueberryFieldSize = BlueberryWarConfig.blueberryFieldSize;

    return SizedBox(
      width: drawBlueberryFieldOnly ? blueberryFieldSize.x : fieldSize.x,
      height: fieldSize.y,
      child: Stack(
        children: [
          Positioned(
            left: blueberryFieldSize.x,
            child: SizedBox(
              height: fieldSize.y,
              child: VerticalDivider(
                thickness: 2,
                endIndent: 10,
                color: Colors.white.withAlpha(100),
              ),
            ),
          ),
          BlueberryWarFieldAgentsOverlay(
            blueberries: blueberries,
            letters: letters,
            isGameOver: isGameOver,
            clockTicker: clockTicker,
            onBlueberrySlingShoot: onBlueberrySlingShoot,
          ),
        ],
      ),
    );
  }
}

class BlueberryWarFieldAgentsOverlay extends StatelessWidget {
  const BlueberryWarFieldAgentsOverlay({
    super.key,
    required this.blueberries,
    required this.letters,
    required this.isGameOver,
    required this.clockTicker,
    required this.onBlueberrySlingShoot,
  });

  final List<BlueberryAgent> blueberries;
  final List<LetterAgent> letters;
  final bool isGameOver;
  final GenericListener clockTicker;
  final Function(BlueberryAgent blueberry, vector_math.Vector2 newVelocity)
      onBlueberrySlingShoot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ...blueberries.map((e) => BlueberryContainer(
            blueberry: e,
            isGameOver: isGameOver,
            clockTicker: clockTicker,
            onBlueberrySlingShoot: onBlueberrySlingShoot)),
        ...letters
            .map((e) => LetterContainer(letter: e, clockTicker: clockTicker)),
      ],
    );
  }
}
