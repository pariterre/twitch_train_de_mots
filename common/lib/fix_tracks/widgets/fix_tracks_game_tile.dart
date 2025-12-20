import 'package:common/fix_tracks/models/fix_tracks_grid.dart';
import 'package:flutter/material.dart';

class FixTracksGameTile extends StatelessWidget {
  const FixTracksGameTile({
    super.key,
    required this.tile,
    required this.tileSize,
    required this.textSize,
  });

  final Tile? tile;
  final double tileSize;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      // decoration: BoxDecoration(
      //   border: Border.all(width: tileSize * 0.03),
      // ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: tile == null ? null : Border.all(width: tileSize * 0.03),
            ),
            child: tile == null
                ? null
                : Image.asset(tile!.hasLetter
                    ? 'packages/common/assets/images/track_fix/open_grass.png'
                    : 'packages/common/assets/images/track_fix/grass.png'),
          ),
          if (tile?.hasLetter ?? false)
            Text(
              tile!.letter!,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: textSize * 0.65,
                  fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
