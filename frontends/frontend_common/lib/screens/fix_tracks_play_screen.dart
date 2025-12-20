import 'package:common/fix_tracks/models/serializable_fix_tracks_game_state.dart';
import 'package:common/fix_tracks/widgets/fix_tracks_game_grid.dart';
import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';

class FixTracksPlayScreen extends StatelessWidget {
  const FixTracksPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: _TrackGrid(),
            );
          }),
        ],
      ),
    );
  }
}

class _TrackGrid extends StatefulWidget {
  const _TrackGrid();

  @override
  State<_TrackGrid> createState() => _TrackGridState();
}

class _TrackGridState extends State<_TrackGrid> {
  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.listen(refresh);
  }

  @override
  void dispose() {
    super.dispose();

    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.cancel(refresh);
  }

  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final thm =
        GameManager.instance.miniGameState as SerializableFixTracksGameState;

    return Center(
      child: FixTracksGameGrid(
        rowCount: thm.grid.rowCount,
        columnCount: thm.grid.columnCount,
        getTileAt: (row, col) => thm.grid.tileAt(row: row, col: col),
      ),
    );
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
        GameManager.instance.miniGameState as SerializableFixTracksGameState;
    final tm = ThemeManager.instance;
    final nextSegment = thm.grid.nextEmptySegment;

    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              thm.timeRemaining.inSeconds > 0
                  ? 'Temps restant ${thm.timeRemaining.inSeconds}'
                  : 'Retournons à la gare!',
              style: tm.textFrontendSc
                  .copyWith(fontSize: constraints.maxWidth * 0.05)),
          Text(
            nextSegment == null
                ? 'Au bout du rail!'
                : 'Prochain mot: ${nextSegment.length} lettres',
            style: tm.textFrontendSc
                .copyWith(fontSize: constraints.maxWidth * 0.05),
          ),
        ],
      );
    });
  }
}
