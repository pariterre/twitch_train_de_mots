import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/generic/widgets/theme_card.dart';
import 'package:train_de_mots/warehouse_cleaning/widgets/warehouse_cleaning_letter_displayer.dart';

class WarehouseCleaningHeader extends StatefulWidget {
  const WarehouseCleaningHeader({super.key});

  @override
  State<WarehouseCleaningHeader> createState() =>
      _WarehouseCleaningHeaderState();
}

class _WarehouseCleaningHeaderState extends State<WarehouseCleaningHeader> {
  int _previousTimeRemainingInSeconds = 0;

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.warehouseCleaning;
    gm.onGameStarted.listen(_onGameStarted);
    gm.onAvatarMoved.listen(_refresh);
    gm.onLetterFound.listen(_onRewardFound);

    Managers.instance.tickerManager.onClockTicked.listen(_onClockTicked);
  }

  @override
  void dispose() {
    final gm = Managers.instance.miniGames.warehouseCleaning;
    gm.onGameStarted.cancel(_refresh);
    gm.onLetterFound.cancel(_onRewardFound);

    Managers.instance.tickerManager.onClockTicked.cancel(_onClockTicked);

    super.dispose();
  }

  void _onGameStarted() {
    setState(() {});
  }

  void _onClockTicked(Duration deltaTime) {
    if (_previousTimeRemainingInSeconds !=
        Managers.instance.miniGames.warehouseCleaning.timeRemaining.inSeconds) {
      _previousTimeRemainingInSeconds =
          Managers.instance.miniGames.warehouseCleaning.timeRemaining.inSeconds;
      setState(() {});
    }
  }

  void _refresh() {
    if (!mounted) return;
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 75.0),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ThemeCard(
                  child: Text(
                    'Temps restant: ${Managers.instance.miniGames.warehouseCleaning.timeRemaining.inSeconds}',
                    style: tm.clientMainTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: tm.textColor),
                  ),
                ),
                ThemeCard(
                  child: Text(
                    'Essais restants: ${Managers.instance.miniGames.warehouseCleaning.triesRemaining}',
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
        const WarehouseCleaningLetterDisplayer(),
      ],
    );
  }
}
