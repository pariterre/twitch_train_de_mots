import 'package:common/fix_tracks/models/serializable_fix_tracks_game_state.dart';
import 'package:common/fix_tracks/widgets/fix_tracks_game_grid.dart';
import 'package:common/generic/managers/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:frontend_common/managers/game_manager.dart';

class FixTracksPlayScreen extends StatelessWidget {
  const FixTracksPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: _Header(),
          ),
          Expanded(
              child: Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: _TrackGrid(),
          )),
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
  Duration _previousTimeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.listen(_refresh);
    gm.tickerManager.onClockTicked.listen(_onClockTicked);
  }

  @override
  void dispose() {
    final gm = GameManager.instance;
    gm.onMiniGameStateUpdated.cancel(_refresh);
    gm.tickerManager.onClockTicked.cancel(_onClockTicked);

    super.dispose();
  }

  void _refresh() => setState(() {});

  void _onClockTicked(Duration deltaTime) {
    if (!mounted) return;

    final thm =
        GameManager.instance.miniGameState as SerializableFixTracksGameState;

    final timeRemaining = thm.roundTimer.timeRemaining ?? Duration.zero;

    if (_previousTimeRemaining.inSeconds != timeRemaining.inSeconds) {
      _previousTimeRemaining = timeRemaining;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final thm =
        GameManager.instance.miniGameState as SerializableFixTracksGameState;
    final tm = ThemeManager.instance;
    final nextSegment = thm.grid.nextEmptySegment;

    return LayoutBuilder(builder: (context, constraints) {
      final time = (thm.roundTimer.timeRemaining?.inSeconds ?? -1) + 1;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Temps restant $time',
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
