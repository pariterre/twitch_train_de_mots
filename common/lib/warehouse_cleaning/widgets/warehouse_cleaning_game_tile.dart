import 'package:common/warehouse_cleaning/models/warehouse_cleaning_grid.dart';
import 'package:flutter/material.dart';

class WarehouseCleaningGameTile extends StatelessWidget {
  const WarehouseCleaningGameTile({
    super.key,
    required this.tile,
    required this.tileSize,
  });

  final Tile tile;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      // decoration: BoxDecoration(
      //   border: Border.all(width: tileSize * 0.05),
      // ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          tile.isRevealed
              ? Container(
                  decoration: const BoxDecoration(
                      // border: Border.all(width: tileSize * 0.02),
                      ),
                  child: Image.asset(tile.content == TileContent.box
                      ? 'packages/common/assets/images/warehouse_cleaning/box.png'
                      : 'packages/common/assets/images/warehouse_cleaning/floor.png'),
                )
              : Container(
                  color: Colors.grey[900],
                ),
          if (tile.hasAvatar)
            // Put a round token
            Container(
              width: tileSize * 0.8,
              height: tileSize * 0.8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(width: tileSize * 0.05, color: Colors.white),
              ),
            ),
          tile.hasLetter &&
                  tile.isRevealed &&
                  tile.isNotVisited &&
                  tile.isNotMysteryLetter
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white.withAlpha(100),
                  ),
                  child: Transform.translate(
                    offset: Offset(0, -tileSize * 0.2), // subtle upward shift
                    child: Text(tile.letter!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: tileSize * 0.9,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                  ),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
