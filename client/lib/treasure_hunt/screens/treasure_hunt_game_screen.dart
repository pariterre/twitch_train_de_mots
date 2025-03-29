import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/treasure_hunt/widgets/treasure_hunt_animated_text_overlay.dart';
import 'package:train_de_mots/treasure_hunt/widgets/game_grid.dart';
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
    gm.onTileRevealed.listen(_refresh);

    final tm = Managers.instance.twitch;
    tm.onTwitchManagerHasConnected.listen(_refresh);

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
    gm.onTileRevealed.cancel(_refresh);

    final tm = Managers.instance.twitch;
    tm.onTwitchManagerHasConnected.cancel(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.miniGames.treasureHunt;
    if (!gm.isReady) {
      return Container();
    }

    final windowHeight = MediaQuery.of(context).size.height;

    final offsetFromBorder = windowHeight * 0.02;
    final headerHeight = 160.0;
    final gridHeight = windowHeight - 2 * offsetFromBorder - headerHeight;

    final tileSize = gridHeight / (gm.nbRows + 1);

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
                GameGrid(tileSize: tileSize),
              ],
            ),
          ),
        ),
        TreasureHuntAnimatedTextOverlay(),
      ],
    );
  }
}
