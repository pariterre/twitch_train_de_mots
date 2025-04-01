import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/treasure_hunt/widgets/treasure_hunt_game_tile.dart';

class TreasureHuntGameGrid extends StatelessWidget {
  const TreasureHuntGameGrid({super.key, required this.tileSize});

  final double tileSize;

  @override
  Widget build(BuildContext context) {
    final textSize = tileSize * 3 / 4;
    final gm = Managers.instance.miniGames.treasureHunt;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(gm.grid.columnCount, (col) {
        return Column(
          children: List.generate(gm.grid.rowCount, (row) {
            return SizedBox(
              width: tileSize,
              height: tileSize,
              child: TreasureHuntGameTile(
                  row: row, col: col, tileSize: tileSize, textSize: textSize),
            );
          }, growable: false),
        );
      }, growable: false),
    );
  }
}
