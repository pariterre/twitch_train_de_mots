import 'dart:math';

import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/generic/models/serializable_game_state.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/theme_card.dart';

class BlueberryWarHeader extends StatefulWidget {
  const BlueberryWarHeader({super.key});

  @override
  State<BlueberryWarHeader> createState() => _BlueberryWarHeaderState();
}

class _BlueberryWarHeaderState extends State<BlueberryWarHeader> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onClockTicked.listen(_onClockTicked);
  }

  @override
  void dispose() {
    final gm = Managers.instance.miniGames.blueberryWar;
    gm.onClockTicked.cancel(_onClockTicked);

    super.dispose();
  }

  void _onClockTicked() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;
    final gm = Managers.instance.miniGames.blueberryWar;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ThemeCard(
          child: Text(
            'Temps restant: ${max(Managers.instance.miniGames.blueberryWar.timeRemaining.inSeconds, 0)}',
            style: tm.clientMainTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: tm.textColor,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...gm.problem.letters.asMap().keys.map(
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      gm.problem.hiddenLetterStatuses[index] ==
                              LetterStatus.hidden
                          ? '_'
                          : gm.problem.letters[index],
                      style: TextStyle(fontSize: 30),
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
