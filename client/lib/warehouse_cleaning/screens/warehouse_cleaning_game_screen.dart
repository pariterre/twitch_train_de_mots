import 'package:common/warehouse_cleaning/widgets/warehouse_cleaning_game_grid.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/warehouse_cleaning/widgets/warehouse_cleaning_animated_text_overlay.dart';
import 'package:train_de_mots/warehouse_cleaning/widgets/warehouse_cleaning_header.dart';

class WarehouseCleaningGameScreen extends StatefulWidget {
  const WarehouseCleaningGameScreen({super.key});

  static const route = '/game-screen';

  @override
  State<WarehouseCleaningGameScreen> createState() =>
      _WarehouseCleaningGameScreenState();
}

class _WarehouseCleaningGameScreenState
    extends State<WarehouseCleaningGameScreen> {
  Future<void> _setTwitchManager({required bool reloadIfPossible}) async {
    await Managers.instance.twitch
        .showConnectManagerDialog(context, reloadIfPossible: reloadIfPossible);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final gm = Managers.instance.miniGames.warehouseCleaning;
    gm.onGameStarted.listen(_refresh);
    gm.onGameIsReady.listen(_refresh);
    gm.onAvatarMoved.listen(_refresh);
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
    final gm = Managers.instance.miniGames.warehouseCleaning;
    gm.onGameStarted.cancel(_refresh);
    gm.onGameIsReady.cancel(_refresh);
    gm.onAvatarMoved.cancel(_refresh);
    gm.onTrySolution.cancel(_solutionWasTried);

    final tm = Managers.instance.twitch;
    tm.onTwitchManagerHasTriedConnecting.cancel(_hasTriedConnecting);

    super.dispose();
  }

  void _hasTriedConnecting({required bool isSuccess}) => setState(() {});
  void _refresh() => setState(() {});
  void _solutionWasTried(
          {required String playerName,
          required String word,
          required bool isSolutionRight,
          required int pointsAwarded}) =>
      setState(() {});

  @override
  Widget build(BuildContext context) {
    final gm = Managers.instance.miniGames.warehouseCleaning;
    if (!gm.isReady) {
      return Container();
    }

    return Stack(
      children: [
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const WarehouseCleaningHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20.0),
                  child: WarehouseCleaningGameGrid(
                    rowCount: gm.grid.rowCount,
                    columnCount: gm.grid.columnCount,
                    getTileAt: (int row, int col) {
                      final tile = gm.grid.tileAt(row: row, col: col)!;
                      return gm.avatarTile.index == tile.index
                          ? tile.copyWith(hasAvatar: true)
                          : tile;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        WarehouseCleaningAnimatedTextOverlay(),
      ],
    );
  }
}
