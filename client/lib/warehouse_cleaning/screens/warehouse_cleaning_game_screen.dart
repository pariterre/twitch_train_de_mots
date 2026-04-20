import 'package:common/warehouse_cleaning/widgets/warehouse_cleaning_game_grid.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/game_round_manager.dart';
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

    final whgm = Managers.instance.miniGames.warehouseCleaning;
    whgm.onRoundInitialized.listen(_refresh);
    whgm.onRoundStarted.listen(_refresh);
    whgm.onAvatarMoved.listen(_refresh);
    whgm.onTrySolution.listen(_solutionWasTried);
    whgm.onRoundEnded.listen(_refresh);

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
    final whgm = Managers.instance.miniGames.warehouseCleaning;
    whgm.onRoundInitialized.cancel(_refresh);
    whgm.onRoundStarted.cancel(_refresh);
    whgm.onAvatarMoved.cancel(_refresh);
    whgm.onTrySolution.cancel(_solutionWasTried);
    whgm.onRoundEnded.cancel(_refresh);

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
    final whgm = Managers.instance.miniGames.warehouseCleaning;
    if (!whgm.isRoundInitialized) {
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
                    rowCount: whgm.grid.rowCount,
                    columnCount: whgm.grid.columnCount,
                    getTileAt: whgm.grid.tileAt,
                    avatars: whgm.avatars,
                    boxes: whgm.boxes,
                    letters: whgm.letters,
                    isRoundInProgress:
                        whgm.roundStatus == GameRoundStatus.inProgress,
                    clockTicker: Managers.instance.tickerManager.onClockTicked,
                    onAvatarSlingShoot: whgm.slingShoot,
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
