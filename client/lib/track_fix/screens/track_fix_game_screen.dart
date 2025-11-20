import 'package:common/track_fix/widgets/track_fix_game_grid.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/track_fix/managers/track_fix_game_manager.dart';
import 'package:train_de_mots/track_fix/widgets/track_fix_animated_text_overlay.dart';
import 'package:train_de_mots/track_fix/widgets/track_fix_header.dart';

class TrackFixGameScreen extends StatefulWidget {
  const TrackFixGameScreen({super.key});

  static const route = '/game-screen';

  @override
  State<TrackFixGameScreen> createState() => _TrackFixGameScreenState();
}

class _TrackFixGameScreenState extends State<TrackFixGameScreen> {
  Future<void> _setTwitchManager({required bool reloadIfPossible}) async {
    await Managers.instance.twitch
        .showConnectManagerDialog(context, reloadIfPossible: reloadIfPossible);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final fgm = Managers.instance.miniGames.trackFix;
    fgm.onGameStarted.listen(_refresh);
    fgm.onGameIsReady.listen(_refresh);
    fgm.onTrySolution.listen(_solutionWasTried);

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
    final fgm = Managers.instance.miniGames.trackFix;
    fgm.onGameStarted.cancel(_refresh);
    fgm.onGameIsReady.cancel(_refresh);
    fgm.onTrySolution.cancel(_solutionWasTried);

    final tm = Managers.instance.twitch;
    tm.onTwitchManagerHasTriedConnecting.cancel(_hasTriedConnecting);

    super.dispose();
  }

  void _hasTriedConnecting({required bool isSuccess}) => setState(() {});
  void _refresh() => setState(() {});
  void _solutionWasTried(
      {required String playerName,
      required String word,
      required SolutionStatus solutionStatus,
      required int pointsAwarded}) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fgm = Managers.instance.miniGames.trackFix;
    if (!fgm.isReady) {
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
                ElevatedButton(
                    onPressed: () async {
                      await Managers.instance.miniGames.trackFix.initialize();
                    },
                    child: const Text('Button')),
                const SizedBox(height: 12),
                const TrackFixHeader(),
                const SizedBox(height: 20),
                SizedBox(
                  height: gridHeight,
                  child: TrackFixGameGrid(
                    rowCount: fgm.grid.rowCount,
                    columnCount: fgm.grid.columnCount,
                    getTileAt: (int row, int col) =>
                        fgm.grid.tileAt(row: row, col: col)!,
                  ),
                ),
              ],
            ),
          ),
        ),
        TrackFixAnimatedTextOverlay(),
      ],
    );
  }
}
