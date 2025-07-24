import 'package:common/blueberry_war/models/blueberry_war_game_manager_helpers.dart';
import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/blueberry_war/models/player_agent.dart';
import 'package:common/blueberry_war/widgets/letter_container.dart';
import 'package:common/blueberry_war/widgets/player_container.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

class BlueberryWarPlayingField extends StatelessWidget {
  const BlueberryWarPlayingField({
    super.key,
    required this.players,
    required this.letters,
    required this.isGameOver,
    required this.clockTicker,
    required this.onPlayerSlingShoot,
  });

  final List<PlayerAgent> players;
  final List<LetterAgent> letters;
  final bool isGameOver;
  final GenericListener clockTicker;
  final Function(PlayerAgent player, vector_math.Vector2 newVelocity)
      onPlayerSlingShoot;

  @override
  Widget build(BuildContext context) {
    final fieldSize = BlueberryWarGameManagerHelpers.fieldSize;

    return SizedBox(
      width: fieldSize.x,
      height: fieldSize.y,
      child: Stack(
        children: [
          Positioned(
            left: fieldSize.x / 5,
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
            players: players,
            letters: letters,
            isGameOver: isGameOver,
            clockTicker: clockTicker,
            onPlayerSlingShoot: onPlayerSlingShoot,
          ),
        ],
      ),
    );
  }
}

class BlueberryWarFieldAgentsOverlay extends StatelessWidget {
  const BlueberryWarFieldAgentsOverlay({
    super.key,
    required this.players,
    required this.letters,
    required this.isGameOver,
    required this.clockTicker,
    required this.onPlayerSlingShoot,
  });

  final List<PlayerAgent> players;
  final List<LetterAgent> letters;
  final bool isGameOver;
  final GenericListener clockTicker;
  final Function(PlayerAgent player, vector_math.Vector2 newVelocity)
      onPlayerSlingShoot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ...players.map((e) => PlayerContainer(
            player: e,
            isGameOver: isGameOver,
            clockTicker: clockTicker,
            onPlayerSlingShoot: onPlayerSlingShoot)),
        ...letters
            .map((e) => LetterContainer(letter: e, clockTicker: clockTicker)),
      ],
    );
  }
}
