import 'dart:math';

import 'package:common/treasure_hunt/models/treasure_hunt_grid.dart';
import 'package:flutter/material.dart';

extension _TileColor on TileValue {
  Color get color {
    switch (this) {
      case TileValue.zero:
        return const Color.fromARGB(0, 0, 0, 0);
      case TileValue.one:
        return const Color.fromARGB(255, 89, 171, 191);
      case TileValue.two:
        return const Color.fromARGB(255, 30, 139, 249);
      case TileValue.three:
        return const Color.fromARGB(255, 171, 161, 235);
      case TileValue.four:
        return const Color.fromARGB(255, 139, 105, 2);
      case TileValue.five:
        return Colors.purple;
      case TileValue.six:
        return Colors.brown;
      case TileValue.seven:
        return const Color.fromARGB(255, 212, 85, 0);
      case TileValue.eight:
        return Colors.deepPurple;
      case TileValue.treasure:
        return const Color.fromARGB(255, 255, 108, 108);
    }
  }
}

class TreasureHuntGameTile extends StatelessWidget {
  const TreasureHuntGameTile({
    super.key,
    required this.tile,
    required this.tileSize,
    required this.onTap,
  });

  final Tile tile;
  final double tileSize;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    // index is the number of treasure around the current tile
    final value = tile.value;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: tileSize * 0.03),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                  // border: Border.all(width: tileSize * 0.02),
                  ),
              child: Image.asset(tile.isConcealed
                  ? 'packages/common/assets/images/treasure_hunt/grass.png'
                  : 'packages/common/assets/images/treasure_hunt/open_grass.png'),
            ),
            tile.isRevealed && tile.hasReward
                ? (tile.isLetter
                    ? Text(tile.letter!,
                        style: TextStyle(
                            fontSize: tileSize * 0.6,
                            color: tile.value.color,
                            fontWeight: FontWeight.bold))
                    : _TreasureTile(size: tileSize * 0.75))
                : Text(
                    tile.isRevealed ? value.toString() : '',
                    style: TextStyle(
                        fontSize: tileSize * 0.6,
                        color: tile.value.color,
                        fontWeight: FontWeight.bold),
                  )
          ],
        ),
      ),
    );
  }
}

class _TreasureTile extends StatefulWidget {
  const _TreasureTile({required this.size});

  final double size;

  @override
  State<_TreasureTile> createState() => _TreasureTileState();
}

class _TreasureTileState extends State<_TreasureTile> {
  double _easeOutExponential(double x) {
    return 1 - (x == 1 ? 1.0 : pow(2, -50 * x).toDouble());
  }

  double _pulsing(double x) {
    return 0.05 * (sin(20 * x) + pi) + (1 - 0.3);
  }

  double _animation(double t) {
    return _easeOutExponential(t) * _pulsing(t);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
        duration: const Duration(seconds: 4),
        tween: Tween<double>(begin: 1, end: 0.02),
        builder: (context, value, child) {
          return SizedBox(
              height: _animation(value) * widget.size,
              width: _animation(value) * widget.size,
              child: Image.asset(
                  'packages/common/assets/images/treasure_hunt/blueberries.png'));
        });
  }
}
