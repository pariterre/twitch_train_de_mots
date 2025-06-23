import 'package:common/blueberry_war/models/letter_agent.dart';
import 'package:common/blueberry_war/models/player_agent.dart';
import 'package:common/generic/models/generic_listener.dart';
import 'package:flutter/material.dart';
import 'package:common/blueberry_war/widgets/letter_container.dart';
import 'package:common/blueberry_war/widgets/player_container.dart';

class BlueberryWarPlayingField extends StatelessWidget {
  const BlueberryWarPlayingField(
      {super.key,
      required this.players,
      required this.letters,
      required this.isGameOver,
      required this.onClockTicked});

  final List<PlayerAgent> players;
  final List<LetterAgent> letters;
  final bool isGameOver;
  final GenericListener onClockTicked;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ...players.map((e) => PlayerContainer(
            player: e, isGameOver: isGameOver, onClockTicked: onClockTicked)),
        ...letters.map(
            (e) => LetterContainer(letter: e, onClockTicked: onClockTicked)),
      ],
    );
  }
}
