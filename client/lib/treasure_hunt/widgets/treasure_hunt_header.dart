import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart';
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
  Duration _previousTimeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.treasureHunt;
    gm.onRoundStarted.listen(_onGameUpdated);
    gm.onGameUpdated.listen(_onGameUpdated);
    gm.onTileRevealed.listen(_onTileRevealed);
    gm.onRewardFound.listen(_onRewardFound);

    Managers.instance.tickerManager.onClockTicked.listen(_onClockTicked);
  }

  @override
  void dispose() {
    final gm = Managers.instance.miniGames.treasureHunt;
    gm.onRoundStarted.cancel(_onGameUpdated);
    gm.onGameUpdated.cancel(_onGameUpdated);
    gm.onTileRevealed.cancel(_onTileRevealed);
    gm.onRewardFound.cancel(_onRewardFound);

    Managers.instance.tickerManager.onClockTicked.cancel(_onClockTicked);

    super.dispose();
  }

  void _onGameUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  void _onClockTicked(Duration deltaTime) {
    final timeRemaining =
        Managers.instance.miniGames.treasureHunt.timeRemaining ?? Duration.zero;

    if (_previousTimeRemaining.inSeconds != timeRemaining.inSeconds) {
      _previousTimeRemaining = timeRemaining;
      setState(() {});
    }
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
    final thgm = Managers.instance.miniGames.treasureHunt;

    final timeRemaining = (thgm.timeRemaining?.isNegative ?? true)
        ? 0
        : thgm.timeRemaining!.inSeconds + 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 75.0),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ThemeCard(
                  child: Text(
                    'Temps restant: $timeRemaining',
                    style: tm.clientMainTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: tm.textColor),
                  ),
                ),
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
          ),
        ),
        const SizedBox(height: 12),
        const TreasureHuntLetterDisplayer(),
      ],
    );
  }
}
