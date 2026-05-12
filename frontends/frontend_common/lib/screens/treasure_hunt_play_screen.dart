import 'dart:math';

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
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.listen(_refresh);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.cancel(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final mgm =
        GameManager.instance.miniGameState as SerializableTreasureHuntGameState;

    return Center(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: _Header(),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TreasureHuntGameGrid(
                  rowCount: mgm.grid.rowCount,
                  columnCount: mgm.grid.columnCount,
                  getTileAt: (row, col) => mgm.grid.tileAt(row: row, col: col)!,
                  onTileTapped: _onTileTapped,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTileTapped(int row, int col) {
    final mgm =
        GameManager.instance.miniGameState as SerializableTreasureHuntGameState;
    if (mgm.triesRemaining <= 0 ||
        (mgm.roundTimer.timeRemaining ?? Duration.zero) < Duration.zero) {
      return;
    }

    final tile = mgm.grid.tileAt(row: row, col: col);
    if (tile == null) return;

    // Preopen the tile so it feels more responsive
    mgm.grid.revealAt(index: tile.index);
    final triesRemaining =
        tile.hasReward ? mgm.triesRemaining + 1 : mgm.triesRemaining - 1;
    final bonusTime =
        tile.isLetter ? const Duration(seconds: 5) : Duration.zero;
    GameManager.instance.updateMiniGameState(mgm.copyWith(
        roundTimer: mgm.roundTimer
            .copyWith(endsAt: mgm.roundTimer.endsAt?.add(bonusTime)),
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
  Duration _previousTimeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.listen(_refresh);

    GameManager.instance.tickerManager.onClockTicked.listen(_onClockTicked);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.cancel(_refresh);

    GameManager.instance.tickerManager.onClockTicked.cancel(_onClockTicked);

    super.dispose();
  }

  void _refresh() => setState(() {});

  void _onClockTicked(Duration deltaTime) {
    if (!mounted) return;

    final mgm = GameManager.instance.miniGameState;
    final timeRemaining = mgm.roundTimer.timeRemaining ?? Duration.zero;

    if (_previousTimeRemaining.inSeconds != timeRemaining.inSeconds) {
      _previousTimeRemaining = timeRemaining;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final mgm =
        GameManager.instance.miniGameState as SerializableTreasureHuntGameState;
    final tm = ThemeManager.instance;

    if (mgm.triesRemaining <= 0) {
      return Text('Vous avez épuisé vos essais!', style: tm.textFrontendSc);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final time = max((mgm.roundTimer.timeRemaining?.inSeconds ?? -1) + 1, 0);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Temps restant $time',
              style: tm.textFrontendSc
                  .copyWith(fontSize: constraints.maxWidth * 0.05)),
          const SizedBox(width: 20),
          Text('Essais restants ${mgm.triesRemaining}',
              style: tm.textFrontendSc
                  .copyWith(fontSize: constraints.maxWidth * 0.05)),
        ],
      );
    });
  }

  // TODO Add the letter displayer?
}
