import 'package:common/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/treasure_hunt/managers/treasure_hunt_game_manager.dart';
import 'package:train_de_mots/treasure_hunt/widgets/game_grid.dart';
import 'package:train_de_mots/treasure_hunt/widgets/header.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const route = '/game-screen';

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Future<void> _setTwitchManager({required bool reloadIfPossible}) async {
    await Managers.instance.twitch
        .showConnectManagerDialog(context, reloadIfPossible: reloadIfPossible);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final gm = TreasureHuntGameManager.instance;
    gm.onGameStarted.listen(_refresh);
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
    final gm = TreasureHuntGameManager.instance;
    gm.onGameStarted.cancel(_refresh);
    gm.onTileRevealed.cancel(_refresh);

    final tm = Managers.instance.twitch;
    tm.onTwitchManagerHasConnected.cancel(_refresh);

    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final windowWidth = MediaQuery.of(context).size.width;
    final windowHeight = MediaQuery.of(context).size.height;

    final offsetFromBorder = windowHeight * 0.02;
    final headerHeight = 160.0;
    final gridHeight = windowHeight - 2 * offsetFromBorder - headerHeight;

    final gm = TreasureHuntGameManager.instance;
    final tileSize = gridHeight / (gm.nbRows + 1);
    final gridWidth = gm.nbCols * tileSize;

    return Scaffold(
      body: Managers.instance.twitch.debugOverlay(
        child: Background(
          backgroundLayer: Opacity(
            opacity: 0.05,
            child: Image.asset(
              'assets/images/train.png',
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Stack(
              children: [
                Positioned(
                    top: offsetFromBorder,
                    left: 0,
                    right: 0,
                    child: Center(
                        child: SizedBox(
                            height: headerHeight, child: const Header()))),
                Positioned(
                  top: offsetFromBorder + headerHeight,
                  left: (windowWidth - gridWidth) / 2,
                  right: (windowWidth - gridWidth) / 2,
                  child: GameGrid(tileSize: tileSize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
