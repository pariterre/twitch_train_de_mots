import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';
import 'package:common/warehouse_cleaning/widgets/warehouse_cleaning_game_tile.dart';
import 'package:flutter/material.dart';

class WarehouseCleaningGameGrid extends StatelessWidget {
  const WarehouseCleaningGameGrid({
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
    final tileSize = 100.0;

    return FittedBox(
      fit: BoxFit.contain,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(columnCount, (col) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(rowCount, (row) {
              return SizedBox(
                  width: tileSize,
                  height: tileSize,
                  child: WarehouseCleaningGameTile(
                      tile: getTileAt(row, col), tileSize: tileSize));
            }, growable: false),
          );
        }, growable: false),
      ),
    );
  }
}
