import 'package:common/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/treasure_hunt/managers/treasure_hunt_game_manager.dart';
import 'package:train_de_mots/treasure_hunt/models/tile.dart';
import 'package:train_de_mots/treasure_hunt/widgets/letter_displayer.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  void initState() {
    super.initState();

    final gm = TreasureHuntGameManager.instance;
    gm.onGameStarted.listen(_onGameStarted);
    gm.onClockTicked.listen(_onClockTicked);
    gm.onTileRevealed.listen(_onTileRevealed);
    gm.onRewardFound.listen(_onRewardFound);
  }

  @override
  void dispose() {
    final gm = TreasureHuntGameManager.instance;
    gm.onGameStarted.cancel(_onGameStarted);
    gm.onClockTicked.cancel(_onClockTicked);
    gm.onTileRevealed.cancel(_onTileRevealed);
    gm.onRewardFound.cancel(_onRewardFound);

    super.dispose();
  }

  void _onGameStarted() {
    setState(() {});
  }

  void _onClockTicked(Duration timeRemaining) {
    setState(() {});
  }

  void _onTileRevealed() {
    setState(() {});
  }

  void _onRewardFound(Tile tile) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Temps restant: ${TreasureHuntGameManager.instance.timeRemaining.inSeconds}',
              style: ThemeManager.instance.textFrontendSc,
            ),
            Text(
              'Essais restants: ${TreasureHuntGameManager.instance.triesRemaining}',
              style: ThemeManager.instance.textFrontendSc,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const LetterDisplayer(),
      ],
    );
  }
}
