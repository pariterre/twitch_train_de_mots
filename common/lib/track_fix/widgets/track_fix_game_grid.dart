import 'dart:math';

import 'package:common/track_fix/models/track_fix_grid.dart';
import 'package:common/track_fix/widgets/track_fix_game_tile.dart';
import 'package:flutter/material.dart';

class TrackFixGameGrid extends StatelessWidget {
  const TrackFixGameGrid({
    super.key,
    required this.rowCount,
    required this.columnCount,
    required this.getTileAt,
  });

  final int rowCount;
  final int columnCount;
  final Tile Function(int row, int col) getTileAt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxTileWidth = (constraints.maxWidth == double.infinity
              ? MediaQuery.of(context).size.width
              : constraints.maxWidth) /
          columnCount;
      final maxTileHeight = (constraints.maxHeight == double.infinity
              ? MediaQuery.of(context).size.height
              : constraints.maxHeight) /
          rowCount;
      final tileSize = min(maxTileWidth, maxTileHeight);
      final textSize = tileSize * 3 / 4;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(columnCount, (col) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(rowCount, (row) {
              return SizedBox(
                  width: tileSize,
                  height: tileSize,
                  child: TrackFixGameTile(
                    tile: getTileAt(row, col),
                    tileSize: tileSize,
                    textSize: textSize,
                  ));
            }, growable: false),
          );
        }, growable: false),
      );
    });
  }
}
