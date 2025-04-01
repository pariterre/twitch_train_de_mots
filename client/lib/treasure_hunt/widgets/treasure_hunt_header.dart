import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/treasure_hunt/treasure_hunt_grid.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/theme_card.dart';
import 'package:train_de_mots/treasure_hunt/widgets/treasure_hunt_letter_displayer.dart';

class TreasureHuntHeader extends StatefulWidget {
  const TreasureHuntHeader({super.key});

  @override
  State<TreasureHuntHeader> createState() => _TreasureHuntHeaderState();
}

class _TreasureHuntHeaderState extends State<TreasureHuntHeader> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.treasureHunt;
    gm.onGameStarted.listen(_onGameStarted);
    gm.onClockTicked.listen(_onClockTicked);
    gm.onTileRevealed.listen(_onTileRevealed);
    gm.onRewardFound.listen(_onRewardFound);
  }

  @override
  void dispose() {
    final gm = Managers.instance.miniGames.treasureHunt;
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

  void _onTileRevealed(Tile tile) {
    setState(() {});
  }

  void _onRewardFound(Tile tile) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tm = ThemeManager.instance;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemeCard(
              child: Text(
                'Temps restant: ${Managers.instance.miniGames.treasureHunt.timeRemaining.inSeconds}',
                style: tm.clientMainTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: tm.textColor),
              ),
            ),
            const SizedBox(width: 100),
            ThemeCard(
              child: Text(
                'Essais restants: ${Managers.instance.miniGames.treasureHunt.triesRemaining}',
                style: tm.clientMainTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: tm.textColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const TreasureHuntLetterDisplayer(),
      ],
    );
  }
}
