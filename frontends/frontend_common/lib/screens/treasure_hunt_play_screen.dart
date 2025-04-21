import 'package:common/generic/managers/theme_manager.dart';
import 'package:common/treasure_hunt/models/serializable_treasure_hunt_game_state.dart';
import 'package:common/treasure_hunt/widgets/treasure_hunt_game_grid.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';
import 'package:frontend_common/managers/twitch_manager.dart';

class TreasureHuntPlayScreen extends StatefulWidget {
  const TreasureHuntPlayScreen({super.key});

  @override
  State<TreasureHuntPlayScreen> createState() => _TreasureHuntPlayScreenState();
}

class _TreasureHuntPlayScreenState extends State<TreasureHuntPlayScreen> {
  @override
  Widget build(BuildContext context) {
    final thm =
        GameManager.instance.miniGameState as SerializableTreasureHuntGameState;

    return Center(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: _Header(),
          ),
          LayoutBuilder(builder: (context, constraints) {
            return SizedBox(
              width: 0.8 * constraints.maxWidth,
              height: (constraints.maxWidth * 1.5 -
                  2 * 20 -
                  2 * ThemeManager.instance.textSize),
              child: Center(
                child: TreasureHuntGameGrid(
                  rowCount: thm.grid.rowCount,
                  columnCount: thm.grid.columnCount,
                  getTileAt: (row, col) => thm.grid.tileAt(row: row, col: col)!,
                  onTileTapped: _onTileTapped,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _onTileTapped(int row, int col) {
    final thm =
        GameManager.instance.miniGameState as SerializableTreasureHuntGameState;
    if (thm.triesRemaining <= 0 || thm.timeRemaining < Duration.zero) return;

    final tile = thm.grid.tileAt(row: row, col: col);
    if (tile == null) return;

    // Preopen the tile so it feels more responsive
    thm.grid.revealAt(index: tile.index);
    final triesRemaining =
        tile.hasReward ? thm.triesRemaining + 1 : thm.triesRemaining - 1;
    final timeReamaining = tile.isLetter
        ? thm.timeRemaining + const Duration(seconds: 5)
        : thm.timeRemaining;
    GameManager.instance.updateMiniGameState(thm.copyWith(
        isTimerRunning: true,
        timeRemaining: timeReamaining,
        triesRemaining: triesRemaining));

    TwitchManager.instance.revealTileAt(index: tile.index);
    setState(() {});
  }
}

class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.listen(refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.cancel(refresh);

    super.dispose();
  }

  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final thm =
        GameManager.instance.miniGameState as SerializableTreasureHuntGameState;
    final tm = ThemeManager.instance;

    if (thm.triesRemaining <= 0) {
      return Text('Vous avez épuisé vos essais!', style: tm.textFrontendSc);
    }

    return LayoutBuilder(builder: (context, constraints) {
      return thm.timeRemaining.inSeconds > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Temps restant ${thm.timeRemaining.inSeconds}',
                    style: tm.textFrontendSc
                        .copyWith(fontSize: constraints.maxWidth * 0.05)),
                const SizedBox(width: 20),
                Text('Essais restants ${thm.triesRemaining}',
                    style: tm.textFrontendSc
                        .copyWith(fontSize: constraints.maxWidth * 0.05)),
              ],
            )
          : Text('Retournons à la gare!',
              style: tm.textFrontendSc
                  .copyWith(fontSize: constraints.maxWidth * 0.05));
    });
  }
}
