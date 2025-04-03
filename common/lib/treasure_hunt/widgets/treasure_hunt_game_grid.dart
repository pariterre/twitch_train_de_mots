import 'dart:math';

import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart';
import 'package:common/treasure_hunt/widgets/treasure_hunt_game_tile.dart';
import 'package:flutter/material.dart';

class TreasureHuntGameGrid extends StatelessWidget {
  const TreasureHuntGameGrid({
    super.key,
    required this.rowCount,
    required this.columnCount,
    required this.getTileAt,
    this.onTileTapped,
  });

  final int rowCount;
  final int columnCount;
  final Function(int row, int col)? onTileTapped;
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
                  child: TreasureHuntGameTile(
                    tile: getTileAt(row, col),
                    tileSize: tileSize,
                    textSize: textSize,
                    onTap: onTileTapped == null
                        ? null
                        : () => onTileTapped!(row, col),
                  ));
            }, growable: false),
          );
        }, growable: false),
      );
    });
  }
}
