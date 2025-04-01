import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart';
import 'package:common/treasure_hunt/widgets/treasure_hunt_game_tile.dart';
import 'package:flutter/material.dart';

class TreasureHuntGameGrid extends StatelessWidget {
  const TreasureHuntGameGrid({
    super.key,
    required this.rowCount,
    required this.columnCount,
    required this.tileSize,
    required this.getTileAt,
    this.onTileTapped,
  });

  final int rowCount;
  final int columnCount;
  final double tileSize;
  final Function(int row, int col)? onTileTapped;
  final Tile Function(int row, int col) getTileAt;

  @override
  Widget build(BuildContext context) {
    final textSize = tileSize * 3 / 4;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(columnCount, (col) {
        return Column(
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
  }
}
