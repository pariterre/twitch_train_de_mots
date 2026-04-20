import 'package:common/fix_tracks/widgets/fix_tracks_game_grid.dart';
import 'package:flutter/material.dart';
import 'package:train_de_mots/fix_tracks/managers/fix_tracks_game_manager.dart';
import 'package:train_de_mots/fix_tracks/widgets/fix_tracks_animated_text_overlay.dart';
import 'package:train_de_mots/fix_tracks/widgets/fix_tracks_header.dart';
import 'package:train_de_mots/generic/managers/managers.dart';

class FixTracksGameScreen extends StatefulWidget {
  const FixTracksGameScreen({super.key});

  static const route = '/game-screen';

  @override
  State<FixTracksGameScreen> createState() => _FixTracksGameScreenState();
}

class _FixTracksGameScreenState extends State<FixTracksGameScreen> {
  Future<void> _setTwitchManager({required bool reloadIfPossible}) async {
    await Managers.instance.twitch
        .showConnectManagerDialog(context, reloadIfPossible: reloadIfPossible);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    final fgm = Managers.instance.miniGames.fixTracks;
    fgm.onRoundInitialized.listen(_refresh);
    fgm.onRoundStarted.listen(_refresh);
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
    final fgm = Managers.instance.miniGames.fixTracks;
    fgm.onRoundInitialized.cancel(_refresh);
    fgm.onRoundStarted.cancel(_refresh);
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
      required FixTracksSolutionStatus solutionStatus,
      required int pointsAwarded}) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fgm = Managers.instance.miniGames.fixTracks;
    if (!fgm.isRoundInitialized) return Container();

    return Stack(
      children: [
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const FixTracksHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: FixTracksGameGrid(
                    rowCount: fgm.grid.rowCount,
                    columnCount: fgm.grid.columnCount,
                    getTileAt: (int row, int col) =>
                        fgm.grid.tileAt(row: row, col: col),
                  ),
                ),
              ),
            ],
          ),
        ),
        FixTracksAnimatedTextOverlay(),
      ],
    );
  }
}
