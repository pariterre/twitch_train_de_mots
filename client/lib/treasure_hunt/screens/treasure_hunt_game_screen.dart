import 'package:common/treasure_hunt/widgets/treasure_hunt_game_grid.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/treasure_hunt/widgets/treasure_hunt_animated_text_overlay.dart';
import 'package:train_de_mots/treasure_hunt/widgets/treasure_hunt_header.dart';

class TreasureHuntGameScreen extends StatefulWidget {
  const TreasureHuntGameScreen({super.key});

  static const route = '/game-screen';

  @override
  State<TreasureHuntGameScreen> createState() => _TreasureHuntGameScreenState();
}

class _TreasureHuntGameScreenState extends State<TreasureHuntGameScreen> {
  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.treasureHunt;
    gm.onInitialized.listen(_refresh);
    gm.onRoundStarted.listen(_refresh);
    gm.onTileRevealed.listen(_refreshWithOneParameter);
    gm.onTrySolution.listen(_solutionWasTried);
  }

  // Dispose
  @override
  void dispose() {
    final gm = Managers.instance.miniGames.treasureHunt;
    gm.onInitialized.cancel(_refresh);
    gm.onRoundStarted.cancel(_refresh);
    gm.onTileRevealed.cancel(_refreshWithOneParameter);
    gm.onTrySolution.cancel(_solutionWasTried);

    super.dispose();
  }

  void _refresh() => setState(() {});
  void _refreshWithOneParameter(dynamic _) => setState(() {});
  void _solutionWasTried(
          {required String playerName,
          required String word,
          required bool isSolutionRight,
          required int pointsAwarded}) =>
      setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.miniGames.treasureHunt;
    if (!gm.isInitialized) return Container();

    return Stack(
      children: [
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const TreasureHuntHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20.0),
                  child: TreasureHuntGameGrid(
                      rowCount: gm.grid.rowCount,
                      columnCount: gm.grid.columnCount,
                      getTileAt: (int row, int col) =>
                          gm.grid.tileAt(row: row, col: col)!,
                      onTileTapped: (int row, int col) {
                        final gm = Managers.instance.miniGames.treasureHunt;
                        gm.revealTile(row: row, col: col);
                      }),
                ),
              ),
            ],
          ),
        ),
        TreasureHuntAnimatedTextOverlay(),
      ],
    );
  }
}
