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
  Future<void> _setTwitchManager({required bool reloadIfPossible}) async {
    await Managers.instance.twitch
        .showConnectManagerDialog(context, reloadIfPossible: reloadIfPossible);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.treasureHunt;
    gm.onGameStarted.listen(_refresh);
    gm.onGameIsReady.listen(_refresh);
    gm.onTileRevealed.listen(_refreshWithOneParameter);
    gm.onTrySolution.listen(_solutionWasTried);

    final tm = Managers.instance.twitch;
    tm.onTwitchManagerHasTriedConnecting.listen(_hasTriedConnecting);

    if (tm.isNotConnected) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _setTwitchManager(reloadIfPossible: true));
    }
  }

  // Dispose
  @override
  void dispose() {
    final gm = Managers.instance.miniGames.treasureHunt;
    gm.onGameStarted.cancel(_refresh);
    gm.onGameIsReady.cancel(_refresh);
    gm.onTileRevealed.cancel(_refreshWithOneParameter);
    gm.onTrySolution.cancel(_solutionWasTried);

    final tm = Managers.instance.twitch;
    tm.onTwitchManagerHasTriedConnecting.cancel(_hasTriedConnecting);

    super.dispose();
  }

  void _hasTriedConnecting({required bool isSuccess}) => setState(() {});
  void _refresh() => setState(() {});
  void _refreshWithOneParameter(_) => setState(() {});
  void _solutionWasTried(String _, String __, bool ___) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.miniGames.treasureHunt;
    if (!gm.isReady) {
      return Container();
    }

    final windowHeight = MediaQuery.of(context).size.height;

    final offsetFromBorder = windowHeight * 0.02;
    final headerHeight = 160.0;
    final gridHeight = windowHeight - 3 * offsetFromBorder - headerHeight;

    return Stack(
      children: [
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                const TreasureHuntHeader(),
                const SizedBox(height: 20),
                SizedBox(
                  height: gridHeight,
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
              ],
            ),
          ),
        ),
        TreasureHuntAnimatedTextOverlay(),
      ],
    );
  }
}
