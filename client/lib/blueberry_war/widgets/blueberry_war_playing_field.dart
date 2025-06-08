import 'package:flutter/material.dart';
import 'package:train_de_mots/blueberry_war/to_remove/any_dumb_stuff.dart';
import 'package:train_de_mots/blueberry_war/widgets/letter_container.dart';
import 'package:train_de_mots/blueberry_war/widgets/player_container.dart';

class BlueberryWarPlayingField extends StatelessWidget {
  const BlueberryWarPlayingField({super.key});

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.miniGames.blueberryWar;

    return Stack(
      children: [
        ...gm.players.map((e) => PlayerContainer(player: e)),
        ...gm.letters.map((e) => LetterContainer(letter: e)),
      ],
    );
  }
}
