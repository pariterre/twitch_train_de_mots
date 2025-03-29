import 'package:flutter/material.dart';
import 'package:train_de_mots/generic/managers/managers.dart';
import 'package:train_de_mots/treasure_hunt/widgets/sweeper_tile.dart';

class GameGrid extends StatelessWidget {
  const GameGrid({super.key, required this.tileSize});

  final double tileSize;

  @override
  Widget build(BuildContext context) {
    final textSize = tileSize * 3 / 4;
    final gm = Managers.instance.miniGames.treasureHunt;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(gm.nbCols, (col) {
        return Column(
          children: List.generate(gm.nbRows, (row) {
            return SizedBox(
              width: tileSize,
              height: tileSize,
              child: SweeperTile(
                tileIndex: row * gm.nbCols + col,
                tileSize: tileSize,
                textSize: textSize,
              ),
            );
          }),
        );
      }, growable: false),
    );
  }
}
